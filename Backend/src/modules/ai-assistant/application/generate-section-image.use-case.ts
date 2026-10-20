import { NotFoundError } from '../../../shared/errors/app-error.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type { Role } from '../../auth/index.js';
import type { CourseSectionRepositoryPort } from '../../courses/domain/course-section-repository.port.js';
import type { CourseRepositoryPort } from '../../courses/domain/course-repository.port.js';
import type { ImageGeneratorPort, ImageKind } from '../domain/image-generator.port.js';
import { buildImagePrompt } from '../domain/image-prompt.js';
import type { ImagePromptOptimizerPort } from '../domain/image-prompt-optimizer.port.js';
import { loadOwnedCourse } from './course-access.js';

export interface GenerateSectionImageDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
  sectionKey: string;
  kind: ImageKind;
}

export type GenerateSectionImageResult = {
  imageUrl: string;
  prompt: string;
  provider: string;
};

/**
 * Illustration for one section (figure, architecture diagram, flowchart, workflow).
 *
 * Flow: the local LLM first rewrites the section (course title/subject +
 * description + key topics, possibly French) into an optimized English SDXL
 * prompt pair (`positive`/`negative` for `sd_xl_base_1.0`); on any LLM
 * failure the deterministic template is used instead. The pair is queued on
 * the ComfyUI SDXL adapter (512x512); while ComfyUI is unconfigured or
 * unreachable it throws IMAGE_SERVICE_UNAVAILABLE (503) so the UI shows an
 * honest "coming soon" state instead of a fake image (RG27: everything
 * stays local — no third-party image API).
 */
export class GenerateSectionImageUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly sectionRepository: CourseSectionRepositoryPort,
    private readonly imageGenerator: ImageGeneratorPort,
    private readonly imagePromptOptimizer: ImagePromptOptimizerPort,
  ) {}

  public async execute(dto: GenerateSectionImageDTO): Promise<GenerateSectionImageResult> {
    const course = await loadOwnedCourse(this.courses, dto);
    const section = await this.sectionRepository.findByKey(dto.courseId, dto.sectionKey);
    if (!section) {
      throw new NotFoundError('Course section not found');
    }

    // Template fallback input keeps the whole section data: description
    // AND the key topics (contract: "kind + title + key points").
    const description = [
      section.description,
      section.keyTopics.length > 0 ? `Key points: ${section.keyTopics.join(' | ')}` : '',
    ]
      .filter(Boolean)
      .join(' — ');

    let positive: string;
    let negative: string | undefined;
    try {
      const optimized = await this.imagePromptOptimizer.optimize({
        courseTitle: course.title,
        courseSubject: course.subject,
        sectionTitle: section.title,
        sectionDescription: section.description,
        keyTopics: section.keyTopics,
        kind: dto.kind,
      });
      positive = optimized.positive;
      negative = optimized.negative;
    } catch (error) {
      logger.warn(
        { sectionKey: dto.sectionKey, error: (error as Error).message },
        'SDXL prompt optimization failed, using the template fallback',
      );
      positive = buildImagePrompt({ title: section.title, description, kind: dto.kind });
      negative = undefined;
    }

    const result = await this.imageGenerator.generate({ positive, negative, kind: dto.kind });

    return {
      imageUrl: result.imageUrl,
      prompt: result.prompt,
      provider: result.provider,
    };
  }
}

import { ValidationError } from '../../../shared/errors/app-error.js';
import { getEnv } from '../../../config/env.js';
import {
  AiInvalidOutputError,
  AiModelUnavailableError,
} from '../../../shared/errors/app-error.js';
import type { AiGatewayPort } from '../../ai-assistant/index.js';
import type { Role } from '../../auth/index.js';
import type { ExamAiModelCatalogPort } from '../domain/exam-ai-model-catalog.port.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import type { CreateExamQuestionInput } from '../domain/exam-repository.port.js';
import { assertCanUseClass } from './exam-access.js';
import { normalizeQuestionInputs } from './exam-input.js';
import { buildExamPrompt, extractJsonPayload } from './exam-ai.prompt.js';

export interface GenerateExamAiDTO {
  requesterId: string;
  requesterRole: Role | null;
  classGroupId: string;
  /** Published + validated courses the teacher explicitly selected. */
  courseIds?: string[];
  title?: string;
  difficulty?: 'facile' | 'moyen' | 'difficile';
  questionCount?: number;
}

export interface GeneratedExamPreview {
  title: string;
  description: string | null;
  questions: CreateExamQuestionInput[];
  model: string;
  source: 'AI';
}

/**
 * Generates a draft question preview from the selected class's published
 * courses only. The model is verified to be installed BEFORE any generation
 * and is never pulled automatically. Nothing is persisted here: the teacher
 * reviews then calls POST /exams.
 */
export class GenerateExamAiUseCase {
  constructor(
    private readonly exams: ExamRepositoryPort,
    private readonly gateway: AiGatewayPort,
    private readonly catalog: ExamAiModelCatalogPort,
    private readonly modelName: string = getEnv().AI_MODEL,
  ) {}

  public async execute(dto: GenerateExamAiDTO): Promise<GeneratedExamPreview> {
    const classGroup = await this.exams.findClassGroup(dto.classGroupId);
    if (!classGroup) {
      throw new ValidationError('Unknown class', [
        { path: 'classGroupId', message: 'This class does not exist' },
      ]);
    }
    await assertCanUseClass(this.exams, dto.classGroupId, {
      id: dto.requesterId,
      role: dto.requesterRole,
    });

    const available = await this.exams.listClassCourses(
      dto.classGroupId,
      dto.requesterId,
    );
    const requestedIds = Array.from(new Set(dto.courseIds ?? []));
    let courses = available;
    if (requestedIds.length > 0) {
      const byId = new Map(available.map((course) => [course.id, course]));
      const missing = requestedIds.filter((courseId) => !byId.has(courseId));
      if (missing.length > 0) {
        throw new ValidationError(
          'Some selected courses are not published and validated for this class',
          [
            {
              path: 'courseIds',
              message: `Unknown or unpublished course(s): ${missing.join(', ')}`,
            },
          ],
        );
      }
      // Keep the teacher's selection order rather than the repository order.
      courses = requestedIds.map((courseId) => byId.get(courseId)!);
    }
    if (courses.length === 0) {
      throw new ValidationError('No published course in this class', [
        {
          path: requestedIds.length > 0 ? 'courseIds' : 'classGroupId',
          message:
            requestedIds.length > 0
              ? 'Select at least one published and validated course'
              : 'Publish and validate at least one course for this class before generating an exam',
        },
      ]);
    }

    const installed = await this.catalog.listInstalledModels();
    if (!installed.includes(this.modelName)) {
      throw new AiModelUnavailableError(
        `The required local model "${this.modelName}" is not installed. Install it manually with Ollama; it is never downloaded automatically.`,
        [{ installedModels: installed }],
      );
    }

    const questionCount = Math.min(30, Math.max(1, dto.questionCount ?? 10));
    const env = getEnv();
    const prompt = buildExamPrompt({
      title: dto.title?.trim() || `Contrôle — ${classGroup.name}`,
      subject: courses[0]?.subject ?? null,
      difficulty: dto.difficulty ?? 'moyen',
      questionCount,
      courses,
      maxSourceChars: env.AI_MAX_SOURCE_CHARS,
    });

    // Stream the model hop: Ollama sends SSE headers immediately, which
    // avoids undici's hard 5-minute `headersTimeout` on a plain fetch (the
    // local model needs 4-6 minutes when it runs partly on CPU). Content is
    // accumulated and parsed exactly like a non-streamed completion.
    let content = '';
    const usage = await this.gateway.streamCompletion(
      {
        system: prompt.system,
        user: prompt.user,
        maxTokens: Math.min(8192, 700 + questionCount * 320),
        temperature: 0.2,
        thinking: false,
      },
      (delta) => {
        content += delta;
      },
    );

    let payload: unknown;
    try {
      payload = extractJsonPayload(content);
    } catch {
      throw new AiInvalidOutputError(
        'The local model did not return a JSON object. Retry or generate the exam manually.',
      );
    }

    const container =
      payload && typeof payload === 'object' && !Array.isArray(payload)
        ? (payload as Record<string, unknown>)
        : {};
    const rawQuestions = Array.isArray(container.questions)
      ? container.questions
      : Array.isArray(payload)
        ? payload
        : null;
    if (!rawQuestions) {
      throw new AiInvalidOutputError('The model output has no "questions" array.');
    }

    let questions: CreateExamQuestionInput[];
    try {
      questions = normalizeQuestionInputs(rawQuestions, { max: 30 }).slice(0, questionCount);
    } catch (error) {
      throw new AiInvalidOutputError(
        'The model questions are malformed (missing options or correct answer).',
        [error instanceof Error ? error.message : String(error)],
      );
    }

    return {
      title:
        typeof container.title === 'string' && container.title.trim().length > 0
          ? container.title.trim()
          : dto.title?.trim() || `Contrôle — ${classGroup.name}`,
      description:
        typeof container.description === 'string' ? container.description.trim() || null : null,
      questions,
      model: usage.model || this.modelName,
      source: 'AI',
    };
  }
}

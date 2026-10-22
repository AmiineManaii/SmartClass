import { randomUUID } from 'node:crypto';

import {
  AppError,
  ImageServiceUnavailableError,
  NotFoundError,
} from '../../../shared/errors/app-error.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type { Role } from '../../auth/index.js';
import type { CourseSectionRepositoryPort } from '../../courses/domain/course-section-repository.port.js';
import type { CourseRepositoryPort } from '../../courses/domain/course-repository.port.js';
import type { ImageGeneratorPort, ImageKind } from '../domain/image-generator.port.js';
import type {
  SectionImageJob,
  SectionImageJobStorePort,
} from '../domain/section-image-job.port.js';
import { loadOwnedCourse } from './course-access.js';
import type {
  GenerateSectionImageDTO,
  GenerateSectionImageUseCase,
} from './generate-section-image.use-case.js';

const JOB_TTL_MS = 30 * 60 * 1000;

export interface StartSectionImageJobDTO extends GenerateSectionImageDTO {
  kind: ImageKind;
}

export interface GetSectionImageJobDTO {
  requesterId: string;
  requesterRole: Role | null;
  jobId: string;
}

/**
 * Runs section illustrations out of the request lifecycle.
 *
 * A teacher can leave the builder while ComfyUI works (4-5 min observed),
 * then poll the job status from wherever the app is. Jobs are process-local:
 * a backend restart loses queued/running work, and the GET answers 404.
 */
export class SectionImageJobService {
  private readonly starts = new Map<string, Promise<SectionImageJob>>();

  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly sections: CourseSectionRepositoryPort,
    private readonly imageUseCase: GenerateSectionImageUseCase,
    private readonly imageGenerator: ImageGeneratorPort,
    private readonly store: SectionImageJobStorePort,
  ) {}

  public start(dto: StartSectionImageJobDTO): Promise<SectionImageJob> {
    const key = `${dto.requesterId}:${dto.courseId}:${dto.sectionKey}`;
    const pending = this.starts.get(key);
    if (pending) return pending;

    const run = this.startJob(dto).finally(() => {
      this.starts.delete(key);
    });
    this.starts.set(key, run);
    return run;
  }

  private async startJob(dto: StartSectionImageJobDTO): Promise<SectionImageJob> {
    await this.store.prune(new Date(Date.now() - JOB_TTL_MS));
    await loadOwnedCourse(this.courses, dto);
    const section = await this.sections.findByKey(dto.courseId, dto.sectionKey);
    if (!section) {
      throw new NotFoundError('Course section not found');
    }

    const active = await this.store.findActive(dto.requesterId, dto.courseId, dto.sectionKey);
    if (active) {
      return active;
    }

    if (!(await this.imageGenerator.isAvailable())) {
      throw new ImageServiceUnavailableError('Image generation service is not available yet');
    }

    const now = new Date();
    const job: SectionImageJob = {
      id: randomUUID(),
      ownerId: dto.requesterId,
      ownerRole: dto.requesterRole,
      courseId: dto.courseId,
      sectionKey: dto.sectionKey,
      kind: dto.kind,
      status: 'QUEUED',
      createdAt: now,
      updatedAt: now,
    };
    await this.store.save(job);
    void this.run(job).catch((error: unknown) => {
      logger.error({ jobId: job.id, error }, 'Section image job crashed');
    });
    return job;
  }

  public async get(dto: GetSectionImageJobDTO): Promise<SectionImageJob> {
    await this.store.prune(new Date(Date.now() - JOB_TTL_MS));
    const job = await this.store.findById(dto.jobId);
    if (!job || (job.ownerId !== dto.requesterId && dto.requesterRole !== 'ADMIN')) {
      throw new NotFoundError('Image generation job not found');
    }
    return job;
  }

  private async run(job: SectionImageJob): Promise<void> {
    job.status = 'RUNNING';
    job.updatedAt = new Date();
    await this.store.save(job);

    try {
      const result = await this.imageUseCase.execute({
        requesterId: job.ownerId,
        requesterRole: job.ownerRole,
        courseId: job.courseId,
        sectionKey: job.sectionKey,
        kind: job.kind,
      });
      job.status = 'SUCCEEDED';
      job.result = result;
      logger.info({ jobId: job.id, sectionKey: job.sectionKey }, 'Section image ready');
    } catch (error) {
      job.status = 'FAILED';
      job.error = {
        code: error instanceof AppError ? error.code : 'INTERNAL_ERROR',
        message: error instanceof Error ? error.message : 'Image generation failed',
      };
      logger.warn(
        { jobId: job.id, sectionKey: job.sectionKey, error: job.error },
        'Section image generation failed',
      );
    } finally {
      job.updatedAt = new Date();
      await this.store.save(job);
    }
  }
}

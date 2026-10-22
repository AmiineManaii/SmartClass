import { describe, it, expect, vi } from 'vitest';

import { SectionImageJobService } from '../../src/modules/ai-assistant/application/section-image-job.service.js';
import type { GenerateSectionImageUseCase } from '../../src/modules/ai-assistant/application/generate-section-image.use-case.js';
import type { ImageGeneratorPort } from '../../src/modules/ai-assistant/domain/image-generator.port.js';
import { InMemorySectionImageJobStore } from '../../src/modules/ai-assistant/infrastructure/in-memory-section-image-job.store.js';
import { ImageServiceUnavailableError } from '../../src/shared/errors/app-error.js';
import type { CourseSection } from '../../src/modules/courses/domain/course-section.entity.js';
import type { CourseSectionRepositoryPort } from '../../src/modules/courses/domain/course-section-repository.port.js';
import type { CourseDetail } from '../../src/modules/courses/domain/course.entity.js';
import type { CourseRepositoryPort } from '../../src/modules/courses/domain/course-repository.port.js';

const COURSE_ID = '11111111-1111-1111-1111-111111111111';
const SECTION_KEY = 'sec-1';
const OWNER_ID = 'author-1';

const course: CourseDetail = {
  id: COURSE_ID,
  title: 'Algorithmique',
  subject: 'Informatique',
  content: '# Avant',
  level: 'equilibre',
  difficulty: 'moyen',
  format: 'resume',
  status: 'DRAFT',
  authorId: OWNER_ID,
  authorName: 'Ada Lovelace',
  classGroupIds: [],
  outline: null,
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
};

const section: CourseSection = {
  id: 's1',
  courseId: COURSE_ID,
  sectionKey: SECTION_KEY,
  title: 'Tris',
  description: 'Tri rapide',
  keyTopics: ['Quick sort'],
  content: '## Tris',
  order: 0,
  estimatedMinutes: 20,
  status: 'VALIDATED',
};

const courses: CourseRepositoryPort = {
  save: async () => course,
  update: async () => course,
  listByAuthor: async () => [],
  listPublished: async () => [],
  findById: async () => course,
  updateStatus: async (_id, status) => ({ ...course, status }),
  remove: async () => undefined,
};

const sections = (found: CourseSection | null = section): CourseSectionRepositoryPort => ({
  initFromOutline: async () => [section],
  listByCourse: async () => [section],
  findByKey: async () => found,
  saveContent: async () => section,
  updateStatus: async () => section,
  countNotValidated: async () => 0,
});

const generator = (available = true): ImageGeneratorPort => ({
  isAvailable: vi.fn(async () => available),
  generate: vi.fn(),
});

const useCase = (execute: GenerateSectionImageUseCase['execute']) =>
  ({ execute }) as GenerateSectionImageUseCase;

const ACCESS = {
  requesterId: OWNER_ID,
  requesterRole: null,
  courseId: COURSE_ID,
  sectionKey: SECTION_KEY,
  kind: 'FIGURE' as const,
};

const makeService = (
  execute: GenerateSectionImageUseCase['execute'],
  imageGenerator = generator(),
  store = new InMemorySectionImageJobStore(),
  sectionRepository = sections(),
) =>
  new SectionImageJobService(courses, sectionRepository, useCase(execute), imageGenerator, store);

const waitForStatus = async (service: SectionImageJobService, jobId: string, status: string) => {
  await vi.waitFor(async () => {
    const job = await service.get({
      requesterId: OWNER_ID,
      requesterRole: null,
      jobId,
    });
    expect(job.status).toBe(status);
  });
};

describe('Unit: SectionImageJobService', () => {
  it('starts a job and exposes its result once generation succeeds', async () => {
    const execute = vi.fn(async () => ({
      imageUrl: 'https://comfy.example/view/out.png',
      prompt: 'a sorting diagram',
      provider: 'comfyui',
    }));
    const service = makeService(execute);

    const started = await service.start(ACCESS);
    expect(started).toMatchObject({
      courseId: COURSE_ID,
      sectionKey: SECTION_KEY,
      kind: 'FIGURE',
    });
    expect(['QUEUED', 'RUNNING', 'SUCCEEDED']).toContain(started.status);

    await waitForStatus(service, started.id, 'SUCCEEDED');
    const job = await service.get({
      requesterId: OWNER_ID,
      requesterRole: null,
      jobId: started.id,
    });
    expect(job.result).toEqual({
      imageUrl: 'https://comfy.example/view/out.png',
      prompt: 'a sorting diagram',
      provider: 'comfyui',
    });
    expect(execute).toHaveBeenCalledWith({
      requesterId: OWNER_ID,
      requesterRole: null,
      courseId: COURSE_ID,
      sectionKey: SECTION_KEY,
      kind: 'FIGURE',
    });
  });

  it('reuses an active job for the same teacher and section', async () => {
    let release!: (value: { imageUrl: string; prompt: string; provider: string }) => void;
    const execute = vi.fn(
      () =>
        new Promise<{ imageUrl: string; prompt: string; provider: string }>((resolve) => {
          release = resolve;
        }),
    );
    const imageGenerator = generator();
    const service = makeService(execute, imageGenerator);

    const first = await service.start(ACCESS);
    const second = await service.start(ACCESS);

    expect(second.id).toBe(first.id);
    expect(execute).toHaveBeenCalledTimes(1);
    expect(imageGenerator.isAvailable).toHaveBeenCalledTimes(1);

    release({
      imageUrl: 'https://comfy.example/view/out.png',
      prompt: 'p',
      provider: 'comfyui',
    });
    await waitForStatus(service, first.id, 'SUCCEEDED');

    const third = await service.start(ACCESS);
    expect(third.id).not.toBe(first.id);
    expect(execute).toHaveBeenCalledTimes(2);
  });

  it('turns a generation failure into a FAILED job with its error code', async () => {
    const execute = vi.fn(async () => {
      throw new ImageServiceUnavailableError('ComfyUI is down');
    });
    const service = makeService(execute);

    const started = await service.start(ACCESS);
    await waitForStatus(service, started.id, 'FAILED');

    const job = await service.get({
      requesterId: OWNER_ID,
      requesterRole: null,
      jobId: started.id,
    });
    expect(job.error).toEqual({
      code: 'IMAGE_SERVICE_UNAVAILABLE',
      message: 'ComfyUI is down',
    });
    expect(job.result).toBeUndefined();
  });

  it('answers 503 before enqueueing when ComfyUI is unavailable', async () => {
    const execute = vi.fn();
    const service = makeService(execute, generator(false));

    await expect(service.start(ACCESS)).rejects.toMatchObject({
      statusCode: 503,
      code: 'IMAGE_SERVICE_UNAVAILABLE',
    });
    expect(execute).not.toHaveBeenCalled();
  });

  it('guards ownership: foreign jobs are 404, admins can read them', async () => {
    const service = makeService(async () => ({
      imageUrl: 'https://comfy.example/view/out.png',
      prompt: 'p',
      provider: 'comfyui',
    }));
    const started = await service.start(ACCESS);

    await expect(
      service.get({
        requesterId: 'intruder',
        requesterRole: null,
        jobId: started.id,
      }),
    ).rejects.toMatchObject({ statusCode: 404 });

    const asAdmin = await service.get({
      requesterId: 'admin-1',
      requesterRole: 'ADMIN',
      jobId: started.id,
    });
    expect(asAdmin.id).toBe(started.id);
  });

  it('answers 404 for an unknown section and an unknown job', async () => {
    const service = makeService(vi.fn(), generator(), undefined, sections(null));

    await expect(service.start(ACCESS)).rejects.toMatchObject({ statusCode: 404 });
    await expect(
      service.get({
        requesterId: OWNER_ID,
        requesterRole: null,
        jobId: '22222222-2222-2222-2222-222222222222',
      }),
    ).rejects.toMatchObject({ statusCode: 404 });
  });
});

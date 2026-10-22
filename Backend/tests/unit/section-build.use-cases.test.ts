import { describe, it, expect, vi } from 'vitest';
import { ImageServiceUnavailableError } from '../../src/shared/errors/app-error.js';
import { GenerateSectionUseCase } from '../../src/modules/ai-assistant/application/generate-section.use-case.js';
import { GetCourseBuildUseCase } from '../../src/modules/ai-assistant/application/get-course-build.use-case.js';
import { ValidateSectionUseCase } from '../../src/modules/ai-assistant/application/validate-section.use-case.js';
import { GenerateSectionImageUseCase } from '../../src/modules/ai-assistant/application/generate-section-image.use-case.js';
import { RefineSectionUseCase } from '../../src/modules/ai-assistant/application/refine-section.use-case.js';
import { SectionMemoryService } from '../../src/modules/ai-assistant/application/section-memory.service.js';
import { PublishCourseUseCase } from '../../src/modules/courses/application/publish-course.use-case.js';
import { buildSectionPrompt, COURSE_PROMPT_VERSION } from '../../src/modules/ai-assistant/domain/course-prompt.js';
import type { AiGatewayPort } from '../../src/modules/ai-assistant/domain/ai-gateway.port.js';
import type { EmbeddingPort } from '../../src/modules/ai-assistant/domain/embedding.port.js';
import type { SectionMemoryPort, MemoryHit } from '../../src/modules/ai-assistant/domain/section-memory.port.js';
import type { CourseRepositoryPort } from '../../src/modules/courses/domain/course-repository.port.js';
import type { CourseSectionRepositoryPort } from '../../src/modules/courses/domain/course-section-repository.port.js';
import type {
  CourseSection,
  OutlineSectionInput,
} from '../../src/modules/courses/domain/course-section.entity.js';
import type { CourseDetail } from '../../src/modules/courses/domain/course.entity.js';

const OUTLINE = {
  title: 'Algorithmique avancée',
  targetAudience: 'Licence 3 Informatique',
  prerequisites: ['Structures de données'],
  description: 'Cours complet',
  sections: [
    { id: 'sec-1', title: 'Tris', description: 'Tri rapide', keyTopics: ['Quick sort'], estimatedMinutes: 20 },
    { id: 'sec-2', title: 'Graphes', description: 'Parcours', keyTopics: ['BFS', 'DFS'] },
  ],
};

const makeCourse = (overrides: Partial<CourseDetail> = {}): CourseDetail => ({
  id: '11111111-1111-1111-1111-111111111111',
  title: 'Algorithmique avancée',
  subject: 'Informatique',
  content: '# Avant',
  level: 'equilibre',
  difficulty: 'moyen',
  format: 'resume',
  status: 'DRAFT',
  authorId: 'author-1',
  authorName: 'Ada Lovelace',
  classGroupIds: [],
  outline: OUTLINE,
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
  ...overrides,
});

const makeSections = (): CourseSection[] => [
  {
    id: 's1',
    courseId: '11111111-1111-1111-1111-111111111111',
    sectionKey: 'sec-1',
    title: 'Tris',
    description: 'Tri rapide',
    keyTopics: ['Quick sort'],
    content: '## Tris\nContenu du tri rapide.',
    order: 0,
    estimatedMinutes: 20,
    status: 'GENERATED',
  },
  {
    id: 's2',
    courseId: '11111111-1111-1111-1111-111111111111',
    sectionKey: 'sec-2',
    title: 'Graphes',
    description: 'Parcours',
    keyTopics: ['BFS', 'DFS'],
    content: null,
    order: 1,
    estimatedMinutes: 15,
    status: 'PENDING',
  },
];

/** In-memory CourseSectionRepositoryPort. */
class FakeSectionRepository implements CourseSectionRepositoryPort {
  public rows: CourseSection[] = [];
  public inits: OutlineSectionInput[][] = [];

  async initFromOutline(courseId: string, sections: OutlineSectionInput[]): Promise<CourseSection[]> {
    this.inits.push(sections);
    this.rows = sections.map((section, index) => ({
      id: `row-${index}`,
      courseId,
      sectionKey: section.sectionKey,
      title: section.title,
      description: section.description,
      keyTopics: section.keyTopics,
      content: null,
      order: index,
      estimatedMinutes: section.estimatedMinutes ?? 15,
      status: 'PENDING',
    }));
    return this.rows;
  }

  async listByCourse(): Promise<CourseSection[]> {
    return [...this.rows].sort((a, b) => a.order - b.order);
  }

  async findByKey(courseId: string, sectionKey: string): Promise<CourseSection | null> {
    return this.rows.find((row) => row.courseId === courseId && row.sectionKey === sectionKey) ?? null;
  }

  async saveContent(params: { courseId: string; sectionKey: string; content: string; status?: 'GENERATED' | 'VALIDATED' }): Promise<CourseSection> {
    const row = this.rows.find((item) => item.sectionKey === params.sectionKey);
    if (!row) throw new Error('section missing');
    row.content = params.content;
    row.status = params.status ?? 'GENERATED';
    return row;
  }

  async updateStatus(_courseId: string, sectionKey: string, status: CourseSection['status']): Promise<CourseSection> {
    const row = this.rows.find((item) => item.sectionKey === sectionKey);
    if (!row) throw new Error('section missing');
    row.status = status;
    return row;
  }

  async countNotValidated(): Promise<number> {
    return this.rows.filter((row) => row.status !== 'VALIDATED').length;
  }
}

const makeCourseRepo = (course: CourseDetail | null): CourseRepositoryPort => ({
  save: async () => course as CourseDetail,
  update: async () => course as CourseDetail,
  listByAuthor: async () => [],
  listPublished: async () => [],
  findById: async () => course,
  updateStatus: async (_id, status) => ({ ...(course as CourseDetail), status }),
  remove: async () => undefined,
});

const makeGateway = (): AiGatewayPort => ({
  chatCompletion: async (input) => ({
    content: `Refined: ${input.instruction}`,
    promptTokens: 1,
    completionTokens: 2,
    model: 'test-model',
    toolsUsed: false,
  }),
  streamCompletion: async (_input, onDelta) => {
    onDelta('## Graphes\n');
    onDelta('BFS et DFS.');
    return { promptTokens: 5, completionTokens: 7, model: 'test-model' };
  },
  checkHealth: async () => ({ available: true, model: 'test-model', latencyMs: 1 }),
});

const workingEmbedder: EmbeddingPort = {
  embed: async () => Array.from({ length: 768 }, (_, i) => i / 768),
  checkHealth: async () => ({ available: true, model: 'embeddinggemma', latencyMs: 2 }),
};

const brokenEmbedder: EmbeddingPort = {
  embed: async () => {
    throw new Error('ollama down');
  },
  checkHealth: async () => ({ available: false, model: 'embeddinggemma', latencyMs: null }),
};

const makeMemory = (hits: MemoryHit[] = []): SectionMemoryPort & { stored: unknown[] } => {
  const stored: unknown[] = [];
  return {
    stored,
    store: async (passage) => {
      stored.push(passage);
      return { ...passage, id: 'p1' };
    },
    search: async () => hits,
  };
};

const ACCESS = {
  requesterId: 'author-1',
  requesterRole: null,
  courseId: '11111111-1111-1111-1111-111111111111',
};

describe('Unit: buildSectionPrompt', () => {
  const base = {
    courseTitle: 'Algorithmique avancée',
    targetAudience: 'Licence 3',
    outlineTitles: ['Tris', 'Graphes', 'Programmation dynamique'],
    level: 'equilibre' as const,
    difficulty: 'moyen' as const,
    section: { title: 'Graphes', description: 'Parcours', keyTopics: ['BFS', 'DFS'], estimatedMinutes: 20 },
    position: { index: 2, total: 3 },
    writtenTitles: ['Tris'],
  };

  it('anchors the section in the validated plan and its own notions', () => {
    const prompt = buildSectionPrompt(base);
    expect(prompt.version).toMatch(/^\d{4}-\d{2}-\d{2}\.v\d+$/);
    expect(prompt.user).toContain('Algorithmique avancée');
    expect(prompt.user).toContain('Graphes  ← SECTION EN COURS');
    expect(prompt.user).toContain('Notions obligatoires à couvrir : BFS, DFS');
    expect(prompt.user).toContain('position 2/3');
    expect(prompt.system).toContain('EXCLUSIVEMENT les notions');
  });

  it('lists already-written sections so the model does not repeat them', () => {
    const prompt = buildSectionPrompt(base);
    expect(prompt.user).toContain('Sections déjà rédigées');
    expect(prompt.user).toContain('Tris');
    expect(prompt.system).toContain('Ne répète pas le contenu des sections précédentes');
  });

  it('injects the teacher\'s validated memory with a usage instruction', () => {
    const prompt = buildSectionPrompt({
      ...base,
      memory: [{ title: 'Ancien cours : graphes', content: 'Les files LIFO…', similarity: 0.87 }],
    });
    expect(prompt.user).toContain('CONTENUS DÉJÀ VALIDÉS PAR L\'ENSEIGNANT');
    expect(prompt.user).toContain('Ancien cours : graphes');
    expect(prompt.user).toContain('terminologie');
  });

  it('includes examples and figures by default, and can opt out', () => {
    const bare = buildSectionPrompt(base);
    expect(bare.user).not.toContain('CONTENUS DÉJÀ VALIDÉS');
    expect(bare.system).toContain('bloc de code mermaid');
    expect(bare.system).toContain('au moins un exemple simple');
    const noFigures = buildSectionPrompt({ ...base, extras: { mermaid: false } });
    expect(noFigures.system).not.toContain('bloc de code mermaid');
  });

  it('flags the last section of the plan', () => {
    const last = buildSectionPrompt({ ...base, position: { index: 3, total: 3 } });
    expect(last.user).toContain('DERNIÈRE section');
    // The "in progress" marker moves to the third (last) title.
    expect(last.user).toContain('Programmation dynamique  ← SECTION EN COURS');
  });
});

describe('Unit: GetCourseBuildUseCase', () => {
  it('materializes sections from the validated outline on first open', async () => {
    const sections = new FakeSectionRepository();
    const useCase = new GetCourseBuildUseCase(makeCourseRepo(makeCourse()), sections);
    const result = await useCase.execute(ACCESS);
    expect(result.initializedFromOutline).toBe(true);
    expect(result.sections.map((section) => section.sectionKey)).toEqual(['sec-1', 'sec-2']);
    expect(result.sections.every((section) => section.status === 'PENDING')).toBe(true);
    expect(sections.inits[0]?.[0]?.keyTopics).toEqual(['Quick sort']);
  });

  it('answers 404 to a non-author (IDOR probe)', async () => {
    const sections = new FakeSectionRepository();
    const useCase = new GetCourseBuildUseCase(makeCourseRepo(makeCourse()), sections);
    await expect(
      useCase.execute({ ...ACCESS, requesterId: 'someone-else' }),
    ).rejects.toMatchObject({ statusCode: 404 });
  });

  it('lets an ADMIN build another teacher\'s course', async () => {
    const sections = new FakeSectionRepository();
    const useCase = new GetCourseBuildUseCase(makeCourseRepo(makeCourse()), sections);
    const result = await useCase.execute({ ...ACCESS, requesterId: 'admin-1', requesterRole: 'ADMIN' });
    expect(result.sections).toHaveLength(2);
  });

  it('returns an empty list without an outline (client falls back)', async () => {
    const sections = new FakeSectionRepository();
    const useCase = new GetCourseBuildUseCase(
      makeCourseRepo(makeCourse({ outline: null })),
      sections,
    );
    const result = await useCase.execute(ACCESS);
    expect(result.sections).toEqual([]);
    expect(result.initializedFromOutline).toBe(false);
  });
});

describe('Unit: GenerateSectionUseCase', () => {
  const buildUseCase = (opts?: {
    memory?: SectionMemoryPort;
    embedder?: EmbeddingPort;
    gateway?: AiGatewayPort;
  }) => {
    const sections = new FakeSectionRepository();
    sections.rows = makeSections();
    const memory = new SectionMemoryService(
      opts?.memory ?? makeMemory(),
      opts?.embedder ?? workingEmbedder,
    );
    const useCase = new GenerateSectionUseCase(
      opts?.gateway ?? makeGateway(),
      makeCourseRepo(makeCourse()),
      sections,
      memory,
    );
    return { useCase, sections };
  };

  const DTO = { ...ACCESS, sectionKey: 'sec-2' };

  it('streams deltas, saves the body and reports memory hits', async () => {
    const { useCase, sections } = buildUseCase({
      memory: makeMemory([
        { id: 'p1', authorId: 'author-1', courseId: null, sectionId: null, subject: 'Informatique', title: 'Ancien', content: '…', similarity: 0.9 },
      ]),
    });
    const deltas: string[] = [];
    const phases: string[] = [];
    const meta = await useCase.stream(DTO, (delta) => deltas.push(delta), (phase) => phases.push(phase));
    expect(deltas.join('')).toContain('BFS et DFS.');
    expect(phases).toEqual(['memory', 'generating']);
    expect(meta.memoryHits).toBe(1);
    expect(meta.regenerated).toBe(false);
    expect(meta.model).toBe('test-model');
    expect(meta.promptVersion).toBe(COURSE_PROMPT_VERSION);
    const saved = await sections.findByKey(ACCESS.courseId, 'sec-2');
    expect(saved?.content).toContain('BFS et DFS.');
    expect(saved?.status).toBe('GENERATED');
  });

  it('attaches thinking and web tools to every section', async () => {
    const seen: Parameters<AiGatewayPort['streamCompletion']>[0][] = [];
    const gateway: AiGatewayPort = {
      ...makeGateway(),
      streamCompletion: async (input, onDelta) => {
        seen.push(input);
        onDelta('## Graphes\nBFS et DFS.');
        return { promptTokens: 5, completionTokens: 7, model: 'test-model' };
      },
    };
    const { useCase } = buildUseCase({ gateway });

    await useCase.stream(DTO, () => undefined);

    expect(seen[0]?.thinking).toBe(true);
    expect(seen[0]?.tools?.map((tool) => tool.function.name)).toEqual(['web_search', 'fetch_url']);
    expect(seen[0]?.system).toContain("tu disposes de l'outil web_search");
  });

  it('refuses to silently overwrite a VALIDATED section', async () => {
    const { useCase, sections } = buildUseCase();
    await sections.updateStatus(ACCESS.courseId, 'sec-1', 'VALIDATED');
    await expect(
      useCase.stream({ ...ACCESS, sectionKey: 'sec-1' }, () => undefined),
    ).rejects.toMatchObject({ statusCode: 409, code: 'CONFLICT' });
  });

  it('regeneration of a VALIDATED section demotes it to GENERATED', async () => {
    const { useCase, sections } = buildUseCase();
    await sections.updateStatus(ACCESS.courseId, 'sec-1', 'VALIDATED');
    const meta = await useCase.stream(
      { ...ACCESS, sectionKey: 'sec-1', regenerate: true },
      () => undefined,
    );
    expect(meta.regenerated).toBe(true);
    const saved = await sections.findByKey(ACCESS.courseId, 'sec-1');
    expect(saved?.status).toBe('GENERATED');
  });

  it('generates without memory when the embedding server is down', async () => {
    const { useCase } = buildUseCase({ embedder: brokenEmbedder });
    const meta = await useCase.stream(DTO, () => undefined);
    expect(meta.memoryHits).toBe(0);
    expect(meta.section.status).toBe('GENERATED');
  });

  it('answers 404 for a foreign course and for an unknown section', async () => {
    const { useCase } = buildUseCase();
    await expect(
      useCase.stream({ ...DTO, requesterId: 'intruder' }, () => undefined),
    ).rejects.toMatchObject({ statusCode: 404 });
    await expect(
      useCase.stream({ ...DTO, sectionKey: 'nope' }, () => undefined),
    ).rejects.toMatchObject({ statusCode: 404 });
  });
});

describe('Unit: ValidateSectionUseCase', () => {
  const setup = (memory?: SectionMemoryPort) => {
    const sections = new FakeSectionRepository();
    sections.rows = makeSections();
    const mem = memory ?? makeMemory();
    const courses = makeCourseRepo(makeCourse());
    const updateSpy = vi.spyOn(courses, 'update');
    const useCase = new ValidateSectionUseCase(
      courses,
      sections,
      new SectionMemoryService(mem, workingEmbedder),
    );
    return { useCase, sections, mem, updateSpy };
  };

  it('marks the section VALIDATED, remembers it and reassembles the draft', async () => {
    const { useCase, sections, mem, updateSpy } = setup();
    const result = await useCase.execute({ ...ACCESS, sectionKey: 'sec-1' });
    expect(result.section.status).toBe('VALIDATED');
    expect(result.remainingToValidate).toBe(1);
    expect(mem.stored).toHaveLength(1);
    expect(mem.stored[0]).toMatchObject({ authorId: 'author-1', subject: 'Informatique' });
    const [courseId, update] = updateSpy.mock.calls[0] ?? [];
    expect(courseId).toBe(ACCESS.courseId);
    expect(update).toMatchObject({ content: expect.stringContaining('# Algorithmique avancée') });
    expect((update as { content: string }).content).toContain('Contenu du tri rapide.');
    // Memory failure must not block validation.
    const failing = setup({
      store: async () => {
        throw new Error('pgvector down');
      },
      search: async () => [],
    });
    const res = await failing.useCase.execute({ ...ACCESS, sectionKey: 'sec-1' });
    expect(res.section.status).toBe('VALIDATED');
    await expect(sections.findByKey(ACCESS.courseId, 'sec-1')).resolves.toBeTruthy();
  });

  it('rejects validation of an empty section (409) and foreign courses (404)', async () => {
    const { useCase } = setup();
    await expect(
      useCase.execute({ ...ACCESS, sectionKey: 'sec-2' }),
    ).rejects.toMatchObject({ statusCode: 409 });
    await expect(
      useCase.execute({ ...ACCESS, sectionKey: 'sec-1', requesterId: 'intruder' }),
    ).rejects.toMatchObject({ statusCode: 404 });
  });
});

describe('Unit: RefineSectionUseCase', () => {
  it('returns the replacement under both keys with an explanation', async () => {
    const useCase = new RefineSectionUseCase(
      makeGateway(),
      makeCourseRepo(makeCourse()),
      new SectionMemoryService(makeMemory(), workingEmbedder),
    );
    const result = await useCase.execute({
      courseTitle: 'Algorithmique avancée',
      courseId: ACCESS.courseId,
      selectedText: 'Le tri rapide est instable.',
      instruction: 'Ajoute un exemple',
      requesterId: 'author-1',
      requesterRole: null,
    });
    expect(result.refinedText).toBe(result.revisedText);
    expect(result.refinedText).toContain('Refined:');
    expect(result.explanation).toBeTruthy();
    expect(result.model).toBe('test-model');
  });

  it('keeps working without memory or an author id', async () => {
    const useCase = new RefineSectionUseCase(makeGateway());
    const result = await useCase.execute({
      selectedText: 'texte',
      instruction: 'corrige',
    });
    expect(result.revisedText).toBe(result.refinedText);
    expect(result.explanation).toBeTruthy();
  });

  it('rejects empty payloads (existing contract)', async () => {
    const useCase = new RefineSectionUseCase(makeGateway());
    await expect(
      useCase.execute({ selectedText: '  ', instruction: 'x' }),
    ).rejects.toMatchObject({ statusCode: 500 });
  });
});

describe('Unit: GenerateSectionImageUseCase', () => {
  const OPTIMIZED = {
    positive:
      'educational diagram, clean flat vector illustration, algorithm sorting, high quality',
    negative: 'text, watermark, low quality, blurry, cartoon',
  };

  const fakeOptimizer = (
    overrides?: Partial<import('../../src/modules/ai-assistant/domain/image-prompt-optimizer.port.js').ImagePromptOptimizerPort>,
  ): import('../../src/modules/ai-assistant/domain/image-prompt-optimizer.port.js').ImagePromptOptimizerPort => ({
    optimize: async () => OPTIMIZED,
    ...overrides,
  });

  const setup = (
    imageGenerator: import('../../src/modules/ai-assistant/domain/image-generator.port.js').ImageGeneratorPort,
    optimizer = fakeOptimizer(),
  ) => {
    const sections = new FakeSectionRepository();
    sections.rows = makeSections();
    const useCase = new GenerateSectionImageUseCase(
      makeCourseRepo(makeCourse()),
      sections,
      imageGenerator,
      optimizer,
    );
    return { useCase };
  };

  const DTO = { ...ACCESS, sectionKey: 'sec-1', kind: 'FIGURE' as const };

  it('optimizes the prompts with the local LLM before queueing the image', async () => {
    let optimizerInput: import('../../src/modules/ai-assistant/domain/image-prompt-optimizer.port.js').ImagePromptOptimizeInput | undefined;
    let captured: import('../../src/modules/ai-assistant/domain/image-generator.port.js').ImageGenerateInput | undefined;
    const { useCase } = setup(
      {
        generate: async (input) => {
          captured = input;
          return {
            imageUrl: 'http://localhost:8188/view?image=a.png',
            prompt: input.positive,
            provider: 'comfyui',
          };
        },
        isAvailable: async () => true,
      },
      fakeOptimizer({
        optimize: async (input) => {
          optimizerInput = input;
          return OPTIMIZED;
        },
      }),
    );
    const result = await useCase.execute(DTO);
    expect(result.imageUrl).toContain('localhost:8188');
    expect(result.provider).toBe('comfyui');
    expect(result.prompt).toBe(OPTIMIZED.positive);
    expect(captured?.positive).toBe(OPTIMIZED.positive);
    expect(captured?.negative).toBe(OPTIMIZED.negative);
    expect(optimizerInput).toMatchObject({
      courseTitle: 'Algorithmique avancée',
      courseSubject: 'Informatique',
      sectionTitle: 'Tris',
      sectionDescription: 'Tri rapide',
      keyTopics: ['Quick sort'],
      kind: 'FIGURE',
    });
  });

  it('falls back to the template prompts when the optimizer fails', async () => {
    let captured: import('../../src/modules/ai-assistant/domain/image-generator.port.js').ImageGenerateInput | undefined;
    const { useCase } = setup(
      {
        generate: async (input) => {
          captured = input;
          return {
            imageUrl: 'http://localhost:8188/view?image=a.png',
            prompt: input.positive,
            provider: 'comfyui',
          };
        },
        isAvailable: async () => true,
      },
      fakeOptimizer({
        optimize: async () => {
          throw new Error('llm down');
        },
      }),
    );
    const result = await useCase.execute(DTO);
    expect(result.imageUrl).toContain('localhost:8188');
    expect(captured?.positive).toContain('masterpiece');
    expect(captured?.positive).toContain('Tris');
    expect(captured?.positive).toContain('Tri rapide');
    expect(captured?.positive).toContain('Quick sort');
    expect(captured?.negative).toBeUndefined();
    expect(result.prompt).toContain('Tris');
  });

  it('answers 503 IMAGE_SERVICE_UNAVAILABLE while ComfyUI is a stub', async () => {
    const { useCase } = setup({
      generate: async () => {
        throw new ImageServiceUnavailableError();
      },
      isAvailable: async () => false,
    });
    await expect(useCase.execute(DTO)).rejects.toMatchObject({
      statusCode: 503,
      code: 'IMAGE_SERVICE_UNAVAILABLE',
    });
  });

  it('enforces ownership and section existence (404)', async () => {
    const { useCase } = setup({ generate: async () => { throw new Error('never'); }, isAvailable: async () => false });
    await expect(
      useCase.execute({ ...DTO, requesterId: 'intruder' }),
    ).rejects.toMatchObject({ statusCode: 404 });
    await expect(
      useCase.execute({ ...DTO, sectionKey: 'unknown' }),
    ).rejects.toMatchObject({ statusCode: 404 });
  });
});

describe('Unit: PublishCourseUseCase (RG27 section gate)', () => {
  const setup = async (statuses: CourseSection['status'][]) => {
    const sections = new FakeSectionRepository();
    sections.rows = statuses.map((status, index) => ({
      id: `s${index}`,
      courseId: ACCESS.courseId,
      sectionKey: `sec-${index + 1}`,
      title: `Partie ${index + 1}`,
      description: '',
      keyTopics: [],
      content: '## x',
      order: index,
      estimatedMinutes: 15,
      status,
    }));
    return { sections, useCase: new PublishCourseUseCase(makeCourseRepo(makeCourse()), sections) };
  };

  it('refuses publication while a section is not validated (409)', async () => {
    const { useCase } = await setup(['VALIDATED', 'GENERATED']);
    await expect(useCase.execute(ACCESS)).rejects.toMatchObject({
      statusCode: 409,
      code: 'SECTIONS_NOT_VALIDATED',
    });
  });

  it('publishes once every section is validated', async () => {
    const { useCase } = await setup(['VALIDATED', 'VALIDATED']);
    const course = await useCase.execute(ACCESS);
    expect(course.status).toBe('PUBLISHED');
  });

  it('still publishes single-document courses that have no sections', async () => {
    const { useCase } = await setup([]);
    const course = await useCase.execute(ACCESS);
    expect(course.status).toBe('PUBLISHED');
  });

  it('keeps the author-only rule (403 for others, 404 for missing)', async () => {
    const { useCase } = await setup(['VALIDATED']);
    await expect(
      useCase.execute({ ...ACCESS, requesterId: 'intruder' }),
    ).rejects.toMatchObject({ statusCode: 403 });
    const orphan = new PublishCourseUseCase(makeCourseRepo(null), undefined);
    await expect(orphan.execute(ACCESS)).rejects.toMatchObject({ statusCode: 404 });
  });
});


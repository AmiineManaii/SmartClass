import { describe, it, expect } from 'vitest';
import {
  CALIBRATED_MIN_VECTOR_SCORE,
  CourseKnowledgeGroundingService,
} from '../../src/modules/ai-assistant/application/course-knowledge-grounding.service.js';
import { GenerateCourseUseCase } from '../../src/modules/ai-assistant/application/generate-course.use-case.js';
import { GenerateOutlineUseCase } from '../../src/modules/ai-assistant/application/generate-outline.use-case.js';
import { GenerateSectionUseCase } from '../../src/modules/ai-assistant/application/generate-section.use-case.js';
import { ImprovePdfUseCase } from '../../src/modules/ai-assistant/application/improve-pdf.use-case.js';
import { RefineSectionUseCase } from '../../src/modules/ai-assistant/application/refine-section.use-case.js';
import { SectionMemoryService } from '../../src/modules/ai-assistant/application/section-memory.service.js';
import type { AiGatewayPort } from '../../src/modules/ai-assistant/domain/ai-gateway.port.js';
import {
  buildCourseFromOutlinePrompt,
  buildCoursePrompt,
  buildOutlinePrompt,
  buildRefineSectionPrompt,
  buildSectionPrompt,
  COURSE_PROMPT_VERSION,
} from '../../src/modules/ai-assistant/domain/course-prompt.js';
import type { EmbeddingPort } from '../../src/modules/ai-assistant/domain/embedding.port.js';
import type { SectionMemoryPort } from '../../src/modules/ai-assistant/domain/section-memory.port.js';
import type { UrlFetcherPort } from '../../src/modules/ai-assistant/domain/url-fetcher.port.js';
import type { PdfTextExtractorPort } from '../../src/modules/ai-assistant/infrastructure/pdf-text-extractor.adapter.js';
import {
  generateOutlineBodySchema,
  knowledgeGroundingSchema,
} from '../../src/modules/ai-assistant/presentation/ai.validation.js';
import type { CourseRepositoryPort } from '../../src/modules/courses/domain/course-repository.port.js';
import type { CourseSectionRepositoryPort } from '../../src/modules/courses/domain/course-section-repository.port.js';
import type { CourseSection } from '../../src/modules/courses/domain/course-section.entity.js';
import type { CourseDetail } from '../../src/modules/courses/domain/course.entity.js';
import type {
  KnowledgeRetrievalPort,
  KnowledgeSearchHit,
  KnowledgeSearchRequest,
  KnowledgeSearchResult,
} from '../../src/modules/knowledge/index.js';

const makeHit = (overrides: Partial<KnowledgeSearchHit> = {}): KnowledgeSearchHit => ({
  chunkId: '11111111-1111-4111-8111-111111111111',
  documentId: '22222222-2222-4222-8222-222222222222',
  sourceType: 'LECTURE_TRANSCRIPT',
  sourceId: 'rec-1',
  title: 'Introduction aux arbres AVL',
  subject: 'Algorithmique',
  visibility: 'PRIVATE_AUTHOR',
  trustTier: 'VERIFIED',
  sectionTitle: 'Rotations doubles LR et RL',
  headingPath: 'Chapitre 3 > Rotations',
  content: 'Une rotation double gauche-droite corrige un déséquilibre +2 suivi de -1.',
  contextHeader: 'Introduction aux arbres AVL > Rotations doubles',
  startSeconds: 95,
  endSeconds: 140,
  sourcePage: null,
  slideNumber: 4,
  score: 0.91,
  vectorScore: 0.84,
  ftsScore: 0.72,
  metadata: {},
  ...overrides,
});

const makeRetrieval = (
  result: Partial<KnowledgeSearchResult> = {},
): {
  port: KnowledgeRetrievalPort;
  requests: KnowledgeSearchRequest[];
} => {
  const requests: KnowledgeSearchRequest[] = [];
  return {
    requests,
    port: {
      search: async (req) => {
        requests.push(req);
        return {
          query: req.query,
          searchMode: result.searchMode ?? 'HYBRID',
          degradedReason: result.degradedReason ?? null,
          embeddingLatencyMs: 22,
          searchLatencyMs: 8,
          totalLatencyMs: 30,
          candidateCount: result.hits?.length ?? 1,
          hits: result.hits ?? [makeHit()],
        };
      },
    },
  };
};

describe('Unit: CourseKnowledgeGroundingService', () => {
  it('bypasses retrieval and returns DISABLED when enabled is false or requesterId is missing', async () => {
    const { port, requests } = makeRetrieval();
    const service = new CourseKnowledgeGroundingService(port);

    const disabled = await service.resolve({
      requesterId: 'teacher-1',
      requesterRole: 'TEACHER',
      query: 'Arbres AVL',
      options: { enabled: false },
      maxChars: 3000,
    });
    expect(disabled.searchMode).toBe('DISABLED');
    expect(disabled.sources).toEqual([]);
    expect(disabled.promptContext).toBe('');
    expect(requests).toHaveLength(0);

    const anonymous = await service.resolve({
      query: 'Arbres AVL',
      maxChars: 3000,
    });
    expect(anonymous.searchMode).toBe('DISABLED');
    expect(requests).toHaveLength(0);
  });

  it('defaults trustTiers to VERIFIED only unless includeDrafts is explicitly true', async () => {
    const { port, requests } = makeRetrieval();
    const service = new CourseKnowledgeGroundingService(port);

    await service.resolve({
      requesterId: 'teacher-1',
      requesterRole: 'TEACHER',
      query: 'Arbres AVL',
      maxChars: 3000,
    });
    expect(requests[0]?.filters?.trustTiers).toEqual(['VERIFIED']);

    await service.resolve({
      requesterId: 'teacher-1',
      requesterRole: 'TEACHER',
      query: 'Arbres AVL',
      options: {
        includeDrafts: true,
        sourceTypes: ['COURSE', 'LECTURE_TRANSCRIPT'],
        documentIds: ['22222222-2222-4222-8222-222222222222'],
      },
      maxChars: 3000,
    });
    expect(requests[1]?.filters?.trustTiers).toEqual(['VERIFIED', 'DRAFT_AI']);
    expect(requests[1]?.filters?.sourceTypes).toEqual(['COURSE', 'LECTURE_TRANSCRIPT']);
    expect(requests[1]?.filters?.documentIds).toEqual([
      '22222222-2222-4222-8222-222222222222',
    ]);
  });

  it('enforces calibrated cosine cutoff (< 0.65) unless documents are explicitly pinned', async () => {
    const weakHit = makeHit({
      chunkId: '33333333-3333-4333-8333-333333333333',
      title: 'Recette sans rapport',
      vectorScore: CALIBRATED_MIN_VECTOR_SCORE - 0.08,
    });
    const strongHit = makeHit({
      chunkId: '44444444-4444-4444-8444-444444444444',
      title: 'Équilibrage AVL',
      vectorScore: CALIBRATED_MIN_VECTOR_SCORE + 0.12,
    });
    const { port } = makeRetrieval({ hits: [strongHit, weakHit] });
    const service = new CourseKnowledgeGroundingService(port);

    const unpinned = await service.resolve({
      requesterId: 'teacher-1',
      requesterRole: 'TEACHER',
      query: 'Arbres AVL',
      maxChars: 4000,
    });
    expect(unpinned.sources.map((s) => s.title)).toEqual(['Équilibrage AVL']);

    const pinned = await service.resolve({
      requesterId: 'teacher-1',
      requesterRole: 'TEACHER',
      query: 'Arbres AVL',
      options: { documentIds: [weakHit.documentId] },
      maxChars: 4000,
    });
    expect(pinned.sources).toHaveLength(2);
  });

  it('reports honest FTS_ONLY degradation and filters excludeSourceIds + respects maxChars', async () => {
    const hitA = makeHit({
      chunkId: 'a1',
      sourceId: 'sec-self',
      title: 'Section actuelle',
      vectorScore: null,
      ftsScore: 0.45,
      content: 'Contenu self',
    });
    const hitB = makeHit({
      chunkId: 'b1',
      sourceId: 'sec-other',
      title: 'Séance précédentes',
      vectorScore: null,
      ftsScore: 0.35,
      content: 'Explication détaillée '.repeat(25),
    });
    const hitC = makeHit({
      chunkId: 'c1',
      sourceId: 'sec-third',
      title: 'Cours 3',
      vectorScore: null,
      ftsScore: 0.25,
      content: 'Autre contenu très long '.repeat(40),
    });

    const { port } = makeRetrieval({
      searchMode: 'FTS_ONLY',
      degradedReason: 'Embedding model offline',
      hits: [hitA, hitB, hitC],
    });
    const service = new CourseKnowledgeGroundingService(port);

    const outcome = await service.resolve({
      requesterId: 'teacher-1',
      query: 'Complexité temporelle',
      maxChars: 650,
      excludeSourceIds: ['sec-self'],
    });
    expect(outcome.searchMode).toBe('FTS_ONLY');
    expect(outcome.degradedReason).toBe('Embedding model offline');
    expect(outcome.sources.map((s) => s.sourceId)).toEqual(['sec-other']);
    expect(outcome.promptContext).toContain('[KB-1]');
    expect(outcome.promptContext).toContain('[01:35]');
    expect(outcome.promptContext).toContain('Slide #4');
    expect(outcome.promptContext.length).toBeLessThanOrEqual(650);
  });

  it('degrades gracefully without throwing when retrieval fails', async () => {
    const failingPort: KnowledgeRetrievalPort = {
      search: async () => {
        throw new Error('database unreachable');
      },
    };
    const service = new CourseKnowledgeGroundingService(failingPort);

    const outcome = await service.resolve({
      requesterId: 'teacher-1',
      query: 'Algorithmique',
      maxChars: 2000,
    });
    expect(outcome.searchMode).toBe('FTS_ONLY');
    expect(outcome.sources).toEqual([]);
    expect(outcome.degradedReason).toBeTruthy();
  });
});

describe('Unit: Phase 2 Prompts & Course Creator Use Cases with RAG', () => {
  it('injects bounded teacher knowledge into all 5 prompt builders and bumps COURSE_PROMPT_VERSION', () => {
    expect(COURSE_PROMPT_VERSION).toMatch(/^\d{4}-\d{2}-\d{2}\.v\d+$/);
    const kb = '[KB-1] (Cours | Vérifié) Cours AVL\nInvariant de hauteur <= 1.';

    const p1 = buildOutlinePrompt({
      topic: 'Arbres rouge-noir',
      level: 'equilibre',
      difficulty: 'moyen',
      knowledgeContext: kb,
    });
    const p2 = buildCoursePrompt({
      mode: 'topic',
      level: 'equilibre',
      difficulty: 'moyen',
      format: 'resume',
      subject: 'Arbres rouge-noir',
      extras: { examples: true, mermaid: true, webImages: false, webSearch: false, thinking: false },
      toolsOffered: false,
      knowledgeContext: kb,
    });
    const p3 = buildCourseFromOutlinePrompt({
      outline: {
        title: 'Arbres rouge-noir',
        targetAudience: 'L3',
        prerequisites: [],
        sections: [{ id: 's1', title: 'Propriétés', description: '5 invariants', keyTopics: ['Hauteur noire'] }],
      },
      level: 'equilibre',
      difficulty: 'moyen',
      extras: { examples: true, mermaid: true, webImages: false, webSearch: false, thinking: false },
      format: 'resume',
      toolsOffered: false,
      knowledgeContext: kb,
    });
    const p4 = buildSectionPrompt({
      courseTitle: 'Arbres rouge-noir',
      outlineTitles: ['Propriétés'],
      level: 'equilibre',
      difficulty: 'moyen',
      section: { title: 'Propriétés', description: 'Invariants', keyTopics: ['Couleur'] },
      position: { index: 1, total: 1 },
      writtenTitles: [],
      knowledgeContext: kb,
    });
    const p5 = buildRefineSectionPrompt({
      courseTitle: 'Arbres rouge-noir',
      selectedText: 'Texte original',
      instruction: 'Clarifie',
      knowledgeContext: kb,
    });

    for (const p of [p1, p2, p3, p4, p5]) {
      expect(p.user).toContain("BASE DE CONNAISSANCES DE L'ENSEIGNANT");
      expect(p.user).toContain('[KB-1]');
    }
  });

  it('GenerateCourseUseCase fixes prepared.outline bug and emits knowledge -> generating phases in stream()', async () => {
    const capturedUsers: string[] = [];
    const fakeGateway: AiGatewayPort = {
      chatCompletion: async (input) => {
        capturedUsers.push(input.user);
        return { content: '# Cours généré', promptTokens: 20, completionTokens: 40, model: 'gemma4:e4b', toolsUsed: false };
      },
      streamCompletion: async (input, onDelta) => {
        capturedUsers.push(input.user);
        onDelta('# Cours streamé');
        return { promptTokens: 15, completionTokens: 30, model: 'gemma4:e4b' };
      },
      checkHealth: async () => ({ available: true, model: 'gemma4:e4b', latencyMs: 10 }),
    };
    const fakeFetcher: UrlFetcherPort = {
      fetchText: async (url) => ({ finalUrl: url, title: 'T', text: 'x'.repeat(200) }),
    };
    const { port } = makeRetrieval();
    const grounding = new CourseKnowledgeGroundingService(port);
    const useCase = new GenerateCourseUseCase(fakeGateway, fakeFetcher, grounding);

    const phases: string[] = [];
    const outline = {
      title: 'Structures arborescentes',
      targetAudience: 'L3 Info',
      prerequisites: ['Pointeurs'],
      sections: [
        { id: 'sec-1', title: 'Rotations AVL', description: 'Rééquilibrage', keyTopics: ['Rotation gauche'] },
      ],
    };

    const meta = await useCase.stream(
      {
        mode: 'topic',
        level: 'equilibre',
        format: 'resume',
        subject: 'Structures arborescentes',
        outline,
        requesterId: 'teacher-1',
        requesterRole: 'TEACHER',
      },
      () => undefined,
      (phase) => phases.push(phase),
    );

    expect(phases).toEqual(['knowledge', 'generating']);
    expect(capturedUsers[0]).toContain("PLAN VALIDÉ PAR L'ENSEIGNANT");
    expect(capturedUsers[0]).toContain('Rotations AVL');
    expect(capturedUsers[0]).toContain('[KB-1]');
    expect(meta.knowledgeSearchMode).toBe('HYBRID');
    expect(meta.knowledgeSources).toHaveLength(1);
    expect(meta.knowledgeSources[0]?.title).toBe('Introduction aux arbres AVL');
  });

  it('GenerateOutlineUseCase, ImprovePdfUseCase, GenerateSectionUseCase & RefineSectionUseCase return attribution', async () => {
    const gateway: AiGatewayPort = {
      chatCompletion: async () => ({
        content: JSON.stringify({
          title: 'Plan IA',
          targetAudience: 'L3',
          prerequisites: [],
          sections: [{ id: 'sec-1', title: 'Intro', description: 'Desc', keyTopics: ['A'], estimatedMinutes: 15 }],
        }),
        promptTokens: 10,
        completionTokens: 20,
        model: 'gemma4:e4b',
        toolsUsed: false,
      }),
      streamCompletion: async (_i, onDelta) => {
        onDelta('## Intro\nContenu');
        return { promptTokens: 10, completionTokens: 20, model: 'gemma4:e4b' };
      },
      checkHealth: async () => ({ available: true, model: 'gemma4:e4b', latencyMs: 5 }),
    };
    const { port } = makeRetrieval();
    const grounding = new CourseKnowledgeGroundingService(port);

    const outlineUc = new GenerateOutlineUseCase(gateway, grounding);
    const outlineRes = await outlineUc.execute({
      topic: 'Arbres AVL',
      requesterId: 'teacher-1',
      requesterRole: 'TEACHER',
    });
    expect(outlineRes.knowledgeSources).toHaveLength(1);
    expect(outlineRes.knowledgeSearchMode).toBe('HYBRID');

    const pdfExtractor: PdfTextExtractorPort = {
      extract: async () => ({ text: 'Contenu PDF complet '.repeat(20), totalPages: 2 }),
    };
    const pdfUc = new ImprovePdfUseCase(pdfExtractor, gateway, grounding);
    const pdfPhases: string[] = [];
    const pdfMeta = await pdfUc.stream(
      {
        file: { buffer: Buffer.from('%PDF-1.4'), originalName: 'avl.pdf', size: 512 },
        level: 'equilibre',
        format: 'resume',
        requesterId: 'teacher-1',
        requesterRole: 'TEACHER',
      },
      () => undefined,
      (p) => pdfPhases.push(p),
    );
    expect(pdfPhases).toEqual(['knowledge', 'generating']);
    expect(pdfMeta.knowledgeSources).toHaveLength(1);

    const fakeCourse: CourseDetail = {
      id: 'c1',
      title: 'Algo',
      subject: 'Info',
      content: '# Algo',
      level: 'equilibre',
      difficulty: 'moyen',
      format: 'resume',
      status: 'DRAFT',
      authorId: 'teacher-1',
      authorName: 'Prof',
      classGroupIds: [],
      outline: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    const courseRepo: CourseRepositoryPort = {
      save: async () => fakeCourse,
      update: async () => fakeCourse,
      listByAuthor: async () => [],
      listPublished: async () => [],
      findById: async () => fakeCourse,
      updateStatus: async () => fakeCourse,
      remove: async () => undefined,
    };
    const secRow: CourseSection = {
      id: 'sec-row-1',
      courseId: 'c1',
      sectionKey: 'sec-1',
      title: 'Intro',
      description: 'Desc',
      keyTopics: ['AVL'],
      content: null,
      order: 0,
      estimatedMinutes: 15,
      status: 'PENDING',
    };
    const secRepo: CourseSectionRepositoryPort = {
      initFromOutline: async () => [secRow],
      listByCourse: async () => [secRow],
      findByKey: async () => secRow,
      saveContent: async ({ content, status }) => ({ ...secRow, content, status: status ?? 'GENERATED' }),
      updateStatus: async (_c, _k, status) => ({ ...secRow, status }),
      countNotValidated: async () => 1,
    };
    const embedder: EmbeddingPort = {
      embed: async () => Array.from({ length: 768 }, () => 0),
      checkHealth: async () => ({ available: true, model: 'embeddinggemma', latencyMs: 1 }),
    };
    const memPort: SectionMemoryPort = {
      store: async (p) => ({ ...p, id: 'm1' }),
      search: async () => [],
    };
    const genSecUc = new GenerateSectionUseCase(
      gateway,
      courseRepo,
      secRepo,
      new SectionMemoryService(memPort, embedder),
      undefined,
      grounding,
    );
    const secPhases: string[] = [];
    const secMeta = await genSecUc.stream(
      { requesterId: 'teacher-1', requesterRole: 'TEACHER', courseId: 'c1', sectionKey: 'sec-1' },
      () => undefined,
      (p) => secPhases.push(p),
    );
    expect(secPhases).toEqual(['knowledge', 'generating']);
    expect(secMeta.knowledgeSources).toHaveLength(1);
    expect(secMeta.memoryHits).toBe(1);

    const refineUc = new RefineSectionUseCase(
      gateway,
      courseRepo,
      new SectionMemoryService(memPort, embedder),
      grounding,
    );
    const refineRes = await refineUc.execute({
      courseId: 'c1',
      selectedText: 'Ancien texte',
      instruction: 'Ajoute rotation',
      requesterId: 'teacher-1',
      requesterRole: 'TEACHER',
    });
    expect(refineRes.knowledgeSources).toHaveLength(1);
    expect(refineRes.knowledgeSearchMode).toBe('HYBRID');
  });

  it('validates knowledge options in both JSON and multipart string form (strict)', () => {
    const jsonStringParsed = knowledgeGroundingSchema.safeParse(
      JSON.stringify({ enabled: true, includeDrafts: true, maxChunks: 4 }),
    );
    expect(jsonStringParsed.success).toBe(true);
    expect(jsonStringParsed.data).toEqual({
      enabled: true,
      includeDrafts: true,
      maxChunks: 4,
    });

    const invalidKey = knowledgeGroundingSchema.safeParse({ unknownField: 123 });
    expect(invalidKey.success).toBe(false);

    const badUuid = knowledgeGroundingSchema.safeParse({ documentIds: ['not-uuid'] });
    expect(badUuid.success).toBe(false);

    const outlineParsed = generateOutlineBodySchema.safeParse({
      subject: 'Les graphes orientés',
      knowledge: { enabled: true, sourceTypes: ['COURSE', 'LECTURE_TRANSCRIPT'] },
    });
    expect(outlineParsed.success).toBe(true);
    if (outlineParsed.success) {
      expect(outlineParsed.data.knowledge).toEqual({
        enabled: true,
        sourceTypes: ['COURSE', 'LECTURE_TRANSCRIPT'],
      });
    }
  });
});

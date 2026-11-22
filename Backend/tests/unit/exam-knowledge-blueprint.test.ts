import { describe, expect, it, vi } from 'vitest';
import type { Role } from '../../src/modules/auth/index.js';
import type {
  KnowledgeRetrievalPort,
  KnowledgeSearchRequest,
  KnowledgeSearchResult,
} from '../../src/modules/knowledge/index.js';
import {
  ExamKnowledgeBlueprintService,
  allocateWaterFillingBudgets,
  distributeQuestionQuotas,
  extractCourseChapterTitles,
  isPracticeQuizOrAnswerKeyHeading,
  parseCourseChaptersForExam,
} from '../../src/modules/exams/application/exam-knowledge-blueprint.service.js';
import { extractJsonPayload } from '../../src/modules/exams/application/exam-ai.prompt.js';
import { ListClassCoursesUseCase } from '../../src/modules/exams/application/list-class-courses.use-case.js';
import { FakeExamRepository } from './exams.test-helpers.js';

const TEACHER: Role = 'TEACHER';

describe('Exam knowledge blueprint helpers', () => {
  it('allocates max-min fair water-filling budgets without starving subsequent short courses', () => {
    const budgets = allocateWaterFillingBudgets(
      [
        { id: 'huge-course-1', rawChars: 30_000 },
        { id: 'short-course-2', rawChars: 1_200 },
        { id: 'short-course-3', rawChars: 1_500 },
      ],
      6_000,
    );

    expect(budgets.get('short-course-2')).toBe(1_200);
    expect(budgets.get('short-course-3')).toBe(1_500);
    expect(budgets.get('huge-course-1')).toBe(3_300);
    const total = Array.from(budgets.values()).reduce((sum, val) => sum + val, 0);
    expect(total).toBe(6_000);
  });

  it('distributes question quotas fairly with at least 1 question per source when possible', () => {
    const quotas = distributeQuestionQuotas(3, 10);
    expect(quotas).toHaveLength(3);
    expect(quotas.reduce((sum, q) => sum + q, 0)).toBe(10);
    expect(quotas.every((q) => q >= 3)).toBe(true);

    const tightQuotas = distributeQuestionQuotas(4, 2);
    expect(tightQuotas).toHaveLength(4);
    expect(tightQuotas.reduce((sum, q) => sum + q, 0)).toBe(2);
    expect(tightQuotas.filter((q) => q === 1)).toHaveLength(2);
  });

  it('parses Markdown chapters, ignores fenced code blocks, and strips practice quiz / answer keys', () => {
    const markdown = [
      '# Cours d’Algorithmique',
      '',
      '## Chapitre 1 : Graphes orientés',
      'Un graphe orienté G = (V, E) modélise des dépendances asymétriques.',
      '```python',
      '# Ce commentaire Python ne doit pas créer de chapitre',
      'def bfs(graph): pass',
      '```',
      '',
      '## Chapitre 2 : Parcours en largeur',
      'BFS explore par couches successives en O(V + E).',
      '',
      '## Quiz rapide',
      'Question bonus hors examen.',
      '',
      '## Correction du quiz',
      'Réponse Q1 : B (secret answer key)',
    ].join('\n');

    const titles = extractCourseChapterTitles(markdown);
    expect(titles).toEqual([
      'Chapitre 1 : Graphes orientés',
      'Chapitre 2 : Parcours en largeur',
    ]);

    const chapters = parseCourseChaptersForExam(markdown);
    expect(chapters).toHaveLength(2);
    expect(chapters[0]?.title).toBe('Chapitre 1 : Graphes orientés');
    expect(chapters[0]?.content).toContain('def bfs(graph)');
    expect(chapters[1]?.title).toBe('Chapitre 2 : Parcours en largeur');

    expect(extractCourseChapterTitles('Simple texte sans titre Markdown.')).toEqual([]);
    expect(isPracticeQuizOrAnswerKeyHeading('Corrigé')).toBe(true);
    expect(isPracticeQuizOrAnswerKeyHeading('Answer Key')).toBe(true);
    expect(isPracticeQuizOrAnswerKeyHeading('Chapitre 3 : Correspondances')).toBe(false);
  });
});

describe('ExamKnowledgeBlueprintService', () => {
  it('covers multiple courses and chapters equitably and emits transparent truncation warnings', async () => {
    const hugeChapter = 'Notion fondamentale de graphe pondéré et algorithme de Dijkstra. '.repeat(
      260,
    );
    const service = new ExamKnowledgeBlueprintService();
    const blueprint = await service.build({
      requesterId: 'teacher-1',
      requesterRole: TEACHER,
      title: 'Partiel Algorithmique',
      questionCount: 8,
      maxSourceChars: 3_000,
      courses: [
        {
          id: 'c-1',
          title: 'Théorie des Graphes',
          subject: 'Informatique',
          content: `## Chapitre 1 : Plus courts chemins\n${hugeChapter}\n\n## Correction du quiz\nRéponse: A`,
        },
        {
          id: 'c-2',
          title: 'Programmation Dynamique',
          subject: 'Informatique',
          content:
            '## Chapitre 1 : Mémoïsation\nLa mémoïsation évite de recalculer les sous-problèmes chevauchants en O(n).',
        },
      ],
    });

    expect(blueprint.searchMode).toBe('DIRECT_BALANCED');
    expect(blueprint.coverage.totalSources).toBe(2);
    expect(blueprint.coverage.coveredSources).toBe(2);
    expect(blueprint.coverage.truncated).toBe(true);
    expect(blueprint.coverage.warnings.length).toBeGreaterThan(0);

    expect(blueprint.promptContext).toContain('Théorie des Graphes');
    expect(blueprint.promptContext).toContain('Programmation Dynamique');
    expect(blueprint.promptContext).toContain('Mémoïsation');
    expect(blueprint.promptContext).not.toContain('Réponse: A');

    const c2Coverage = blueprint.coverage.distribution.find((d) => d.sourceId === 'c-2');
    expect(c2Coverage?.trimmed).toBe(false);
    expect(c2Coverage?.targetQuestions).toBe(4);
  });

  it('filters chapters accent-insensitively and passes VERIFIED default or opt-in DRAFT_AI to KnowledgeRetrievalPort', async () => {
    const requests: KnowledgeSearchRequest[] = [];
    const retrieval: KnowledgeRetrievalPort = {
      search: vi.fn(async (req: KnowledgeSearchRequest): Promise<KnowledgeSearchResult> => {
        requests.push(req);
        return {
          query: req.query,
          searchMode: 'FTS_ONLY',
          degradedReason: 'Embedding runtime unavailable in test',
          embeddingLatencyMs: null,
          searchLatencyMs: 5,
          totalLatencyMs: 6,
          candidateCount: 1,
          hits: [
            {
              chunkId: 'chunk-1',
              documentId: 'doc-video-1',
              sourceType: 'LECTURE_PACKAGE',
              sourceId: 'rec-1',
              title: 'Séance 4 : Backpropagation',
              subject: 'Deep Learning',
              visibility: 'PRIVATE_AUTHOR',
              trustTier: 'VERIFIED',
              sectionTitle: 'Descente de gradient',
              headingPath: 'Descente de gradient',
              content:
                'La rétropropagation calcule le gradient de la fonction de perte via la règle de dérivation en chaîne.',
              contextHeader: 'Séance 4',
              startSeconds: 185,
              endSeconds: 245,
              sourcePage: null,
              slideNumber: 7,
              score: 0.9,
              vectorScore: null,
              ftsScore: 0.9,
              metadata: {},
            },
          ],
        };
      }),
    };

    const service = new ExamKnowledgeBlueprintService(retrieval);

    // Default (includeDrafts omitted => false => VERIFIED only)
    const bpDefault = await service.build({
      requesterId: 'teacher-1',
      requesterRole: TEACHER,
      title: 'Examen Deep Learning',
      questionCount: 4,
      maxSourceChars: 6_000,
      chapters: ['Reseaux convolutifs'],
      courses: [
        {
          id: 'course-dl',
          title: 'Deep Learning',
          subject: 'IA',
          content: [
            '## Perceptrons',
            'Un perceptron applique une combinaison linéaire.',
            '## Réseaux convolutifs',
            'Les CNN exploitent des filtres partagés invariants par translation.',
          ].join('\n'),
        },
      ],
      knowledgeDocumentIds: ['doc-video-1'],
    });

    expect(bpDefault.searchMode).toBe('FTS_ONLY');
    expect(bpDefault.degradedReason).toContain('Embedding runtime unavailable');
    expect(requests.every((r) => r.filters?.trustTiers?.length === 1 && r.filters.trustTiers[0] === 'VERIFIED')).toBe(
      true,
    );
    expect(bpDefault.promptContext).toContain('filtres partagés');
    expect(bpDefault.promptContext).not.toContain('Un perceptron applique');
    expect(bpDefault.promptContext).toContain('[03:05]');
    expect(bpDefault.promptContext).toContain('Slide #7');

    // Explicit opt-in includeDrafts: true
    requests.length = 0;
    await service.build({
      requesterId: 'teacher-1',
      requesterRole: TEACHER,
      title: 'Examen avec brouillons',
      questionCount: 4,
      maxSourceChars: 6_000,
      includeDrafts: true,
      courses: [],
      knowledgeDocumentIds: ['doc-video-1'],
    });

    expect(requests[0]?.filters?.trustTiers).toEqual(['VERIFIED', 'DRAFT_AI']);
  });
});

describe('ListClassCoursesUseCase with chapter extraction', () => {
  it('returns parsed teaching chapters when Markdown headings exist while omitting chapters for headingless text', async () => {
    const repo = new FakeExamRepository();
    repo.addClass('c-1', 'L3 Info');
    repo.allowTeacher('t-1', 'c-1');
    repo.classCourses.set('c-1', [
      {
        id: 'structured',
        title: 'Algèbre Linéaire',
        subject: 'Maths',
        content: '## Espaces vectoriels\nDéfinition...\n## Valeurs propres\nPolynôme caractéristique...\n## Corrigé\n1: A',
      },
      {
        id: 'plain',
        title: 'Notes brutes',
        subject: 'Maths',
        content: 'Résumé linéaire sans balisage Markdown.',
      },
    ]);

    const useCase = new ListClassCoursesUseCase(repo);
    const list = await useCase.execute({
      requesterId: 't-1',
      requesterRole: TEACHER,
      classGroupId: 'c-1',
    });

    expect(list).toEqual([
      {
        id: 'structured',
        title: 'Algèbre Linéaire',
        subject: 'Maths',
        chapters: ['Espaces vectoriels', 'Valeurs propres'],
      },
      {
        id: 'plain',
        title: 'Notes brutes',
        subject: 'Maths',
      },
    ]);
  });
});

describe('extractJsonPayload', () => {
  it('parses fenced JSON, repairs minor unclosed options array or trailing comma, and rejects non-JSON prose', () => {
    const fenced = '```json\n{"title":"QCM","questions":[]}\n```';
    expect(extractJsonPayload(fenced)).toEqual({ title: 'QCM', questions: [] });

    const brokenOptions =
      '{"title":"Test","questions":[{"prompt":"Q1","options":["A1","B1","C1","D1","correctOptionId":"A","explanation":"Ok","points":1,}]}';
    expect(extractJsonPayload(brokenOptions)).toEqual({
      title: 'Test',
      questions: [
        {
          prompt: 'Q1',
          options: ['A1', 'B1', 'C1', 'D1'],
          correctOptionId: 'A',
          explanation: 'Ok',
          points: 1,
        },
      ],
    });

    expect(() => extractJsonPayload('Voici un texte sans objet JSON valide.')).toThrow();
  });
});

import { describe, it, expect } from 'vitest';
import type { Role } from '../../src/modules/auth/index.js';
import type {
  CourseDetail,
  CourseStatus,
  CourseSummary,
} from '../../src/modules/courses/domain/course.entity.js';
import type {
  CourseRepositoryPort,
  SaveCourseParams,
  UpdateCourseParams,
} from '../../src/modules/courses/domain/course-repository.port.js';
import type {
  CourseStudyArtifact,
  CourseTutorCitation,
  CourseTutorConversation,
  CourseTutorMessage,
} from '../../src/modules/courses/domain/course-study.entity.js';
import type {
  AppendCourseTutorMessageParams,
  CourseStudyRepositoryPort,
  CreateCourseStudyArtifactParams,
  CreateCourseTutorConversationParams,
} from '../../src/modules/courses/domain/course-study-repository.port.js';
import type {
  CoursePassageHit,
  CoursePassageRetrievalPort,
} from '../../src/modules/courses/domain/course-passage-retrieval.port.js';
import type {
  ModelRole,
  SmartModelRouterPort,
} from '../../src/modules/ai-assistant/index.js';
import {
  evaluateCourseScope,
  parseFlashcardsJson,
  splitCoursePassages,
} from '../../src/modules/courses/domain/course-grounding.js';
import { GenerateCourseStudyArtifactUseCase } from '../../src/modules/courses/application/generate-course-study-artifact.use-case.js';
import { AskCourseTutorUseCase } from '../../src/modules/courses/application/ask-course-tutor.use-case.js';
import { GetCourseStudyWorkspaceUseCase } from '../../src/modules/courses/application/course-study.use-cases.js';
import { NotFoundError } from '../../src/shared/errors/app-error.js';

const STUDENT = 'student-1';
const OTHER_STUDENT = 'student-2';
const TEACHER = 'teacher-1';
const STUDENT_ROLE: Role = 'STUDENT';

let seq = 0;

const COURSE_CONTENT = [
  '# Les boucles en Python',
  '',
  'Une boucle `for` parcourt une séquence. La clause `range` génère une suite d’entiers.',
  '',
  '# Les fonctions récursives',
  '',
  'Une fonction récursive s’appelle elle-même et doit avoir un cas de base pour s’arrêter.',
  '',
  '# Les listes',
  '',
  'Une liste Python est ordonnée et mutable, on y accède par index.',
].join('\n');

class FakeCourseRepository implements CourseRepositoryPort {
  readonly store = new Map<string, CourseDetail>();

  seed(overrides: Partial<CourseDetail> = {}): CourseDetail {
    seq += 1;
    const now = new Date();
    const course: CourseDetail = {
      id: `course-${seq}`,
      title: 'Algorithmique en Python',
      subject: 'Informatique',
      content: COURSE_CONTENT,
      outline: null,
      level: 'concis',
      difficulty: 'moyen',
      format: 'resume',
      status: 'PUBLISHED',
      authorId: TEACHER,
      authorName: 'Thomas Laurent',
      createdAt: now,
      updatedAt: now,
      ...overrides,
    };
    this.store.set(course.id, course);
    return course;
  }

  async save(params: SaveCourseParams): Promise<CourseDetail> {
    return this.seed({ authorId: params.authorId, content: params.content, title: params.title });
  }

  async listByAuthor(_authorId: string): Promise<CourseSummary[]> {
    return [];
  }

  async listPublished(): Promise<CourseSummary[]> {
    return [];
  }

  async findById(id: string): Promise<CourseDetail | null> {
    return this.store.get(id) ?? null;
  }

  async updateStatus(id: string, status: CourseStatus): Promise<CourseDetail> {
    const course = this.store.get(id);
    if (!course) throw new Error('missing');
    const next = { ...course, status };
    this.store.set(id, next);
    return next;
  }

  async remove(id: string): Promise<void> {
    this.store.delete(id);
  }

  async update(id: string, params: UpdateCourseParams): Promise<CourseDetail> {
    const course = this.store.get(id);
    if (!course) throw new Error('missing');
    const next = { ...course, ...params };
    this.store.set(id, next);
    return next;
  }
}

class FakeStudyRepository implements CourseStudyRepositoryPort {
  readonly artifacts: CourseStudyArtifact[] = [];
  readonly conversations = new Map<string, CourseTutorConversation>();

  async listArtifacts(courseId: string, userId: string): Promise<CourseStudyArtifact[]> {
    return this.artifacts.filter((a) => a.courseId === courseId && a.userId === userId);
  }

  async createArtifact(params: CreateCourseStudyArtifactParams): Promise<CourseStudyArtifact> {
    seq += 1;
    const artifact: CourseStudyArtifact = {
      id: `artifact-${seq}`,
      ...params,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.artifacts.push(artifact);
    return artifact;
  }

  async deleteArtifact(artifactId: string, userId: string): Promise<boolean> {
    const index = this.artifacts.findIndex((a) => a.id === artifactId && a.userId === userId);
    if (index === -1) return false;
    this.artifacts.splice(index, 1);
    return true;
  }

  async listConversations(courseId: string, userId: string): Promise<CourseTutorConversation[]> {
    return [...this.conversations.values()].filter(
      (c) => c.courseId === courseId && c.userId === userId,
    );
  }

  async findConversation(id: string, userId: string): Promise<CourseTutorConversation | null> {
    const conversation = this.conversations.get(id);
    return conversation && conversation.userId === userId ? conversation : null;
  }

  async createConversation(
    params: CreateCourseTutorConversationParams,
  ): Promise<CourseTutorConversation> {
    seq += 1;
    const conversation: CourseTutorConversation = {
      id: `conversation-${seq}`,
      ...params,
      messages: [],
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.conversations.set(conversation.id, conversation);
    return conversation;
  }

  async appendMessage(params: AppendCourseTutorMessageParams): Promise<CourseTutorMessage> {
    seq += 1;
    const message: CourseTutorMessage = {
      id: `message-${seq}`,
      conversationId: params.conversationId,
      role: params.role,
      content: params.content,
      citations: params.citations ?? [],
      inScope: params.inScope ?? true,
      modelUsed: params.modelUsed ?? null,
      createdAt: new Date(),
    };
    const conversation = this.conversations.get(params.conversationId);
    if (conversation) {
      conversation.messages.push(message);
      conversation.updatedAt = new Date();
    }
    return message;
  }
}

class FakeModelRouter implements SmartModelRouterPort {
  calls: ModelRole[] = [];
  fail = false;
  reply = '';

  async inspectInventory() {
    throw new Error('not used');
  }

  async inspectModels() {
    throw new Error('not used');
  }

  async completeForRole() {
    throw new Error('not used');
  }

  async generateForRole(role: ModelRole): Promise<{
    content: string;
    modelUsed: string;
    fallbackUsed: boolean;
  }> {
    this.calls.push(role);
    if (this.fail) throw new Error('ollama offline');
    return { content: this.reply, modelUsed: 'qwen-local', fallbackUsed: false };
  }

  async streamForRole() {
    throw new Error('not used');
  }

  async analyzeVisualFrame() {
    throw new Error('not used');
  }
}

class FakeRetrieval implements CoursePassageRetrievalPort {
  hits: CoursePassageHit[] = [];
  async search(): Promise<CoursePassageHit[]> {
    return this.hits;
  }
}

const buildSummaryUseCase = (repo: FakeCourseRepository) => {
  const study = new FakeStudyRepository();
  const router = new FakeModelRouter();
  const useCase = new GenerateCourseStudyArtifactUseCase(repo, undefined, study, router);
  return { study, router, useCase };
};

describe('Unit: course grounding', () => {
  it('splits Markdown into citable chapters', () => {
    const passages = splitCoursePassages(COURSE_CONTENT, 'Cours');
    expect(passages.map((p) => p.title)).toEqual([
      'Les boucles en Python',
      'Les fonctions récursives',
      'Les listes',
    ]);
    expect(passages[0]?.id).toBe('p-1');
  });

  it('accepts an in-course question and rejects an off-course one', () => {
    const passages = splitCoursePassages(COURSE_CONTENT, 'Cours');
    const inScope = evaluateCourseScope({
      question: 'Comment fonctionne une fonction récursive ?',
      courseTitle: 'Algorithmique en Python',
      courseSubject: 'Informatique',
      passages,
    });
    expect(inScope.inScope).toBe(true);
    expect(inScope.score).toBeGreaterThan(0.34);

    const offCourse = evaluateCourseScope({
      question: 'Quelle est la capitale de la Mongolie ?',
      courseTitle: 'Algorithmique en Python',
      courseSubject: 'Informatique',
      passages,
    });
    expect(offCourse.inScope).toBe(false);
  });

  it('treats a course-level meta request as in scope', () => {
    const passages = splitCoursePassages(COURSE_CONTENT, 'Cours');
    const scope = evaluateCourseScope({
      question: 'Résume ce cours',
      courseTitle: 'Algorithmique en Python',
      passages,
    });
    expect(scope.inScope).toBe(true);
  });

  it('parses an LLM flashcard JSON array and ignores junk', () => {
    const cards = parseFlashcardsJson(
      'Voici :\n```json\n[{"front":"Que fait range ?","back":"Elle génère une suite.","sectionTitle":"Chapitre"}]```',
    );
    expect(cards).toHaveLength(1);
    expect(cards[0]?.sectionTitle).toBe('Chapitre');
    expect(parseFlashcardsJson('pas du json')).toEqual([]);
  });
});

describe('Unit: GenerateCourseStudyArtifactUseCase', () => {
  it('falls back to a deterministic extractive summary when the LLM is offline', async () => {
    const repo = new FakeCourseRepository();
    const course = repo.seed();
    const { useCase, study, router } = buildSummaryUseCase(repo);
    router.fail = true;

    const artifact = await useCase.execute({
      requesterId: STUDENT,
      requesterRole: STUDENT_ROLE,
      courseId: course.id,
      artifact: { kind: 'SUMMARY', summaryMode: 'medium' },
    });

    expect(artifact.kind).toBe('SUMMARY');
    expect(artifact.modelUsed).toBe('extractive-fallback');
    const content = artifact.content as { markdown: string; keyTakeaways: string[] };
    expect(content.markdown).toContain('Les boucles en Python');
    expect(content.keyTakeaways.length).toBeGreaterThan(0);
    expect(study.artifacts).toHaveLength(1);
  });

  it('stores an LLM flashcard deck when the model answers valid JSON', async () => {
    const repo = new FakeCourseRepository();
    const course = repo.seed();
    const { useCase, router } = buildSummaryUseCase(repo);
    router.reply =
      '[{"front":"Que fait range ?","back":"Elle génère une suite d’entiers.","sectionTitle":"Les boucles en Python"},' +
      '{"front":"Qu’est-ce qu’un cas de base ?","back":"La condition qui arrête la récursion.","sectionTitle":"Les fonctions récursives"}]';

    const artifact = await useCase.execute({
      requesterId: STUDENT,
      requesterRole: STUDENT_ROLE,
      courseId: course.id,
      artifact: { kind: 'FLASHCARDS', flashcardCount: 4 },
    });

    expect(artifact.kind).toBe('FLASHCARDS');
    expect(artifact.modelUsed).toBe('qwen-local');
    const content = artifact.content as { cards: Array<{ front: string }> };
    expect(content.cards[0]?.front).toBe('Que fait range ?');
  });

  it('never serves a draft to a student (404, no existence oracle)', async () => {
    const repo = new FakeCourseRepository();
    const course = repo.seed({ status: 'DRAFT', authorId: TEACHER });
    const { useCase } = buildSummaryUseCase(repo);

    await expect(
      useCase.execute({
        requesterId: STUDENT,
        requesterRole: STUDENT_ROLE,
        courseId: course.id,
        artifact: { kind: 'SUMMARY' },
      }),
    ).rejects.toBeInstanceOf(NotFoundError);
  });
});

describe('Unit: AskCourseTutorUseCase', () => {
  const buildTutor = (repo: FakeCourseRepository) => {
    const study = new FakeStudyRepository();
    const router = new FakeModelRouter();
    const retrieval = new FakeRetrieval();
    const useCase = new AskCourseTutorUseCase(
      repo,
      undefined,
      study,
      retrieval,
      router,
    );
    return { useCase, study, router, retrieval };
  };

  it('refuses an off-course question without calling the model', async () => {
    const repo = new FakeCourseRepository();
    const course = repo.seed();
    const { useCase, router, retrieval } = buildTutor(repo);
    router.reply = 'should never be used';

    const result = await useCase.execute({
      requesterId: STUDENT,
      requesterRole: STUDENT_ROLE,
      courseId: course.id,
      question: 'Quelle est la capitale de la Mongolie ?',
    });

    expect(router.calls).toHaveLength(0);
    expect(result.assistantMessage.inScope).toBe(false);
    expect(result.assistantMessage.content).toContain('ne porte pas sur le contenu du cours');
    expect(result.assistantMessage.citations).toEqual([]);
    expect(retrieval.hits).toEqual([]);
  });

  it('answers an in-course question with citations from the course', async () => {
    const repo = new FakeCourseRepository();
    const course = repo.seed();
    const { useCase, router } = buildTutor(repo);
    router.reply = 'Une fonction récursive doit avoir un cas de base.';

    const result = await useCase.execute({
      requesterId: STUDENT,
      requesterRole: STUDENT_ROLE,
      courseId: course.id,
      question: 'Comment fonctionne une fonction récursive ?',
    });

    expect(router.calls).toEqual(['AI_TUTOR_RAG']);
    expect(result.assistantMessage.inScope).toBe(true);
    expect(result.assistantMessage.content).toBe(router.reply);
    expect(result.assistantMessage.citations.length).toBeGreaterThan(0);
    expect(result.assistantMessage.citations[0]?.sectionTitle).toContain('récursives');
  });

  it('keeps tutor threads private to their owner', async () => {
    const repo = new FakeCourseRepository();
    const course = repo.seed();
    const { useCase, study } = buildTutor(repo);

    const first = await useCase.execute({
      requesterId: STUDENT,
      requesterRole: STUDENT_ROLE,
      courseId: course.id,
      question: 'Résume ce cours',
    });

    const stolen = await useCase.execute({
      requesterId: OTHER_STUDENT,
      requesterRole: STUDENT_ROLE,
      courseId: course.id,
      question: 'Résume ce cours',
      conversationId: first.conversationId,
    });

    expect(stolen.conversationId).not.toBe(first.conversationId);
    expect(study.conversations.size).toBe(2);
  });
});

describe('Unit: GetCourseStudyWorkspaceUseCase', () => {
  it('returns chapters plus only the caller artifacts', async () => {
    const repo = new FakeCourseRepository();
    const course = repo.seed();
    const study = new FakeStudyRepository();
    const generate = new GenerateCourseStudyArtifactUseCase(
      repo,
      undefined,
      study,
      new FakeModelRouter(),
    );

    await generate.execute({
      requesterId: STUDENT,
      requesterRole: STUDENT_ROLE,
      courseId: course.id,
      artifact: { kind: 'SUMMARY' },
    });
    await generate.execute({
      requesterId: OTHER_STUDENT,
      requesterRole: STUDENT_ROLE,
      courseId: course.id,
      artifact: { kind: 'SUMMARY' },
    });

    const workspace = await new GetCourseStudyWorkspaceUseCase(
      repo,
      undefined,
      study,
    ).execute({
      requesterId: STUDENT,
      requesterRole: STUDENT_ROLE,
      courseId: course.id,
    });

    expect(workspace.courseId).toBe(course.id);
    expect(workspace.chapters).toHaveLength(3);
    expect(workspace.artifacts).toHaveLength(1);
    expect(workspace.artifacts[0]?.userId).toBe(STUDENT);
    expect(workspace.conversations).toEqual([]);
  });
});

describe('Unit: course tutor citations shape', () => {
  it('exposes the citation contract used by the frontend', () => {
    const citation: CourseTutorCitation = {
      passageId: 'p-1',
      sectionTitle: 'Chapitre',
      excerpt: 'Extrait',
      score: 0.5,
    };
    expect(citation.passageId).toBe('p-1');
  });
});

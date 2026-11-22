import { randomUUID } from 'node:crypto';
import { afterAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { getEnv } from '../../src/config/env.js';
import type { AiGatewayPort } from '../../src/modules/ai-assistant/domain/ai-gateway.port.js';
import { ConsoleEmailAdapter } from '../../src/modules/auth/infrastructure/console-email.adapter.js';
import type { KnowledgeEmbeddingPort } from '../../src/modules/knowledge/domain/knowledge-embedding.port.js';
import { computeSha256 } from '../../src/modules/knowledge/domain/structure-chunker.js';
import { getPgPool, getPrismaClient } from '../../src/shared/infrastructure/prisma.js';

const prisma = getPrismaClient();
const pool = getPgPool();

const createdExamIds: string[] = [];
const createdCourseIds: string[] = [];
const createdGroupIds: string[] = [];
const createdDocIds: string[] = [];
const createdUserIds: string[] = [];

const cleanUp = async (): Promise<void> => {
  if (createdExamIds.length > 0) {
    await prisma.examAttempt.deleteMany({
      where: { examId: { in: createdExamIds } },
    });
    await prisma.examQuestion.deleteMany({
      where: { examId: { in: createdExamIds } },
    });
    await prisma.exam.deleteMany({
      where: { id: { in: createdExamIds } },
    });
  }
  if (createdCourseIds.length > 0) {
    await prisma.knowledgeDocument.deleteMany({
      where: { sourceId: { in: createdCourseIds } },
    });
    await prisma.course.deleteMany({
      where: { id: { in: createdCourseIds } },
    });
  }
  if (createdDocIds.length > 0) {
    await prisma.knowledgeDocument.deleteMany({
      where: { id: { in: createdDocIds } },
    });
  }
  if (createdGroupIds.length > 0) {
    await prisma.groupMember.deleteMany({
      where: { classGroupId: { in: createdGroupIds } },
    });
    await prisma.classGroup.deleteMany({
      where: { id: { in: createdGroupIds } },
    });
  }
  if (createdUserIds.length > 0) {
    await prisma.knowledgeRetrievalLog.deleteMany({
      where: { userId: { in: createdUserIds } },
    });
    await prisma.knowledgeDocument.deleteMany({
      where: { authorId: { in: createdUserIds } },
    });
    await prisma.user.deleteMany({
      where: { id: { in: createdUserIds } },
    });
  }
};

describe('Integration: Phase 3 Intelligent Exam Generator (Balanced Multi-Course, RAG & Answer-Key Isolation)', () => {
  const emailService = new ConsoleEmailAdapter();
  const capturedExamPrompts: string[] = [];
  const env = getEnv();

  const topicVector = (text: string): number[] => {
    const vec = new Array<number>(768).fill(0);
    const lower = text.toLowerCase();
    vec[0] =
      lower.includes('graphe') || lower.includes('dijkstra') || lower.includes('bellman')
        ? 0.92
        : 0.05;
    vec[1] =
      lower.includes('dynamique') || lower.includes('memoisation') || lower.includes('knapsack')
        ? 0.92
        : 0.05;
    vec[2] =
      lower.includes('retropropagation') || lower.includes('gradient') || lower.includes('seance')
        ? 0.92
        : 0.05;
    vec[3] = lower.includes('brouillon') || lower.includes('draft') ? 0.5 : 0.05;
    const norm = Math.sqrt(vec.reduce((sum, val) => sum + val * val, 0)) || 1;
    return vec.map((val) => val / norm);
  };

  const fakeEmbedding: KnowledgeEmbeddingPort = {
    embedOne: async (text) => topicVector(text),
    embedBatch: async (texts) => texts.map((text) => topicVector(text)),
    checkHealth: async () => ({
      available: true,
      model: 'embeddinggemma-2:270m',
      numGpu: 0,
      dimension: 768,
      latencyMs: 10,
      runtime: 'cpu',
    }),
  };

  const spyExamGateway: AiGatewayPort = {
    chatCompletion: async () => {
      throw new Error('chatCompletion not used by exam generator');
    },
    streamCompletion: async (input, onDelta) => {
      capturedExamPrompts.push(input.user);
      const json = JSON.stringify({
        title: 'Partiel Algorithmique & Deep Learning',
        description: 'Sujet équilibré généré à partir des ressources sélectionnées.',
        questions: [
          {
            prompt: 'Quelle structure utilise l’algorithme de Dijkstra ?',
            hint: 'File de priorité',
            options: [
              'Une file de priorité (tas binaire)',
              'Une pile LIFO simple',
              'Un arbre B+',
              'Une matrice creuse sans tri',
            ],
            correctOptionId: 'A',
            explanation: 'Dijkstra extrait le sommet de distance minimale via une file de priorité.',
            points: 2,
          },
          {
            prompt: 'Quel principe caractérise la programmation dynamique ?',
            options: [
              'Diviser sans chevauchement',
              'Sous-problèmes chevauchants avec mémoïsation',
              'Recherche purement aléatoire',
              'Tri topologique strict',
            ],
            correctOptionId: 'B',
            explanation: 'La programmation dynamique stocke les résultats des sous-problèmes.',
            points: 2,
          },
        ],
      });
      const mid = Math.ceil(json.length / 2);
      onDelta(json.slice(0, mid));
      onDelta(json.slice(mid));
      return { promptTokens: 120, completionTokens: 90, model: env.AI_MODEL };
    },
    checkHealth: async () => ({ available: true, model: env.AI_MODEL, latencyMs: 5 }),
  };

  const app = createApp({
    skipLogging: true,
    skipRateLimit: true,
    authModuleOptions: { emailService },
    knowledgeModuleOptions: { embedding: fakeEmbedding },
    examsModuleOptions: {
      aiGateway: spyExamGateway,
      aiModelCatalog: {
        listInstalledModels: async () => [env.AI_MODEL],
      },
    },
  });

  const stamp = Date.now();
  const password = 'StrongPassword123!';

  const createVerifiedUser = async (
    rawEmail: string,
    role: 'TEACHER' | 'STUDENT',
  ): Promise<{ token: string; userId: string }> => {
    const email = rawEmail.toLowerCase();
    const reg = await request(app).post('/api/v1/auth/register').send({
      email,
      password,
      firstName: role,
      lastName: 'ExamRag',
      role,
    });
    expect(reg.status).toBe(201);
    const sent = emailService.getSentEmails();
    const ver = await request(app)
      .post('/api/v1/auth/verify-email')
      .send({ email, code: sent[sent.length - 1]?.code ?? '' });
    expect(ver.status).toBe(200);
    if (role === 'TEACHER') {
      await prisma.user.update({
        where: { email },
        data: { teacherApprovalStatus: 'APPROVED' },
      });
    }
    const login = await request(app).post('/api/v1/auth/login').send({ email, password });
    expect(login.status).toBe(200);
    const userId = login.body.data.user.id as string;
    createdUserIds.push(userId);
    return { token: login.body.data.accessToken as string, userId };
  };

  const seedLectureDocument = async (params: {
    authorId: string;
    title: string;
    sectionTitle: string;
    content: string;
    trustTier: 'VERIFIED' | 'DRAFT_AI';
    visibility: 'PRIVATE_AUTHOR' | 'CLASS_PUBLISHED';
    classGroupIds?: string[];
    startSeconds?: number | null;
    slideNumber?: number | null;
  }): Promise<string> => {
    const docId = randomUUID();
    const sourceId = `rec-${randomUUID()}`;
    const vecLiteral = `[${topicVector(`${params.title} ${params.content}`).join(',')}]`;
    const docHash = computeSha256(`${params.title}:${params.content}:${docId}`);
    createdDocIds.push(docId);

    await prisma.knowledgeDocument.create({
      data: {
        id: docId,
        sourceType: 'LECTURE_PACKAGE',
        sourceId,
        authorId: params.authorId,
        title: params.title,
        subject: 'Informatique',
        language: 'fr',
        visibility: params.visibility,
        trustTier: params.trustTier,
        classGroupIds: params.classGroupIds ?? [],
        contentHash: docHash,
        indexStatus: 'INDEXED',
        embeddingModel: 'embeddinggemma-2:270m',
        embeddingDims: 768,
        chunkCount: 1,
        indexedAt: new Date(),
        metadata: {},
      },
    });

    await pool.query(
      `INSERT INTO knowledge_chunks (
         id, document_id, chunk_index, section_title, heading_path,
         content, context_header, token_estimate, start_seconds, end_seconds,
         source_page, slide_number, content_hash, embedding, metadata,
         created_at, updated_at
       ) VALUES (
         $1::uuid, $2::uuid, 0, $3, $3,
         $4, $5, 60, $6, $7,
         NULL, $8, $9, $10::vector, '{}'::jsonb,
         NOW(), NOW()
       )`,
      [
        randomUUID(),
        docId,
        params.sectionTitle,
        params.content,
        params.title,
        params.startSeconds ?? null,
        params.startSeconds !== undefined && params.startSeconds !== null
          ? params.startSeconds + 45
          : null,
        params.slideNumber ?? null,
        computeSha256(params.content),
        vecLiteral,
      ],
    );

    return docId;
  };

  afterAll(async () => {
    await cleanUp();
  });

  it('generates balanced multi-course & recorded-lecture exams, enforces draft opt-in & teacher isolation, and never exposes exam answer keys', async () => {
    const teacherA = await createVerifiedUser(`ex_tA_${stamp}@test.com`, 'TEACHER');
    const teacherB = await createVerifiedUser(`ex_tB_${stamp}@test.com`, 'TEACHER');
    const student = await createVerifiedUser(`ex_s1_${stamp}@test.com`, 'STUDENT');

    const classId = randomUUID();
    createdGroupIds.push(classId);
    await prisma.classGroup.create({
      data: {
        id: classId,
        name: `L3 IA ${stamp}`,
        level: 'LICENCE',
        academicYear: '2026-2027',
        status: 'PUBLISHED',
        capacity: 40,
        ownerId: teacherA.userId,
        referentId: teacherA.userId,
      },
    });
    await prisma.groupMember.create({
      data: { classGroupId: classId, userId: student.userId },
    });

    // Huge Course 1 (exceeds AI_MAX_SOURCE_CHARS alone so a greedy slicer would starve Course 2)
    const hugeFiller =
      'L’algorithme de Dijkstra résout le problème du plus court chemin à poids positifs sur un graphe orienté. '.repeat(
        260,
      );
    const quizSecretMarker = 'QUIZ_SELF_CHECK_CORRECTION_SECRET_4412';
    const c1Res = await request(app)
      .post('/api/v1/courses')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({
        title: 'Théorie des Graphes Avancée',
        subject: 'Informatique',
        classGroupIds: [classId],
        level: 'detaille',
        difficulty: 'moyen',
        format: 'resume',
        content: [
          '## Chapitre 1 : Dijkstra',
          hugeFiller,
          '## Chapitre 2 : Bellman-Ford',
          'Bellman-Ford détecte les cycles absorbants de poids négatif en O(V * E).',
          '## Correction du quiz',
          `Réponse Q1 : ${quizSecretMarker}`,
        ].join('\n\n'),
      });
    expect(c1Res.status).toBe(201);
    const course1Id = c1Res.body.data.id as string;
    createdCourseIds.push(course1Id);
    const pub1 = await request(app)
      .patch(`/api/v1/courses/${course1Id}/publish`)
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({});
    expect(pub1.status).toBe(200);

    // Short Course 2 (would be completely starved by sequential slicing)
    const course2Marker = 'KNAPSACK_MEMOIZATION_UNIQUE_MARKER_7720';
    const c2Res = await request(app)
      .post('/api/v1/courses')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({
        title: 'Programmation Dynamique',
        subject: 'Informatique',
        classGroupIds: [classId],
        level: 'concis',
        difficulty: 'moyen',
        format: 'resume',
        content: `## Chapitre 1 : Sac à dos\nLa mémoïsation résout le sac à dos (${course2Marker}) en temps pseudo-polynomial.`,
      });
    expect(c2Res.status).toBe(201);
    const course2Id = c2Res.body.data.id as string;
    createdCourseIds.push(course2Id);
    const pub2 = await request(app)
      .patch(`/api/v1/courses/${course2Id}/publish`)
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({});
    expect(pub2.status).toBe(200);

    // Index courses explicitly via Knowledge API
    const reindexRes = await request(app)
      .post('/api/v1/knowledge/reindex')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({ sourceTypes: ['COURSE'], force: true });
    expect(reindexRes.status).toBe(200);

    // Seed verified recorded lecture + draft lecture for Teacher A + private doc for Teacher B
    const verifiedLectureId = await seedLectureDocument({
      authorId: teacherA.userId,
      title: 'Séance 5 : Rétropropagation du gradient',
      sectionTitle: 'Dérivation en chaîne',
      content:
        'La rétropropagation applique la règle de dérivation en chaîne pour calculer le gradient dans chaque couche.',
      trustTier: 'VERIFIED',
      visibility: 'PRIVATE_AUTHOR',
      startSeconds: 185,
      slideNumber: 4,
    });

    const draftLectureId = await seedLectureDocument({
      authorId: teacherA.userId,
      title: 'Séance Brouillon Non Validée',
      sectionTitle: 'Brouillon Transformers',
      content: 'BROUILLON_UNVALIDATED_ATTENTION_MARKER sur l’attention multi-têtes.',
      trustTier: 'DRAFT_AI',
      visibility: 'PRIVATE_AUTHOR',
      startSeconds: 60,
    });

    const foreignDocId = await seedLectureDocument({
      authorId: teacherB.userId,
      title: 'Document Privé Enseignant B',
      sectionTitle: 'Privé',
      content: 'FOREIGN_TEACHER_PRIVATE_LEAK_MARKER ne doit jamais être accessible.',
      trustTier: 'VERIFIED',
      visibility: 'PRIVATE_AUTHOR',
    });

    // 1. Course picker exposes Markdown teaching chapters while excluding Correction du quiz
    const coursesRes = await request(app)
      .get(`/api/v1/exams/classes/${classId}/courses`)
      .set({ Authorization: `Bearer ${teacherA.token}` });
    expect(coursesRes.status).toBe(200);
    const course1Option = (
      coursesRes.body.data as Array<{ id: string; chapters?: string[] }>
    ).find((c) => c.id === course1Id);
    expect(course1Option?.chapters).toEqual([
      'Chapitre 1 : Dijkstra',
      'Chapitre 2 : Bellman-Ford',
    ]);

    // 2. Balanced multi-course + verified lecture exam generation
    capturedExamPrompts.length = 0;
    const genRes = await request(app)
      .post('/api/v1/exams/ai/generate')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({
        classGroupId: classId,
        courseIds: [course1Id, course2Id],
        knowledgeDocumentIds: [verifiedLectureId],
        focusTopics: ['Dijkstra', 'mémoïsation', 'rétropropagation'],
        questionCount: 6,
        difficulty: 'moyen',
      });

    expect(genRes.status).toBe(200);
    const preview = genRes.body.data;
    expect(preview.knowledgeSearchMode).toBe('HYBRID');
    expect(preview.coverage.coveredSources).toBe(3);
    expect(preview.coverage.truncated).toBe(true);
    expect(preview.coverage.warnings.length).toBeGreaterThan(0);

    const promptSent = capturedExamPrompts[0] ?? '';
    expect(promptSent).toContain('Dijkstra');
    expect(promptSent).toContain(course2Marker);
    expect(promptSent).toContain('rétropropagation'.toLowerCase().slice(0, 12));
    expect(promptSent).not.toContain(quizSecretMarker);

    const lectureAttribution = (
      preview.knowledgeSources as Array<{
        documentId: string | null;
        startSeconds: number | null;
        slideNumber: number | null;
      }>
    ).find((s) => s.documentId === verifiedLectureId);
    expect(lectureAttribution).toBeDefined();
    expect(lectureAttribution?.startSeconds).toBe(185);
    expect(lectureAttribution?.slideNumber).toBe(4);

    // 3. Default includeDrafts=false rejects draft-only pin; includeDrafts=true allows own draft;
    //    Teacher B's private doc is strictly rejected even with includeDrafts=true.
    const draftBlockedRes = await request(app)
      .post('/api/v1/exams/ai/generate')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({
        classGroupId: classId,
        knowledgeDocumentIds: [draftLectureId],
        questionCount: 2,
      });
    expect(draftBlockedRes.status).toBe(422);

    const draftAllowedRes = await request(app)
      .post('/api/v1/exams/ai/generate')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({
        classGroupId: classId,
        knowledgeDocumentIds: [draftLectureId],
        includeDrafts: true,
        questionCount: 2,
      });
    expect(draftAllowedRes.status).toBe(200);
    expect(
      (draftAllowedRes.body.data.knowledgeSources as Array<{ trustTier: string }>)[0]?.trustTier,
    ).toBe('DRAFT_AI');

    const crossTeacherBlocked = await request(app)
      .post('/api/v1/exams/ai/generate')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({
        classGroupId: classId,
        knowledgeDocumentIds: [foreignDocId],
        includeDrafts: true,
        questionCount: 2,
      });
    expect(crossTeacherBlocked.status).toBe(422);
    expect(capturedExamPrompts.join('\n')).not.toContain('FOREIGN_TEACHER_PRIVATE_LEAK_MARKER');

    // 4. Security check: Published exam questions & answer keys NEVER appear in Knowledge retrieval
    //    and NEVER appear in student exam attempt payloads.
    const secretCanary = `ExamCanaryToken${stamp}Z9`;
    const now = Date.now();
    const createExamRes = await request(app)
      .post('/api/v1/exams')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({
        title: `Examen Sécurisé ${stamp}`,
        description: 'Ne doit jamais apparaître dans le RAG.',
        classGroupId: classId,
        durationMinutes: 45,
        startsAt: new Date(now - 60_000).toISOString(),
        endsAt: new Date(now + 3_600_000).toISOString(),
        source: 'AI',
        questions: [
          {
            prompt: `Question confidentielle (${secretCanary}) ?`,
            options: ['Mauvaise réponse', `Bonne réponse ${secretCanary}`, 'Distracteur C', 'Distracteur D'],
            correctOptionId: 'B',
            explanation: `Explication secrète du corrigé : ${secretCanary}`,
            points: 2,
          },
        ],
      });
    expect(createExamRes.status).toBe(201);
    const examId = createExamRes.body.data.id as string;
    createdExamIds.push(examId);

    const publishExamRes = await request(app)
      .patch(`/api/v1/exams/${examId}/publish`)
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({});
    expect(publishExamRes.status).toBe(200);

    const studentFtsCanary = await request(app)
      .post('/api/v1/knowledge/search')
      .set({ Authorization: `Bearer ${student.token}` })
      .send({ query: secretCanary, preferredMode: 'FTS_ONLY' });
    expect(studentFtsCanary.status).toBe(200);
    expect(studentFtsCanary.body.data.hits).toHaveLength(0);

    const teacherFtsCanary = await request(app)
      .post('/api/v1/knowledge/search')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({ query: secretCanary, preferredMode: 'FTS_ONLY' });
    expect(teacherFtsCanary.status).toBe(200);
    expect(teacherFtsCanary.body.data.hits).toHaveLength(0);

    const studentRagSearch = await request(app)
      .post('/api/v1/knowledge/search')
      .set({ Authorization: `Bearer ${student.token}` })
      .send({ query: secretCanary });
    expect(studentRagSearch.status).toBe(200);
    expect(JSON.stringify(studentRagSearch.body.data.hits)).not.toContain(secretCanary);

    const teacherRagSearch = await request(app)
      .post('/api/v1/knowledge/search')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({ query: secretCanary });
    expect(teacherRagSearch.status).toBe(200);
    expect(JSON.stringify(teacherRagSearch.body.data.hits)).not.toContain(secretCanary);

    const indexedExamCount = await prisma.knowledgeDocument.count({
      where: { sourceId: examId },
    });
    expect(indexedExamCount).toBe(0);

    const startRes = await request(app)
      .post(`/api/v1/exams/${examId}/start`)
      .set({ Authorization: `Bearer ${student.token}` })
      .send({});
    expect(startRes.status).toBe(200);
    const studentQuestions = startRes.body.data.exam.questions as Array<Record<string, unknown>>;
    expect(studentQuestions).toHaveLength(1);
    expect(studentQuestions[0]).not.toHaveProperty('correctOptionIds');
    expect(studentQuestions[0]).not.toHaveProperty('explanation');
  });
});

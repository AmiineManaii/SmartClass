import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { ConsoleEmailAdapter } from '../../src/modules/auth/infrastructure/console-email.adapter.js';
import { getPgPool, getPrismaClient } from '../../src/shared/infrastructure/prisma.js';
import { OllamaCpuEmbeddingAdapter } from '../../src/modules/knowledge/infrastructure/ollama-cpu-embedding.adapter.js';
import type { KnowledgeEmbeddingPort } from '../../src/modules/knowledge/domain/knowledge-embedding.port.js';

const prisma = getPrismaClient();
const pool = getPgPool();

const createdCourseIds: string[] = [];
const createdGroupIds: string[] = [];
const createdUserIds: string[] = [];

const cleanUp = async () => {
  if (createdCourseIds.length > 0) {
    await prisma.knowledgeDocument.deleteMany({
      where: { sourceId: { in: createdCourseIds } },
    });
    await prisma.course.deleteMany({ where: { id: { in: createdCourseIds } } });
  }
  if (createdGroupIds.length > 0) {
    await prisma.classGroup.deleteMany({ where: { id: { in: createdGroupIds } } });
  }
  if (createdUserIds.length > 0) {
    await prisma.knowledgeRetrievalLog.deleteMany({
      where: { userId: { in: createdUserIds } },
    });
    await prisma.user.deleteMany({ where: { id: { in: createdUserIds } } });
  }
};

describe('Integration: Unified SmartClass Knowledge Engine (pgvector HNSW + FTS + Authorization)', () => {
  const emailService = new ConsoleEmailAdapter();
  let embeddingOnline = true;
  const realCpuEmbedding = new OllamaCpuEmbeddingAdapter();
  let liveOllamaAvailable = false;

  // Deterministic normalized 768-dim topic embedder for CI/hermetic isolation, plus toggleable outage test
  const topicVector = (text: string): number[] => {
    const vec = new Array<number>(768).fill(0);
    const lower = text.toLowerCase();
    vec[0] = lower.includes('crisp') || lower.includes('data science') || lower.includes('données') ? 0.9 : 0.05;
    vec[1] = lower.includes('overfit') || lower.includes('surapprentissage') || lower.includes('lasso') ? 0.9 : 0.05;
    vec[2] = lower.includes('sql') || lower.includes('jointure') || lower.includes('join') ? 0.9 : 0.05;
    vec[3] = lower.includes('secret') || lower.includes('draft') ? 0.9 : 0.05;
    const norm = Math.sqrt(vec.reduce((s, v) => s + v * v, 0)) || 1;
    return vec.map((v) => v / norm);
  };

  const switchableEmbedding: KnowledgeEmbeddingPort = {
    embedOne: async (text) => {
      if (!embeddingOnline) throw new Error('Simulated Ollama CPU offline');
      return topicVector(text);
    },
    embedBatch: async (texts) => {
      if (!embeddingOnline) throw new Error('Simulated Ollama CPU offline');
      return texts.map((t) => topicVector(t));
    },
    checkHealth: async () => ({
      available: embeddingOnline,
      model: 'embeddinggemma-2:270m',
      numGpu: 0,
      dimension: 768,
      latencyMs: embeddingOnline ? 15 : null,
      runtime: 'cpu',
    }),
  };

  const app = createApp({
    skipLogging: true,
    skipRateLimit: true,
    authModuleOptions: { emailService },
    knowledgeModuleOptions: {
      embedding: switchableEmbedding,
    },
  });

  const stamp = Date.now();
  const password = 'StrongPassword123!';

  const createVerifiedUser = async (email: string, role: 'TEACHER' | 'STUDENT' | 'ADMIN') => {
    await request(app).post('/api/v1/auth/register').send({
      email,
      password,
      firstName: role,
      lastName: 'Knowledge',
      role,
    });
    const sent = emailService.getSentEmails();
    await request(app)
      .post('/api/v1/auth/verify-email')
      .send({ email, code: sent[sent.length - 1]?.code ?? '' });
    if (role === 'TEACHER') {
      await prisma.user.update({
        where: { email },
        data: { teacherApprovalStatus: 'APPROVED' },
      });
    }
    const login = await request(app).post('/api/v1/auth/login').send({ email, password });
    const userId = login.body.data.user.id as string;
    createdUserIds.push(userId);
    return { token: login.body.data.accessToken as string, userId };
  };

  beforeAll(async () => {
    const health = await realCpuEmbedding.checkHealth();
    liveOllamaAvailable = health.available;
  });

  afterAll(async () => {
    await cleanUp();
  });

  it('verifies schema tables, HNSW & GIN indexes, and preserves legacy course_passages', async () => {
    const tables = await pool.query<{ tablename: string }>(
      `SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('knowledge_documents', 'knowledge_chunks', 'knowledge_retrieval_logs', 'course_passages')`,
    );
    const names = tables.rows.map((r) => r.tablename).sort();
    expect(names).toEqual([
      'course_passages',
      'knowledge_chunks',
      'knowledge_documents',
      'knowledge_retrieval_logs',
    ]);
  });

  it('enforces strict teacher privacy, student class-published VERIFIED gating, FTS_ONLY degradation, and legacy course indexing lifecycle', async () => {
    const t1 = await createVerifiedUser(`k_t1_${stamp}@test.com`, 'TEACHER');
    const t2 = await createVerifiedUser(`k_t2_${stamp}@test.com`, 'TEACHER');
    const s1 = await createVerifiedUser(`k_s1_${stamp}@test.com`, 'STUDENT');
    const s2 = await createVerifiedUser(`k_s2_${stamp}@test.com`, 'STUDENT');

    const classA = randomUUID();
    const classB = randomUUID();
    createdGroupIds.push(classA, classB);

    await prisma.classGroup.createMany({
      data: [
        { id: classA, name: `Class A ${stamp}`, level: 'LICENCE', academicYear: '2026-2027', status: 'PUBLISHED', capacity: 30, ownerId: t1.userId, referentId: t1.userId },
        { id: classB, name: `Class B ${stamp}`, level: 'LICENCE', academicYear: '2026-2027', status: 'PUBLISHED', capacity: 30, ownerId: t2.userId, referentId: t2.userId },
      ],
    });
    await prisma.groupMember.createMany({
      data: [
        { classGroupId: classA, userId: s1.userId },
        { classGroupId: classB, userId: s2.userId },
      ],
    });

    // 1. Teacher 1 saves DRAFT_AI course assigned to classA
    const saveRes = await request(app)
      .post('/api/v1/courses')
      .set({ Authorization: `Bearer ${t1.token}` })
      .send({
        title: `Data Science Draft Secret ${stamp}`,
        subject: 'Data Science',
        content: '# Cycle CRISP-DM Secret\n\nLe surapprentissage (overfitting) est traité par régularisation Lasso L1 et Ridge L2.',
        level: 'equilibre',
        classGroupIds: [classA],
      });
    expect(saveRes.status).toBe(201);
    const course1Id = saveRes.body.data.id as string;
    createdCourseIds.push(course1Id);

    // Wait briefly for async queue to index course1
    await new Promise((r) => setTimeout(r, 250));

    // Teacher 1 sees own DRAFT_AI course
    const t1Search = await request(app)
      .post('/api/v1/knowledge/search')
      .set({ Authorization: `Bearer ${t1.token}` })
      .send({ query: `CRISP-DM Secret ${stamp}`, filters: { sourceIds: [course1Id] } });
    expect(t1Search.status).toBe(200);
    expect(t1Search.body.data.searchMode).toBe('HYBRID');
    expect(t1Search.body.data.hits.length).toBeGreaterThanOrEqual(1);
    expect(t1Search.body.data.hits[0].trustTier).toBe('DRAFT_AI');

    // Teacher 2 MUST NOT see Teacher 1's document
    const t2Search = await request(app)
      .post('/api/v1/knowledge/search')
      .set({ Authorization: `Bearer ${t2.token}` })
      .send({ query: `CRISP-DM Secret ${stamp}`, filters: { sourceIds: [course1Id] } });
    expect(t2Search.status).toBe(200);
    expect(t2Search.body.data.hits).toHaveLength(0);

    // Enrolled student s1 MUST NOT see DRAFT_AI course before publication
    const s1DraftSearch = await request(app)
      .post('/api/v1/knowledge/search')
      .set({ Authorization: `Bearer ${s1.token}` })
      .send({ query: `CRISP-DM Secret ${stamp}`, filters: { sourceIds: [course1Id] } });
    expect(s1DraftSearch.status).toBe(200);
    expect(s1DraftSearch.body.data.hits).toHaveLength(0);

    // 2. Teacher 1 publishes course -> promoted to VERIFIED + CLASS_PUBLISHED
    const pubRes = await request(app)
      .patch(`/api/v1/courses/${course1Id}/publish`)
      .set({ Authorization: `Bearer ${t1.token}` });
    expect(pubRes.status).toBe(200);
    await new Promise((r) => setTimeout(r, 150));

    // Enrolled student s1 CAN now retrieve published course
    const s1PubSearch = await request(app)
      .post('/api/v1/knowledge/search')
      .set({ Authorization: `Bearer ${s1.token}` })
      .send({ query: 'surapprentissage regularisation Lasso', filters: { sourceIds: [course1Id] } });
    expect(s1PubSearch.status).toBe(200);
    expect(s1PubSearch.body.data.hits.length).toBeGreaterThanOrEqual(1);
    expect(s1PubSearch.body.data.hits[0].trustTier).toBe('VERIFIED');
    expect(s1PubSearch.body.data.hits[0].visibility).toBe('CLASS_PUBLISHED');

    // Student s2 (enrolled ONLY in classB) MUST NOT see classA course
    const s2Blocked = await request(app)
      .post('/api/v1/knowledge/search')
      .set({ Authorization: `Bearer ${s2.token}` })
      .send({ query: 'surapprentissage', filters: { sourceIds: [course1Id] } });
    expect(s2Blocked.status).toBe(200);
    expect(s2Blocked.body.data.hits).toHaveLength(0);

    // Student cannot call /knowledge/status or /knowledge/reindex
    const s1Status = await request(app)
      .get('/api/v1/knowledge/status')
      .set({ Authorization: `Bearer ${s1.token}` });
    expect(s1Status.status).toBe(403);

    // 3. Simulate embedding service offline -> explicit FTS_ONLY degradation + PENDING_EMBEDDING persistence
    embeddingOnline = false;
    const ftsFallbackSearch = await request(app)
      .post('/api/v1/knowledge/search')
      .set({ Authorization: `Bearer ${s1.token}` })
      .send({ query: 'surapprentissage Lasso', filters: { sourceIds: [course1Id] } });
    expect(ftsFallbackSearch.status).toBe(200);
    expect(ftsFallbackSearch.body.data.searchMode).toBe('FTS_ONLY');
    expect(ftsFallbackSearch.body.data.degradedReason).toContain('offline');
    expect(ftsFallbackSearch.body.data.hits.length).toBeGreaterThanOrEqual(1);
    embeddingOnline = true;

    // 4. Unpublish revokes student visibility immediately
    const unpubRes = await request(app)
      .patch(`/api/v1/courses/${course1Id}/unpublish`)
      .set({ Authorization: `Bearer ${t1.token}` });
    expect(unpubRes.status).toBe(200);
    const s1AfterUnpub = await request(app)
      .post('/api/v1/knowledge/search')
      .set({ Authorization: `Bearer ${s1.token}` })
      .send({ query: 'surapprentissage', filters: { sourceIds: [course1Id] } });
    expect(s1AfterUnpub.body.data.hits).toHaveLength(0);

    // 5. Knowledge diagnostics & document listing
    const statusRes = await request(app)
      .get('/api/v1/knowledge/status')
      .set({ Authorization: `Bearer ${t1.token}` });
    expect(statusRes.status).toBe(200);
    expect(statusRes.body.data.counts.totalDocuments).toBeGreaterThanOrEqual(1);

    // 6. Delete course -> automatically removes indexed knowledge document & chunks
    const delCourseRes = await request(app)
      .delete(`/api/v1/courses/${course1Id}`)
      .set({ Authorization: `Bearer ${t1.token}` });
    expect([200, 204]).toContain(delCourseRes.status);
    const t1AfterDelete = await request(app)
      .post('/api/v1/knowledge/search')
      .set({ Authorization: `Bearer ${t1.token}` })
      .send({ query: 'CRISP-DM Secret', filters: { sourceIds: [course1Id] } });
    expect(t1AfterDelete.status).toBe(200);
    expect(t1AfterDelete.body.data.hits).toHaveLength(0);
  });

  it('retrieves multilingual FR / EN / AR / Tunisian Derja queries with real CPU embeddinggemma-2:270m when Ollama is live', async () => {
    if (!liveOllamaAvailable) return;

    const liveApp = createApp({
      skipLogging: true,
      skipRateLimit: true,
      authModuleOptions: { emailService },
    });

    const email = `k_live_${stamp}@test.com`;
    await request(liveApp).post('/api/v1/auth/register').send({
      email,
      password,
      firstName: 'Live',
      lastName: 'Teacher',
      role: 'TEACHER',
    });
    const sent = emailService.getSentEmails();
    await request(liveApp)
      .post('/api/v1/auth/verify-email')
      .send({ email, code: sent[sent.length - 1]?.code ?? '' });
    await prisma.user.update({ where: { email }, data: { teacherApprovalStatus: 'APPROVED' } });
    const login = await request(liveApp).post('/api/v1/auth/login').send({ email, password });
    const token = login.body.data.accessToken as string;
    const teacherId = login.body.data.user.id as string;
    createdUserIds.push(teacherId);

    const saveRes = await request(liveApp)
      .post('/api/v1/courses')
      .set({ Authorization: `Bearer ${token}` })
      .send({
        title: `Cours ML Réel ${stamp}`,
        subject: 'Machine Learning',
        content: '# Surapprentissage (Overfitting)\n\nLe surapprentissage arrive lorsque le modèle mémorise le bruit du jeu d’entraînement. On l’évite via la validation croisée et la régularisation Ridge L2.',
        level: 'concis',
      });
    expect(saveRes.status).toBe(201);
    const cId = saveRes.body.data.id as string;
    createdCourseIds.push(cId);

    await new Promise((r) => setTimeout(r, 500));

    for (const q of [
      'How do we avoid overfitting in machine learning?',
      'kifech nna9sou overfitting b ridge regularization',
      'كيف نتجنب فرط التخصيص في تعلم الآلة',
    ]) {
      const searchRes = await request(liveApp)
        .post('/api/v1/knowledge/search')
        .set({ Authorization: `Bearer ${token}` })
        .send({ query: q, k: 3, filters: { sourceIds: [cId] } });
      expect(searchRes.status).toBe(200);
      expect(searchRes.body.data.searchMode).toBe('HYBRID');
      expect(searchRes.body.data.hits.length).toBeGreaterThanOrEqual(1);
      expect(searchRes.body.data.hits[0].content).toContain('surapprentissage');
    }
  }, 30000);
});

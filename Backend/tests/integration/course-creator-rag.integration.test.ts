import { afterAll, describe, expect, it } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import type { AiGatewayPort } from '../../src/modules/ai-assistant/domain/ai-gateway.port.js';
import { ConsoleEmailAdapter } from '../../src/modules/auth/infrastructure/console-email.adapter.js';
import type { KnowledgeEmbeddingPort } from '../../src/modules/knowledge/domain/knowledge-embedding.port.js';
import { getPrismaClient } from '../../src/shared/infrastructure/prisma.js';

const prisma = getPrismaClient();

const createdCourseIds: string[] = [];
const createdUserIds: string[] = [];

const cleanUp = async (): Promise<void> => {
  if (createdCourseIds.length > 0) {
    await prisma.knowledgeDocument.deleteMany({
      where: { sourceId: { in: createdCourseIds } },
    });
    await prisma.course.deleteMany({
      where: { id: { in: createdCourseIds } },
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

describe('Integration: Phase 2 Intelligent Course Creator (RAG grounding, isolation, attribution)', () => {
  const emailService = new ConsoleEmailAdapter();
  const capturedPrompts: string[] = [];

  const topicVector = (text: string): number[] => {
    const vec = new Array<number>(768).fill(0);
    const lower = text.toLowerCase();
    vec[0] =
      lower.includes('graphe') || lower.includes('dijkstra') || lower.includes('bfs')
        ? 0.95
        : 0.05;
    vec[1] = lower.includes('brouillon') || lower.includes('draft') ? 0.35 : 0.05;
    const norm = Math.sqrt(vec.reduce((sum, v) => sum + v * v, 0)) || 1;
    return vec.map((v) => v / norm);
  };

  const fakeEmbedding: KnowledgeEmbeddingPort = {
    embedOne: async (text) => topicVector(text),
    embedBatch: async (texts) => texts.map((text) => topicVector(text)),
    checkHealth: async () => ({
      available: true,
      model: 'embeddinggemma-2:270m',
      numGpu: 0,
      dimension: 768,
      latencyMs: 12,
      runtime: 'cpu',
    }),
  };

  const spyGateway: AiGatewayPort = {
    chatCompletion: async (input) => {
      capturedPrompts.push(input.user);
      if (input.system.includes('format JSON pur') || input.user.includes('format JSON pur')) {
        return {
          content: JSON.stringify({
            title: 'Algorithmes sur les Graphes',
            targetAudience: 'Licence 3',
            prerequisites: ['Structures de données'],
            sections: [
              {
                id: 'sec-1',
                title: 'Parcours BFS et DFS',
                description: 'Fondamentaux des graphes',
                keyTopics: ['BFS', 'DFS'],
                estimatedMinutes: 20,
              },
            ],
          }),
          promptTokens: 30,
          completionTokens: 45,
          model: 'gemma4:e4b',
          toolsUsed: false,
        };
      }
      return {
        content: '# Algorithmes sur les Graphes\n\nContenu généré.',
        promptTokens: 35,
        completionTokens: 55,
        model: 'gemma4:e4b',
        toolsUsed: false,
      };
    },
    streamCompletion: async (input, onDelta) => {
      capturedPrompts.push(input.user);
      onDelta('# Algorithmes sur les Graphes\n\n');
      onDelta('Plus court chemin avec Dijkstra.');
      return { promptTokens: 40, completionTokens: 60, model: 'gemma4:e4b' };
    },
    checkHealth: async () => ({ available: true, model: 'gemma4:e4b', latencyMs: 8 }),
  };

  const app = createApp({
    skipLogging: true,
    skipRateLimit: true,
    authModuleOptions: { emailService },
    knowledgeModuleOptions: { embedding: fakeEmbedding },
    aiModuleOptions: { gateway: spyGateway },
  });

  const stamp = Date.now();
  const password = 'StrongPassword123!';

  const createTeacher = async (rawEmail: string) => {
    const email = rawEmail.toLowerCase();
    const reg = await request(app).post('/api/v1/auth/register').send({
      email,
      password,
      firstName: 'Teacher',
      lastName: 'Rag',
      role: 'TEACHER',
    });
    expect(reg.status).toBe(201);
    const sent = emailService.getSentEmails();
    const ver = await request(app)
      .post('/api/v1/auth/verify-email')
      .send({ email, code: sent[sent.length - 1]?.code ?? '' });
    expect(ver.status).toBe(200);
    await prisma.user.update({
      where: { email },
      data: { teacherApprovalStatus: 'APPROVED' },
    });
    const login = await request(app).post('/api/v1/auth/login').send({ email, password });
    expect(login.status).toBe(200);
    const userId = login.body.data.user.id as string;
    createdUserIds.push(userId);
    return { token: login.body.data.accessToken as string, userId };
  };

  const createCourseAndIndex = async (
    token: string,
    payload: { title: string; subject: string; content: string; publish: boolean },
  ): Promise<string> => {
    const res = await request(app)
      .post('/api/v1/courses')
      .set({ Authorization: `Bearer ${token}` })
      .send({
        title: payload.title,
        subject: payload.subject,
        content: payload.content,
        level: 'equilibre',
        difficulty: 'moyen',
        format: 'resume',
      });
    expect(res.status).toBe(201);
    const courseId = res.body.data.id as string;
    createdCourseIds.push(courseId);

    if (payload.publish) {
      const pub = await request(app)
        .patch(`/api/v1/courses/${courseId}/publish`)
        .set({ Authorization: `Bearer ${token}` })
        .send({});
      expect(pub.status).toBe(200);
    }

    const reindex = await request(app)
      .post('/api/v1/knowledge/reindex')
      .set({ Authorization: `Bearer ${token}` })
      .send({ sourceTypes: ['COURSE'], force: true });
    expect(reindex.status).toBe(200);

    return courseId;
  };

  afterAll(async () => {
    await cleanUp();
  });

  it('grounds only VERIFIED private teacher docs by default, respects opt-in drafts, isolates cross-teacher docs, and emits SSE metadata', async () => {
    const teacherA = await createTeacher(`teacherA_p2_${stamp}@test.com`);
    const teacherB = await createTeacher(`teacherB_p2_${stamp}@test.com`);

    await createCourseAndIndex(teacherA.token, {
      title: 'Graphes Validés A',
      subject: 'Algorithmique des graphes',
      content:
        '# Graphes Validés A\n\n## Dijkstra et BFS\nL algorithme de Dijkstra résout les plus courts chemins à poids positifs.',
      publish: true,
    });

    await createCourseAndIndex(teacherA.token, {
      title: 'Graphes Brouillon A',
      subject: 'Algorithmique des graphes',
      content:
        '# Graphes Brouillon A\n\n## Note brouillon secrète\nCe brouillon non validé mentionne les graphes pondérés.',
      publish: false,
    });

    await createCourseAndIndex(teacherB.token, {
      title: 'Graphes Privés Enseignant B',
      subject: 'Algorithmique des graphes',
      content:
        '# Graphes Privés Enseignant B\n\n## Contenu privé B\nL algorithme de Dijkstra côté enseignant B ne doit jamais fuiter.',
      publish: true,
    });

    // Find Teacher B's knowledge document ID directly via Teacher B's API list
    const listB = await request(app)
      .get('/api/v1/knowledge/documents?limit=10')
      .set({ Authorization: `Bearer ${teacherB.token}` });
    expect(listB.status).toBe(200);
    const teacherBDocId = listB.body.data[0]?.id as string;
    expect(teacherBDocId).toBeTruthy();

    // 1. Default outline generation for Teacher A: ONLY VERIFIED doc from Teacher A (no DRAFT_AI, no Teacher B)
    const outlineDefault = await request(app)
      .post('/api/v1/ai/courses/generate-outline')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({ topic: 'Algorithmes des graphes et Dijkstra' });

    expect(outlineDefault.status).toBe(200);
    expect(outlineDefault.body.data.knowledgeSearchMode).toBe('HYBRID');
    const defaultTitles = (
      outlineDefault.body.data.knowledgeSources as Array<{ title: string; trustTier: string }>
    ).map((s) => s.title);
    expect(defaultTitles).toContain('Graphes Validés A');
    expect(defaultTitles).not.toContain('Graphes Brouillon A');
    expect(defaultTitles).not.toContain('Graphes Privés Enseignant B');

    // 2. Explicit opt-in includeDrafts: includes Teacher A's DRAFT_AI doc, STILL isolates Teacher B
    const outlineWithDrafts = await request(app)
      .post('/api/v1/ai/courses/generate-outline')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({
        topic: 'Algorithmes des graphes et Dijkstra',
        knowledge: { enabled: true, includeDrafts: true, maxChunks: 6 },
      });

    expect(outlineWithDrafts.status).toBe(200);
    const optInTitles = (
      outlineWithDrafts.body.data.knowledgeSources as Array<{ title: string }>
    ).map((s) => s.title);
    expect(optInTitles).toContain('Graphes Validés A');
    expect(optInTitles).toContain('Graphes Brouillon A');
    expect(optInTitles).not.toContain('Graphes Privés Enseignant B');

    // 3. Cross-teacher documentIds attack: SQL isolation returns 0 sources
    const crossTenantRes = await request(app)
      .post('/api/v1/ai/courses/from-topic')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({
        subject: 'Algorithmes des graphes et Dijkstra',
        level: 'concis',
        format: 'resume',
        knowledge: { enabled: true, documentIds: [teacherBDocId], includeDrafts: true },
      });
    expect(crossTenantRes.status).toBe(200);
    expect(crossTenantRes.body.data.knowledgeSources).toEqual([]);

    // 4. Disabled RAG returns DISABLED mode and 0 sources
    const disabledRes = await request(app)
      .post('/api/v1/ai/courses/from-topic')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({
        subject: 'Algorithmes des graphes et Dijkstra',
        level: 'concis',
        format: 'resume',
        knowledge: { enabled: false },
      });
    expect(disabledRes.status).toBe(200);
    expect(disabledRes.body.data.knowledgeSearchMode).toBe('DISABLED');
    expect(disabledRes.body.data.knowledgeSources).toEqual([]);

    // 5. SSE stream with outline & RAG emits phases (knowledge -> generating), outline instructions, and done frame attribution
    capturedPrompts.length = 0;
    const streamRes = await request(app)
      .post('/api/v1/ai/courses/stream')
      .set({ Authorization: `Bearer ${teacherA.token}` })
      .send({
        mode: 'topic',
        subject: 'Algorithmes des graphes et Dijkstra',
        level: 'equilibre',
        format: 'resume',
        outline: {
          title: 'Algorithmes des Graphes',
          targetAudience: 'Licence 3',
          prerequisites: ['Listes'],
          sections: [
            {
              id: 'sec-1',
              title: 'Algorithme de Dijkstra',
              description: 'Plus court chemin pondéré positif',
              keyTopics: ['File de priorité', 'Relâchement'],
              estimatedMinutes: 25,
            },
          ],
        },
        knowledge: { enabled: true, sourceTypes: ['COURSE'] },
      });

    expect(streamRes.status).toBe(200);
    expect(streamRes.text).toContain('"phase":"knowledge"');
    expect(streamRes.text).toContain('"phase":"generating"');
    expect(streamRes.text).toContain('"knowledgeSearchMode":"HYBRID"');
    expect(streamRes.text).toContain('Graphes Validés A');
    expect(capturedPrompts[0]).toContain("PLAN VALIDÉ PAR L'ENSEIGNANT");
    expect(capturedPrompts[0]).toContain('File de priorité');
    expect(capturedPrompts[0]).toContain('[KB-1]');
  });
});

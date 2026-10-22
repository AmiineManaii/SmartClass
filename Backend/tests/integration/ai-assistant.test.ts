import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { ConsoleEmailAdapter } from '../../src/modules/auth/infrastructure/console-email.adapter.js';
import { ServiceUnavailableError } from '../../src/shared/errors/app-error.js';
import type { AiGatewayPort } from '../../src/modules/ai-assistant/domain/ai-gateway.port.js';

// Hermetic gateway: the real Ollama state varies per machine, so
// generation tests run against a drained fake (deterministic 503).
const downGateway: AiGatewayPort = {
  chatCompletion: async () => {
    throw new ServiceUnavailableError(
      'The local AI model is currently unreachable. Start Ollama and retry.',
    );
  },
  streamCompletion: async () => {
    throw new ServiceUnavailableError(
      'The local AI model is currently unreachable. Start Ollama and retry.',
    );
  },
  checkHealth: async () => ({ available: false, model: 'test-model', latencyMs: null }),
};

describe('Integration: AI course generation (local LLM gateway)', () => {
  const emailService = new ConsoleEmailAdapter();
  const app = createApp({
    skipLogging: true,
    authModuleOptions: { emailService },
    aiModuleOptions: { gateway: downGateway },
  });
  const stamp = Date.now();
  const password = 'StrongPassword123!';

  const registerVerifyLogin = async (email: string, role?: string) => {
    await request(app).post('/api/v1/auth/register').send({
      email,
      password,
      firstName: 'Ai',
      lastName: 'Test',
      ...(role ? { role } : {}),
    });
    const sent = emailService.getSentEmails();
    await request(app)
      .post('/api/v1/auth/verify-email')
      .send({ email, code: sent[sent.length - 1]?.code ?? '' });
    const login = await request(app).post('/api/v1/auth/login').send({ email, password });
    expect(login.status).toBe(200);
    return login.body.data.accessToken as string;
  };

  it('GET /ai/status reports the gateway state (never 500)', async () => {
    const teacherToken = await registerVerifyLogin(`aiteacher_${stamp}@test.com`, 'TEACHER');
    const res = await request(app)
      .get('/api/v1/ai/status')
      .set({ Authorization: `Bearer ${teacherToken}` });

    expect(res.status).toBe(200);
    expect(typeof res.body.data.available).toBe('boolean');
    expect(typeof res.body.data.model).toBe('string');
  });

  it('rejects anonymous (401) and non-teachers (403)', async () => {
    const anonymous = await request(app).get('/api/v1/ai/status');
    expect(anonymous.status).toBe(401);

    const studentToken = await registerVerifyLogin(`aistudent_${stamp}@test.com`, 'STUDENT');
    const studentStatus = await request(app)
      .get('/api/v1/ai/status')
      .set({ Authorization: `Bearer ${studentToken}` });
    expect(studentStatus.status).toBe(403);

    const studentGenerate = await request(app)
      .post('/api/v1/ai/courses/generate')
      .set({ Authorization: `Bearer ${studentToken}` })
      .send({ mode: 'topic', subject: 'Les arbres AVL en Algorithmique' });
    expect(studentGenerate.status).toBe(403);
  });

  it('validates generation payloads (422)', async () => {
    const teacherToken = await registerVerifyLogin(`aivalid_${stamp}@test.com`, 'TEACHER');
    const auth = { Authorization: `Bearer ${teacherToken}` };

    const badMode = await request(app)
      .post('/api/v1/ai/courses/generate')
      .set(auth)
      .send({ mode: 'slideshow', subject: 'Les arbres AVL en Algorithmique' });
    expect(badMode.status).toBe(422);

    const shortSubject = await request(app)
      .post('/api/v1/ai/courses/generate')
      .set(auth)
      .send({ mode: 'topic', subject: 'Maths' });
    expect(shortSubject.status).toBe(422);

    const shortText = await request(app)
      .post('/api/v1/ai/courses/generate')
      .set(auth)
      .send({ mode: 'text', sourceText: 'trop court' });
    expect(shortText.status).toBe(422);
  });

  it('returns 503 when the local model is unreachable', async () => {
    const teacherToken = await registerVerifyLogin(`ainodown_${stamp}@test.com`, 'TEACHER');
    const res = await request(app)
      .post('/api/v1/ai/courses/generate')
      .set({ Authorization: `Bearer ${teacherToken}` })
      .send({ mode: 'topic', subject: 'Les arbres AVL en Algorithmique' });

    // Fake drained gateway: deterministic unavailability.
    expect(res.status).toBe(503);
    expect(res.body.error.code).toBe('SERVICE_UNAVAILABLE');
  });

  it('dedicated from-topic / from-url endpoints validate and reach the gateway', async () => {    const teacherToken = await registerVerifyLogin(`aimethods_${stamp}@test.com`, 'TEACHER');
    const auth = { Authorization: `Bearer ${teacherToken}` };

    const shortTopic = await request(app)
      .post('/api/v1/ai/courses/from-topic')
      .set(auth)
      .send({ subject: 'Maths', difficulty: 'facile' });
    expect(shortTopic.status).toBe(422);

    const topic = await request(app)
      .post('/api/v1/ai/courses/from-topic')
      .set(auth)
      .send({
        subject: 'Les arbres AVL en Algorithmique',
        difficulty: 'difficile',
        level: 'concis',
        format: 'flashcards',
        extras: { examples: true, mermaid: false, webImages: true },
      });
    expect(topic.status).toBe(503);
    expect(topic.body.error.code).toBe('SERVICE_UNAVAILABLE');

    const badUrl = await request(app)
      .post('/api/v1/ai/courses/from-url')
      .set(auth)
      .send({ url: 'not-a-url' });
    expect(badUrl.status).toBe(422);

    const badDifficulty = await request(app)
      .post('/api/v1/ai/courses/from-topic')
      .set(auth)
      .send({ subject: 'Les arbres AVL en Algorithmique', difficulty: 'expert' });
    expect(badDifficulty.status).toBe(422);
  });

  it('POST /ai/courses/improve-pdf validates the upload (422) then reaches the gateway (503)', async () => {
    const teacherToken = await registerVerifyLogin(`aipdf_${stamp}@test.com`, 'TEACHER');
    const auth = { Authorization: `Bearer ${teacherToken}` };

    const missing = await request(app)
      .post('/api/v1/ai/courses/improve-pdf')
      .set(auth)
      .field('level', 'equilibre');
    expect(missing.status).toBe(422);

    const notPdf = await request(app)
      .post('/api/v1/ai/courses/improve-pdf')
      .set(auth)
      .field('level', 'equilibre')
      .attach('file', Buffer.from('not a pdf at all'), 'notes.txt');
    expect(notPdf.status).toBe(422);

    const lines = ['Chapitre 1 : les pointeurs et les references.'];
    for (let i = 0; i < 10; i++) lines.push(`Contenu pedagogique reel numero ${i}.`);
    const stream = lines
      .map((line, i) => `BT /F1 12 Tf 72 ${720 - i * 20} Td (${line}) Tj ET`)
      .join('\n');
    const objs = [
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
      `<< /Length ${Buffer.byteLength(stream)} >> stream\n${stream}\nendstream`,
    ];
    let pdf = '%PDF-1.4\n';
    const offsets: number[] = [];
    for (let i = 0; i < objs.length; i++) {
      offsets.push(Buffer.byteLength(pdf));
      pdf += `${i + 1} 0 obj\n${objs[i]}\nendobj\n`;
    }
    const xrefAt = Buffer.byteLength(pdf);
    pdf += 'xref\n0 6\n0000000000 65535 f \n';
    for (const offset of offsets) {
      pdf += `${String(offset).padStart(10, '0')} 00000 n \n`;
    }
    pdf += `trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n${xrefAt}\n%%EOF`;

    // Extraction passes (>100 chars across Tj ops) so the gateway
    // stage (fake drained → 503) is reached.
    const valid = await request(app)
      .post('/api/v1/ai/courses/improve-pdf')
      .set(auth)
      .field('level', 'equilibre')
      .field('format', 'resume')
      .attach('file', Buffer.from(pdf, 'latin1'), 'ancien-cours.pdf');

    // No Ollama in CI: extraction succeeded, gateway is down.
    expect(valid.status).toBe(503);
    expect(valid.body.error.code).toBe('SERVICE_UNAVAILABLE');
  });

  it('POST /ai/courses/stream relays live SSE frames and the error event', async () => {
    const teacherToken = await registerVerifyLogin(`aistream_${stamp}@test.com`, 'TEACHER');
    const auth = { Authorization: `Bearer ${teacherToken}` };

    const badMode = await request(app)
      .post('/api/v1/ai/courses/stream')
      .set(auth)
      .send({ mode: 'slideshow', subject: 'Les arbres AVL en Algorithmique' });
    expect(badMode.status).toBe(422);

    // Fake drained gateway: HTTP stays 200, failure arrives as SSE event.
    const down = await request(app)
      .post('/api/v1/ai/courses/stream')
      .set(auth)
      .send({ mode: 'topic', subject: 'Les arbres AVL en Algorithmique' });
    expect(down.status).toBe(200);
    expect(down.headers['content-type']).toContain('text/event-stream');
    expect(down.text).toContain('"code":"SERVICE_UNAVAILABLE"');
  });

  it('POST /ai/courses/improve-pdf-stream validates then streams the error event', async () => {
    const teacherToken = await registerVerifyLogin(`aistreampdf_${stamp}@test.com`, 'TEACHER');
    const auth = { Authorization: `Bearer ${teacherToken}` };

    const missing = await request(app)
      .post('/api/v1/ai/courses/improve-pdf-stream')
      .set(auth)
      .field('level', 'equilibre');
    expect(missing.status).toBe(422);

    const stream = await request(app)
      .post('/api/v1/ai/courses/improve-pdf-stream')
      .set(auth)
      .field('level', 'equilibre')
      .attach('file', Buffer.from('%PDF-1.4 ' + 'x'.repeat(200)), 'cours.pdf');
    // Extraction fails (<100 chars) → 422 arrives as SSE error event.
    expect(stream.status).toBe(200);
    expect(stream.text).toContain('VALIDATION_ERROR');
  });
});

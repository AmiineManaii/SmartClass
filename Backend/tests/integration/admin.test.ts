import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { ConsoleEmailAdapter } from '../../src/modules/auth/infrastructure/console-email.adapter.js';
import { getPrismaClient } from '../../src/shared/infrastructure/prisma.js';

describe('Integration: Admin endpoints (users / groups / exams / videoconference)', () => {
  const emailService = new ConsoleEmailAdapter();
  const app = createApp({
    skipLogging: true,
    authModuleOptions: { emailService },
  });
  const prisma = getPrismaClient();
  const stamp = Date.now();

  const adminEmail = `admin_${stamp}@test.com`;
  const teacherEmail = `teacher_${stamp}@test.com`;
  const studentEmail = `student_${stamp}@test.com`;
  const password = 'StrongPassword123!';

  let adminToken = '';
  let studentToken = '';
  let groupId = '';
  let studentId = '';
  let teacherId = '';
  let reportId = '';

  const registerAndVerify = async (email: string, firstName: string, lastName: string) => {
    await request(app).post('/api/v1/auth/register').send({
      email,
      password,
      firstName,
      lastName,
    });
    const sent = emailService.getSentEmails();
    const otp = sent[sent.length - 1]?.code ?? '';
    const verifyRes = await request(app)
      .post('/api/v1/auth/verify-email')
      .send({ email, code: otp });
    expect(verifyRes.status).toBe(200);
  };

  beforeAll(async () => {
    emailService.clear();
    await registerAndVerify(adminEmail, 'Admin', 'Root');
    await registerAndVerify(teacherEmail, 'Amine', 'Mansouri');
    await registerAndVerify(studentEmail, 'Salma', 'Benali');

    // ADMIN is never self-assignable via the API: promote directly for tests.
    await prisma.user.update({ where: { email: adminEmail }, data: { role: 'ADMIN' } });
    await prisma.user.update({ where: { email: teacherEmail }, data: { role: 'TEACHER' } });

    const adminLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: adminEmail, password });
    expect(adminLogin.status).toBe(200);
    adminToken = adminLogin.body.data.accessToken as string;

    const studentLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: studentEmail, password });
    expect(studentLogin.status).toBe(200);
    studentToken = studentLogin.body.data.accessToken as string;

    const student = await prisma.user.findUnique({ where: { email: studentEmail } });
    const teacher = await prisma.user.findUnique({ where: { email: teacherEmail } });
    studentId = student?.id ?? '';
    teacherId = teacher?.id ?? '';
  }, 60000);

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  it('GET /users rejects anonymous (401) and non-admin (403) callers', async () => {
    const anonymous = await request(app).get('/api/v1/users');
    expect(anonymous.status).toBe(401);

    const student = await request(app).get('/api/v1/users').set(auth(studentToken));
    expect(student.status).toBe(403);
    expect(student.body.error.code).toBe('FORBIDDEN');
  });

  it('GET /users supports role filter, search and pagination meta', async () => {
    const res = await request(app)
      .get('/api/v1/users')
      .query({ role: 'STUDENT', search: `student_${stamp}`, page: 1, limit: 20 })
      .set(auth(adminToken));

    expect(res.status).toBe(200);
    expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    expect(res.body.meta).toMatchObject({ page: 1, limit: 20 });
    expect(typeof res.body.meta.total).toBe('number');
    for (const user of res.body.data as Array<{ role: string }>) {
      expect(user.role).toBe('STUDENT');
    }
  });

  it('GET /users rejects an invalid role with 422', async () => {
    const res = await request(app)
      .get('/api/v1/users')
      .query({ role: 'SUPERUSER' })
      .set(auth(adminToken));

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('POST /groups validates the payload (422) and creates a class (201)', async () => {
    const invalid = await request(app)
      .post('/api/v1/groups')
      .set(auth(adminToken))
      .send({ name: 'X', level: 'PHD', capacity: 0 });

    expect(invalid.status).toBe(422);

    const created = await request(app)
      .post('/api/v1/groups')
      .set(auth(adminToken))
      .send({
        name: `Informatique 3A ${stamp}`,
        level: 'LICENCE',
        department: 'Informatique',
        capacity: 35,
        description: 'Promotion de test',
      });

    expect(created.status).toBe(201);
    expect(created.body.data.name).toContain('Informatique 3A');
    expect(created.body.data.memberCount).toBe(0);
    expect(created.body.data.status).toBe('PUBLISHED');
    groupId = created.body.data.id as string;
  });

  it('GET /groups lists with counts and GET /groups/:id returns 404 unknown', async () => {
    const list = await request(app)
      .get('/api/v1/groups')
      .query({ level: 'LICENCE', search: `3A ${stamp}` })
      .set(auth(adminToken));

    expect(list.status).toBe(200);
    expect(list.body.data.length).toBeGreaterThanOrEqual(1);
    expect(list.body.meta.total).toBeGreaterThanOrEqual(1);

    const missing = await request(app)
      .get('/api/v1/groups/00000000-0000-0000-0000-000000000000')
      .set(auth(adminToken));
    expect(missing.status).toBe(404);
    expect(missing.body.error.code).toBe('NOT_FOUND');
  });

  it('POST /groups/:id/members assigns students, rejects duplicates (409) and non-students (422)', async () => {
    const assigned = await request(app)
      .post(`/api/v1/groups/${groupId}/members`)
      .set(auth(adminToken))
      .send({ studentIds: [studentId] });

    expect(assigned.status).toBe(200);
    expect(assigned.body.data.added).toEqual([studentId]);
    expect(assigned.body.data.memberCount).toBe(1);

    const duplicate = await request(app)
      .post(`/api/v1/groups/${groupId}/members`)
      .set(auth(adminToken))
      .send({ studentIds: [studentId] });

    expect(duplicate.status).toBe(409);
    expect(duplicate.body.error.code).toBe('ROLE_ALREADY_ASSIGNED');

    const wrongRole = await request(app)
      .post(`/api/v1/groups/${groupId}/members`)
      .set(auth(adminToken))
      .send({ studentIds: [teacherId] });

    expect(wrongRole.status).toBe(422);

    const detail = await request(app).get(`/api/v1/groups/${groupId}`).set(auth(adminToken));
    expect(detail.body.data.memberCount).toBe(1);
  });

  it('POST /groups/:id/teachers upserts assignments and rejects non-teachers (422)', async () => {
    const assigned = await request(app)
      .post(`/api/v1/groups/${groupId}/teachers`)
      .set(auth(adminToken))
      .send({
        assignments: [{ teacherId, subject: 'Développement Mobile', weeklyHours: '4h/semaine' }],
      });

    expect(assigned.status).toBe(200);
    expect(assigned.body.data.teacherCount).toBe(1);

    const updated = await request(app)
      .post(`/api/v1/groups/${groupId}/teachers`)
      .set(auth(adminToken))
      .send({
        assignments: [{ teacherId, subject: 'Algorithmique', weeklyHours: '6h/semaine' }],
      });

    expect(updated.status).toBe(200);
    expect(updated.body.data.teacherCount).toBe(1);
    expect(updated.body.data.assigned[0].subject).toBe('Algorithmique');

    const wrongRole = await request(app)
      .post(`/api/v1/groups/${groupId}/teachers`)
      .set(auth(adminToken))
      .send({ assignments: [{ teacherId: studentId, subject: 'Maths' }] });

    expect(wrongRole.status).toBe(422);
  });

  it('GET /exams/fraud-reports/summary returns counters', async () => {
    await prisma.fraudReport.create({
      data: {
        title: `Suspicion QCM ${stamp}`,
        context: 'Examen Partiel',
        severity: 'HIGH',
        status: 'UNTREATED',
        studentId,
        studentName: 'Salma Benali',
        studentCode: '#ETU-1',
        classGroupId: groupId,
        className: 'Informatique 3A',
        findings: ['Perte de focus x5'],
        occurredAt: new Date(),
      },
    });

    const res = await request(app).get('/api/v1/exams/fraud-reports/summary').set(auth(adminToken));

    expect(res.status).toBe(200);
    expect(res.body.data.untreated).toBeGreaterThanOrEqual(1);
    expect(res.body.data).toMatchObject({
      inProgress: expect.any(Number),
      closed: expect.any(Number),
      resolvedThisMonth: expect.any(Number),
    });
    reportId = (
      await prisma.fraudReport.findFirst({
        where: { title: `Suspicion QCM ${stamp}` },
        select: { id: true },
      })
    )?.id as string;
  });

  it('GET /exams/fraud-reports paginates with cursor and filters by status', async () => {
    const page = await request(app)
      .get('/api/v1/exams/fraud-reports')
      .query({ status: 'UNTREATED', limit: 5 })
      .set(auth(adminToken));

    expect(page.status).toBe(200);
    expect(Array.isArray(page.body.data)).toBe(true);
    expect(page.body.meta).toMatchObject({ limit: 5 });
    expect(typeof page.body.meta.hasMore).toBe('boolean');
    for (const report of page.body.data as Array<{ status: string }>) {
      expect(report.status).toBe('UNTREATED');
    }
  });

  it('PATCH /exams/fraud-reports/:id transitions status and locks CLOSED reports', async () => {
    const progress = await request(app)
      .patch(`/api/v1/exams/fraud-reports/${reportId}`)
      .set(auth(adminToken))
      .send({ status: 'IN_PROGRESS' });

    expect(progress.status).toBe(200);
    expect(progress.body.data.status).toBe('IN_PROGRESS');

    const closed = await request(app)
      .patch(`/api/v1/exams/fraud-reports/${reportId}`)
      .set(auth(adminToken))
      .send({ status: 'CLOSED', resolution: 'Dossier vérifié.' });

    expect(closed.status).toBe(200);
    expect(closed.body.data.status).toBe('CLOSED');

    const reopen = await request(app)
      .patch(`/api/v1/exams/fraud-reports/${reportId}`)
      .set(auth(adminToken))
      .send({ status: 'IN_PROGRESS' });

    expect(reopen.status).toBe(409);
    expect(reopen.body.error.code).toBe('CONFLICT');
  });

  it('GET /videoconference/timetable returns the bounded week view', async () => {
    const monday = new Date();
    const shift = (monday.getUTCDay() + 6) % 7;
    monday.setUTCDate(monday.getUTCDate() - shift);
    monday.setUTCHours(0, 0, 0, 0);

    await prisma.timetableSlot.create({
      data: {
        classGroupId: groupId,
        title: 'Développement Mobile',
        kind: 'CM',
        startsAt: new Date(monday.getTime() + 8 * 3600 * 1000),
        endsAt: new Date(monday.getTime() + 10 * 3600 * 1000),
        teacherId,
        room: 'Salle 102',
        statusNotes: ['Confirmé'],
      },
    });

    const res = await request(app)
      .get('/api/v1/videoconference/timetable')
      .query({ classGroupId: groupId })
      .set(auth(adminToken));

    expect(res.status).toBe(200);
    expect(res.body.data.days).toHaveLength(6);
    expect(res.body.data.events.length).toBeGreaterThanOrEqual(1);
    const event = res.body.data.events[0] as {
      start: string;
      kind: string;
      teacher: { name: string } | null;
    };
    expect(event.start).toBe('08:00');
    expect(event.kind).toBe('CM');
    expect(event.teacher?.name).toContain('Amine');
  });

  it('GET /videoconference/timetable validates input (404 unknown group, 422 bad date)', async () => {
    const missing = await request(app)
      .get('/api/v1/videoconference/timetable')
      .query({ classGroupId: '00000000-0000-0000-0000-000000000000' })
      .set(auth(adminToken));
    expect(missing.status).toBe(404);

    const badDate = await request(app)
      .get('/api/v1/videoconference/timetable')
      .query({ classGroupId: groupId, weekStart: '2025-13-45' })
      .set(auth(adminToken));
    expect(badDate.status).toBe(422);
  });

  it('non-admin callers are rejected on admin routes (403)', async () => {
    const res = await request(app)
      .get('/api/v1/exams/fraud-reports/summary')
      .set(auth(studentToken));
    expect(res.status).toBe(403);
  });
});

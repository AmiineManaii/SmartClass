import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { ConsoleEmailAdapter } from '../../src/modules/auth/infrastructure/console-email.adapter.js';
import { getPrismaClient } from '../../src/shared/infrastructure/prisma.js';

describe('Integration: role management (register guard + set role)', () => {
  const emailService = new ConsoleEmailAdapter();
  const prisma = getPrismaClient();
  const app = createApp({
    skipLogging: true,
    authModuleOptions: {
      emailService,
    },
  });

  const stamp = Date.now();
  const newcomer = `rolecheck_${stamp}@test.com`;
  const password = 'StrongPassword123!';

  const registerVerifyLogin = async (email: string) => {
    const regRes = await request(app).post('/api/v1/auth/register').send({
      email,
      password,
      firstName: 'Role',
      lastName: 'Check',
    });
    expect(regRes.status).toBe(201);

    const sent = emailService.getSentEmails();
    const otp = sent[sent.length - 1]?.code ?? '';
    const verifyRes = await request(app)
      .post('/api/v1/auth/verify-email')
      .send({ email, code: otp });
    expect(verifyRes.status).toBe(200);

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email, password });
    expect(loginRes.status).toBe(200);
    return loginRes.body.data.accessToken as string;
  };

  it('rejects ADMIN at public registration with 403', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({
      email: `eviladmin_${stamp}@test.com`,
      password,
      firstName: 'Evil',
      lastName: 'Admin',
      role: 'ADMIN',
    });

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe('FORBIDDEN');
  });

  it('assigns TEACHER once via PATCH /users/me/role and issues fresh tokens', async () => {
    const token = await registerVerifyLogin(newcomer);

    const first = await request(app)
      .patch('/api/v1/users/me/role')
      .set('Authorization', `Bearer ${token}`)
      .send({ role: 'TEACHER' });

    expect(first.status).toBe(200);
    expect(first.body.data.user.role).toBe('TEACHER');
    expect(first.body.data.accessToken).toBeDefined();
    expect(first.body.data.refreshToken).toBeDefined();

    const second = await request(app)
      .patch('/api/v1/users/me/role')
      .set('Authorization', `Bearer ${first.body.data.accessToken}`)
      .send({ role: 'STUDENT' });

    expect(second.status).toBe(409);
    expect(second.body.error.code).toBe('ROLE_ALREADY_ASSIGNED');
  });

  it('rejects ADMIN self-assignment via PATCH /users/me/role', async () => {
    const email = `selfadmin_${stamp}@test.com`;
    const token = await registerVerifyLogin(email);

    const res = await request(app)
      .patch('/api/v1/users/me/role')
      .set('Authorization', `Bearer ${token}`)
      .send({ role: 'ADMIN' });

    expect(res.status).toBe(403);
  });

  it('lets an admin promote another user and blocks self-modification', async () => {
    // Self-contained promoter: ADMIN is never self-assignable via the API,
    // so the fixture is promoted directly (no seed dependency).
    const promoterEmail = `promoter_${stamp}@test.com`;
    await request(app).post('/api/v1/auth/register').send({
      email: promoterEmail,
      password,
      firstName: 'Root',
      lastName: 'Admin',
    });
    const sent = emailService.getSentEmails();
    await request(app)
      .post('/api/v1/auth/verify-email')
      .send({ email: promoterEmail, code: sent[sent.length - 1]?.code ?? '' });
    await prisma.user.update({
      where: { email: promoterEmail },
      data: { role: 'ADMIN' },
    });
    const adminLogin = await request(app).post('/api/v1/auth/login').send({
      email: promoterEmail,
      password,
    });
    expect(adminLogin.status).toBe(200);
    const adminToken = adminLogin.body.data.accessToken as string;

    const targetEmail = `promote_${stamp}@test.com`;
    const targetToken = await registerVerifyLogin(targetEmail);

    const meRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${targetToken}`);
    const targetId = meRes.body.data.user.id as string;

    const promoted = await request(app)
      .patch(`/api/v1/users/${targetId}/role`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ role: 'ADMIN' });

    expect(promoted.status).toBe(200);
    expect(promoted.body.data.user.role).toBe('ADMIN');

    const adminMe = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${adminToken}`);
    const adminId = adminMe.body.data.user.id as string;

    const selfMod = await request(app)
      .patch(`/api/v1/users/${adminId}/role`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ role: 'STUDENT' });

    expect(selfMod.status).toBe(403);

    const studentAttempt = await request(app)
      .patch(`/api/v1/users/${targetId}/role`)
      .set('Authorization', `Bearer ${targetToken}`)
      .send({ role: 'TEACHER' });

    expect(studentAttempt.status).toBe(403);
  });

  it('requires authentication on role routes (401)', async () => {
    const res = await request(app)
      .patch('/api/v1/users/me/role')
      .send({ role: 'TEACHER' });

    expect(res.status).toBe(401);
  });
});

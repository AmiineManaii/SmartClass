import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { ConsoleEmailAdapter } from '../../src/modules/auth/infrastructure/console-email.adapter.js';

describe('Integration: POST /api/v1/auth/check-email', () => {
  const emailService = new ConsoleEmailAdapter();
  const app = createApp({
    skipLogging: true,
    authModuleOptions: {
      emailService,
    },
  });

  const takenEmail = `taken_${Date.now()}@test.com`;
  const freeEmail = `free_${Date.now()}@test.com`;

  it('returns available=true for an unknown email', async () => {
    const res = await request(app)
      .post('/api/v1/auth/check-email')
      .send({ email: freeEmail });

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({ available: true, email: freeEmail });
  });

  it('returns available=false after the email is registered', async () => {
    const regRes = await request(app).post('/api/v1/auth/register').send({
      email: takenEmail,
      password: 'StrongPassword123!',
      firstName: 'Salma',
      lastName: 'Benali',
      role: 'STUDENT',
    });
    expect(regRes.status).toBe(201);

    const res = await request(app)
      .post('/api/v1/auth/check-email')
      .send({ email: takenEmail });

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({ available: false, email: takenEmail });
  });

  it('matches case-insensitively like register does', async () => {
    const res = await request(app)
      .post('/api/v1/auth/check-email')
      .send({ email: takenEmail.toUpperCase() });

    expect(res.status).toBe(200);
    expect(res.body.data.available).toBe(false);
  });

  it('rejects an invalid email with 422', async () => {
    const res = await request(app)
      .post('/api/v1/auth/check-email')
      .send({ email: 'not-an-email' });

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('rejects a missing body with 422', async () => {
    const res = await request(app)
      .post('/api/v1/auth/check-email')
      .send({});

    expect(res.status).toBe(422);
  });
});

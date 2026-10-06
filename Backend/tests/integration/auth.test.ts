import { describe, it, expect, beforeEach } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { ConsoleEmailAdapter } from '../../src/modules/auth/infrastructure/console-email.adapter.js';

describe('Integration: Auth Endpoints', () => {
  const emailService = new ConsoleEmailAdapter();
  const app = createApp({
    skipLogging: true,
    authModuleOptions: {
      emailService,
    },
  });

  const testUser = {
    email: `student_${Date.now()}@test.com`,
    password: 'StrongPassword123!',
    firstName: 'Salma',
    lastName: 'Benali',
    role: 'STUDENT' as const,
  };

  beforeEach(() => {
    emailService.clear();
  });

  it('full auth lifecycle: register -> verify -> login -> me -> refresh -> logout', async () => {
    // 1. Register new user
    const regRes = await request(app)
      .post('/api/v1/auth/register')
      .send(testUser);

    expect(regRes.status).toBe(201);
    expect(regRes.body.data.user.email).toBe(testUser.email.toLowerCase());
    expect(regRes.body.data.user.emailVerified).toBe(false);

    // Retrieve verification OTP from email mock
    const sentEmails = emailService.getSentEmails();
    expect(sentEmails.length).toBe(1);
    const otpCode = sentEmails[0]?.code;
    expect(otpCode).toMatch(/^\d{6}$/);

    // 2. Attempt login before email verification -> expects 403 AUTH_EMAIL_NOT_VERIFIED
    const unverifiedLoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: testUser.email,
        password: testUser.password,
      });

    expect(unverifiedLoginRes.status).toBe(403);
    expect(unverifiedLoginRes.body.error.code).toBe('AUTH_EMAIL_NOT_VERIFIED');

    // 3. Verify email with OTP code -> expects 200 and initial session tokens
    const verifyRes = await request(app)
      .post('/api/v1/auth/verify-email')
      .send({
        email: testUser.email,
        code: otpCode,
      });

    expect(verifyRes.status).toBe(200);
    expect(verifyRes.body.data.user.emailVerified).toBe(true);
    expect(verifyRes.body.data.accessToken).toBeDefined();
    expect(verifyRes.body.data.refreshToken).toBeDefined();

    // 4. Successful login
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: testUser.email,
        password: testUser.password,
      });

    expect(loginRes.status).toBe(200);
    const { accessToken, refreshToken } = loginRes.body.data;
    expect(accessToken).toBeDefined();
    expect(refreshToken).toBeDefined();

    // 5. Access protected /auth/me endpoint
    const meRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${accessToken}`);

    expect(meRes.status).toBe(200);
    expect(meRes.body.data.user.email).toBe(testUser.email.toLowerCase());
    expect(meRes.body.data.user.firstName).toBe('Salma');

    // 6. Rotate refresh token via /auth/refresh
    const refreshRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken });

    expect(refreshRes.status).toBe(200);
    expect(refreshRes.body.data.accessToken).toBeDefined();
    expect(refreshRes.body.data.refreshToken).toBeDefined();
    expect(refreshRes.body.data.refreshToken).not.toBe(refreshToken);

    // 7. Logout
    const logoutRes = await request(app)
      .post('/api/v1/auth/logout')
      .send({ refreshToken: refreshRes.body.data.refreshToken });

    expect(logoutRes.status).toBe(200);
    expect(logoutRes.body.data.message).toContain('Logged out successfully');
  });

  it('rejects registration with weak passwords (validation error 422)', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        email: 'weak@example.com',
        password: 'weak', // too short, no uppercase, no numbers, no special chars
        firstName: 'Weak',
        lastName: 'Pass',
      });

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('enforces 3-attempt account lockout for 5 minutes (HTTP 423 AUTH_ACCOUNT_LOCKED)', async () => {
    const email = `lockout_${Date.now()}@test.com`;
    const password = 'CorrectPassword123!';

    // Register & verify user
    await request(app).post('/api/v1/auth/register').send({
      email,
      password,
      firstName: 'Locked',
      lastName: 'User',
    });

    const otp = emailService.getSentEmails()[0]?.code;
    await request(app).post('/api/v1/auth/verify-email').send({ email, code: otp });

    // Wrong password 1: 401 with 2 attempts remaining
    const attempt1 = await request(app)
      .post('/api/v1/auth/login')
      .send({ email, password: 'WrongPassword1!' });
    expect(attempt1.status).toBe(401);
    expect(attempt1.body.error.code).toBe('AUTH_INVALID_CREDENTIALS');

    // Wrong password 2: 401 with 1 attempt remaining
    const attempt2 = await request(app)
      .post('/api/v1/auth/login')
      .send({ email, password: 'WrongPassword2!' });
    expect(attempt2.status).toBe(401);

    // Wrong password 3: TRIGGERS 5-MINUTE LOCKOUT (HTTP 423)!
    const attempt3 = await request(app)
      .post('/api/v1/auth/login')
      .send({ email, password: 'WrongPassword3!' });
    expect(attempt3.status).toBe(423);
    expect(attempt3.body.error.code).toBe('AUTH_ACCOUNT_LOCKED');
    expect(attempt3.body.error.message).toContain('Account temporarily locked');

    // Attempt 4: Even with correct password, login is blocked while locked
    const attempt4 = await request(app)
      .post('/api/v1/auth/login')
      .send({ email, password });
    expect(attempt4.status).toBe(423);
    expect(attempt4.body.error.code).toBe('AUTH_ACCOUNT_LOCKED');
  });

  it('supports password reset flow via OTP', async () => {
    const email = `reset_${Date.now()}@test.com`;
    const oldPassword = 'OldPassword123!';
    const newPassword = 'BrandNewPassword456!';

    // Register & verify user
    await request(app).post('/api/v1/auth/register').send({
      email,
      password: oldPassword,
      firstName: 'Reset',
      lastName: 'Candidate',
    });
    const verifyOtp = emailService.getSentEmails()[0]?.code;
    await request(app).post('/api/v1/auth/verify-email').send({ email, code: verifyOtp });
    emailService.clear();

    // 1. Request forgot-password
    const forgotRes = await request(app)
      .post('/api/v1/auth/forgot-password')
      .send({ email });
    expect(forgotRes.status).toBe(200);

    const resetOtp = emailService.getSentEmails()[0]?.code;
    expect(resetOtp).toMatch(/^\d{6}$/);

    // 2. Submit reset-password
    const resetRes = await request(app)
      .post('/api/v1/auth/reset-password')
      .send({
        email,
        code: resetOtp,
        newPassword,
      });
    expect(resetRes.status).toBe(200);

    // 3. Old password should fail
    const oldLoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email, password: oldPassword });
    expect(oldLoginRes.status).toBe(401);

    // 4. New password should succeed
    const newLoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email, password: newPassword });
    expect(newLoginRes.status).toBe(200);
    expect(newLoginRes.body.data.accessToken).toBeDefined();
  });

  it('supports 3 account roles (STUDENT, TEACHER, ADMIN) with French/English inputs', async () => {
    // 1. Register with 'profesor' -> normalized to TEACHER
    const teacherRes = await request(app).post('/api/v1/auth/register').send({
      email: `prof_${Date.now()}@test.com`,
      password: 'ProfPassword123!',
      firstName: 'Farouk',
      lastName: 'Messay',
      role: 'profesor',
    });
    expect(teacherRes.status).toBe(201);
    expect(teacherRes.body.data.user.role).toBe('TEACHER');

    // 2. Register with 'administrateur' -> normalized to ADMIN
    const adminRes = await request(app).post('/api/v1/auth/register').send({
      email: `admin_${Date.now()}@test.com`,
      password: 'AdminPassword123!',
      firstName: 'Karim',
      lastName: 'Admin',
      role: 'administrateur',
    });
    expect(adminRes.status).toBe(201);
    expect(adminRes.body.data.user.role).toBe('ADMIN');

    // 3. Register with default (omitted role) -> defaults to STUDENT
    const studentRes = await request(app).post('/api/v1/auth/register').send({
      email: `student_default_${Date.now()}@test.com`,
      password: 'StudentPass123!',
      firstName: 'Salma',
      lastName: 'Eleve',
    });
    expect(studentRes.status).toBe(201);
    expect(studentRes.body.data.user.role).toBe('STUDENT');
  });

  it('supports fetching and updating account profile data via /auth/profile', async () => {
    const email = `account_profile_${Date.now()}@test.com`;
    const password = 'ProfilePassword123!';

    // Register & verify
    await request(app).post('/api/v1/auth/register').send({
      email,
      password,
      firstName: 'InitialFirst',
      lastName: 'InitialLast',
      role: 'TEACHER',
    });
    const otp = emailService.getSentEmails()[0]?.code;
    await request(app).post('/api/v1/auth/verify-email').send({ email, code: otp });

    // Login
    const loginRes = await request(app).post('/api/v1/auth/login').send({ email, password });
    const token = loginRes.body.data.accessToken;

    // GET /api/v1/auth/profile
    const getProfileRes = await request(app)
      .get('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${token}`);
    expect(getProfileRes.status).toBe(200);
    expect(getProfileRes.body.data.user.email).toBe(email);
    expect(getProfileRes.body.data.user.firstName).toBe('InitialFirst');
    expect(getProfileRes.body.data.user.role).toBe('TEACHER');

    // PATCH /api/v1/auth/profile
    const patchRes = await request(app)
      .patch('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${token}`)
      .send({
        firstName: 'UpdatedFarouk',
        lastName: 'UpdatedMessay',
        birthDate: '1995-12-10',
        onboardingCompleted: true,
      });

    expect(patchRes.status).toBe(200);
    expect(patchRes.body.data.message).toBe('Profile updated successfully');
    expect(patchRes.body.data.user.firstName).toBe('UpdatedFarouk');
    expect(patchRes.body.data.user.lastName).toBe('UpdatedMessay');
    expect(patchRes.body.data.user.birthDate).toBe('1995-12-10');
    expect(patchRes.body.data.user.onboardingCompleted).toBe(true);
  });
});


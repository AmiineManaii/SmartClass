import { describe, it, expect, beforeEach } from 'vitest';
import crypto from 'node:crypto';
import { RegisterUseCase } from '../../src/modules/auth/application/register.use-case.js';
import { VerifyEmailUseCase } from '../../src/modules/auth/application/verify-email.use-case.js';
import { LoginUseCase } from '../../src/modules/auth/application/login.use-case.js';
import { RefreshTokenUseCase } from '../../src/modules/auth/application/refresh-token.use-case.js';
import { ResetPasswordUseCase } from '../../src/modules/auth/application/reset-password.use-case.js';
import { UserEntity } from '../../src/modules/auth/domain/user.entity.js';
import type {
  AuthRepositoryPort,
  CreateUserParams,
  StoredPasswordResetCode,
  StoredRefreshToken,
  StoredVerificationCode,
} from '../../src/modules/auth/domain/auth-repository.port.js';
import type { PasswordHasherPort } from '../../src/modules/auth/domain/password-hasher.port.js';
import type { TokenServicePort } from '../../src/modules/auth/domain/token-service.port.js';
import type { EmailPort } from '../../src/modules/auth/domain/email.port.js';
import {
  AccountLockedError,
  ConflictError,
  ForbiddenError,
  UnauthorizedError,
  BadRequestError,
} from '../../src/shared/errors/app-error.js';
import { ErrorCodes } from '../../src/shared/errors/error-codes.js';

class MockAuthRepository implements AuthRepositoryPort {
  public users: Map<string, UserEntity> = new Map();
  public verificationCodes: Map<string, StoredVerificationCode> = new Map();
  public passwordResetCodes: Map<string, StoredPasswordResetCode> = new Map();
  public refreshTokens: Map<string, StoredRefreshToken> = new Map();

  public async findUserByEmail(email: string): Promise<UserEntity | null> {
    for (const u of this.users.values()) {
      if (u.email.toLowerCase() === email.toLowerCase()) return u;
    }
    return null;
  }

  public async findUserById(id: string): Promise<UserEntity | null> {
    return this.users.get(id) ?? null;
  }

  public async createUser(params: CreateUserParams): Promise<UserEntity> {
    const id = crypto.randomUUID();
    const entity = new UserEntity({
      id,
      email: params.email,
      passwordHash: params.passwordHash,
      firstName: params.firstName,
      lastName: params.lastName,
      role: params.role ?? null,
      birthDate: null,
      status: params.status ?? 'ACTIVE',
      emailVerified: params.emailVerified ?? false,
      onboardingCompleted: false,
      failedLoginAttempts: 0,
      lockedUntil: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    this.users.set(id, entity);
    return entity;
  }

  public async updateUser(
    id: string,
    params: Partial<{
      passwordHash: string;
      emailVerified: boolean;
      failedLoginAttempts: number;
      lockedUntil: Date | null;
      status: 'ACTIVE' | 'SUSPENDED';
    }>,
  ): Promise<UserEntity> {
    const current = this.users.get(id);
    if (!current) throw new Error('User not found in mock');

    const updated = new UserEntity({
      id: current.id,
      email: current.email,
      passwordHash: params.passwordHash ?? current.passwordHash,
      firstName: current.firstName,
      lastName: current.lastName,
      role: current.role,
      birthDate: current.birthDate,
      status: params.status ?? current.status,
      emailVerified: params.emailVerified ?? current.emailVerified,
      onboardingCompleted: current.onboardingCompleted,
      failedLoginAttempts: params.failedLoginAttempts ?? current.failedLoginAttempts,
      lockedUntil: params.lockedUntil !== undefined ? params.lockedUntil : current.lockedUntil,
      createdAt: current.createdAt,
      updatedAt: new Date(),
    });
    this.users.set(id, updated);
    return updated;
  }

  public async incrementFailedAttempts(
    userId: string,
    maxAttempts: number,
    lockoutMinutes: number,
  ) {
    const user = this.users.get(userId);
    if (!user) throw new Error('User not found');
    const newAttempts = user.failedLoginAttempts + 1;

    if (newAttempts >= maxAttempts) {
      const lockedUntil = new Date(Date.now() + lockoutMinutes * 60 * 1000);
      await this.updateUser(userId, { failedLoginAttempts: newAttempts, lockedUntil });
      return { failedAttempts: newAttempts, isLocked: true, lockedUntil };
    }

    await this.updateUser(userId, { failedLoginAttempts: newAttempts });
    return { failedAttempts: newAttempts, isLocked: false, lockedUntil: null };
  }

  public async resetFailedAttempts(userId: string): Promise<void> {
    await this.updateUser(userId, { failedLoginAttempts: 0, lockedUntil: null });
  }

  public async createVerificationCode(userId: string, codeHash: string, expiresAt: Date) {
    this.verificationCodes.set(userId, {
      id: crypto.randomUUID(),
      userId,
      codeHash,
      expiresAt,
      attempts: 0,
    });
  }

  public async getLatestVerificationCode(userId: string) {
    return this.verificationCodes.get(userId) ?? null;
  }

  public async incrementVerificationAttempts(codeId: string) {
    for (const [key, code] of this.verificationCodes.entries()) {
      if (code.id === codeId) {
        code.attempts += 1;
        this.verificationCodes.set(key, code);
        return code.attempts;
      }
    }
    return 1;
  }

  public async deleteVerificationCodes(userId: string) {
    this.verificationCodes.delete(userId);
  }

  public async createPasswordResetCode(userId: string, codeHash: string, expiresAt: Date) {
    this.passwordResetCodes.set(userId, {
      id: crypto.randomUUID(),
      userId,
      codeHash,
      expiresAt,
      usedAt: null,
      attempts: 0,
    });
  }

  public async getLatestPasswordResetCode(userId: string) {
    return this.passwordResetCodes.get(userId) ?? null;
  }

  public async incrementPasswordResetAttempts(codeId: string) {
    for (const [key, code] of this.passwordResetCodes.entries()) {
      if (code.id === codeId) {
        code.attempts += 1;
        this.passwordResetCodes.set(key, code);
        return code.attempts;
      }
    }
    return 1;
  }

  public async markPasswordResetCodeUsed(codeId: string) {
    for (const [key, code] of this.passwordResetCodes.entries()) {
      if (code.id === codeId) {
        code.usedAt = new Date();
        this.passwordResetCodes.set(key, code);
      }
    }
  }

  public async saveRefreshToken(userId: string, tokenHash: string, familyId: string, expiresAt: Date) {
    const id = crypto.randomUUID();
    this.refreshTokens.set(tokenHash, {
      id,
      userId,
      tokenHash,
      familyId,
      isRevoked: false,
      expiresAt,
      createdAt: new Date(),
    });
  }

  public async findRefreshToken(tokenHash: string) {
    return this.refreshTokens.get(tokenHash) ?? null;
  }

  public async revokeRefreshToken(id: string) {
    for (const [hash, token] of this.refreshTokens.entries()) {
      if (token.id === id) {
        token.isRevoked = true;
        this.refreshTokens.set(hash, token);
      }
    }
  }

  public async revokeFamily(familyId: string) {
    for (const [hash, token] of this.refreshTokens.entries()) {
      if (token.familyId === familyId) {
        token.isRevoked = true;
        this.refreshTokens.set(hash, token);
      }
    }
  }

  public async revokeAllUserTokens(userId: string) {
    for (const [hash, token] of this.refreshTokens.entries()) {
      if (token.userId === userId) {
        token.isRevoked = true;
        this.refreshTokens.set(hash, token);
      }
    }
  }
}

class MockPasswordHasher implements PasswordHasherPort {
  public async hash(password: string): Promise<string> {
    return `hashed_${password}`;
  }

  public async verify(password: string, hash: string): Promise<boolean> {
    return hash === `hashed_${password}`;
  }
}

class MockTokenService implements TokenServicePort {
  public async generateAccessToken(payload: { sub: string }): Promise<{ token: string; expiresIn: number }> {
    return { token: `access_${payload.sub}`, expiresIn: 900 };
  }

  public generateRefreshToken(): string {
    return `refresh_${crypto.randomUUID()}`;
  }

  public async verifyAccessToken(token: string) {
    const sub = token.replace('access_', '');
    return { sub, email: 'test@example.com', role: null, status: 'ACTIVE' as const };
  }

  public hashRefreshToken(token: string): string {
    return `hash_${token}`;
  }
}

class MockEmailService implements EmailPort {
  public sentVerificationCodes: { email: string; code: string }[] = [];
  public sentResetCodes: { email: string; code: string }[] = [];

  public async sendVerificationEmail(email: string, _firstName: string, code: string): Promise<void> {
    this.sentVerificationCodes.push({ email, code });
  }

  public async sendPasswordResetEmail(email: string, _firstName: string, code: string): Promise<void> {
    this.sentResetCodes.push({ email, code });
  }
}

describe('Auth Module — Unit Tests', () => {
  let authRepo: MockAuthRepository;
  let hasher: MockPasswordHasher;
  let tokenService: MockTokenService;
  let emailService: MockEmailService;

  beforeEach(() => {
    authRepo = new MockAuthRepository();
    hasher = new MockPasswordHasher();
    tokenService = new MockTokenService();
    emailService = new MockEmailService();
  });

  describe('RegisterUseCase', () => {
    it('creates a user with unverified email and dispatches 6-digit OTP', async () => {
      const useCase = new RegisterUseCase(authRepo, hasher, emailService);
      const result = await useCase.execute({
        email: 'amine@test.com',
        password: 'Password123!',
        firstName: 'Amine',
        lastName: 'Manai',
        role: 'TEACHER',
      });

      expect(result.user.email).toBe('amine@test.com');
      expect(result.user.emailVerified).toBe(false);
      expect(emailService.sentVerificationCodes.length).toBe(1);
      expect(emailService.sentVerificationCodes[0]?.code).toMatch(/^\d{6}$/);
    });

    it('rejects duplicate email with ConflictError', async () => {
      const useCase = new RegisterUseCase(authRepo, hasher, emailService);
      await useCase.execute({
        email: 'amine@test.com',
        password: 'Password123!',
        firstName: 'Amine',
        lastName: 'Manai',
      });

      await expect(
        useCase.execute({
          email: 'amine@test.com',
          password: 'Password123!',
          firstName: 'Amine',
          lastName: 'Duplicate',
        }),
      ).rejects.toThrow(ConflictError);
    });
  });

  describe('VerifyEmailUseCase', () => {
    it('verifies email with correct OTP and returns access & refresh tokens', async () => {
      const registerUseCase = new RegisterUseCase(authRepo, hasher, emailService);
      await registerUseCase.execute({
        email: 'salma@test.com',
        password: 'Password123!',
        firstName: 'Salma',
        lastName: 'Student',
      });

      const sentCode = emailService.sentVerificationCodes[0]?.code ?? '';
      const verifyUseCase = new VerifyEmailUseCase(authRepo, tokenService);
      const result = await verifyUseCase.execute({
        email: 'salma@test.com',
        code: sentCode,
      });

      expect(result.user.emailVerified).toBe(true);
      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
    });

    it('rejects wrong OTP with BadRequestError and tracks attempts', async () => {
      const registerUseCase = new RegisterUseCase(authRepo, hasher, emailService);
      await registerUseCase.execute({
        email: 'salma@test.com',
        password: 'Password123!',
        firstName: 'Salma',
        lastName: 'Student',
      });

      const verifyUseCase = new VerifyEmailUseCase(authRepo, tokenService);
      await expect(
        verifyUseCase.execute({
          email: 'salma@test.com',
          code: '000000',
        }),
      ).rejects.toThrow(BadRequestError);
    });
  });

  describe('LoginUseCase — 3-Attempt Lockout & Brute Force Protection', () => {
    it('allows login with valid password and verified email', async () => {
      const user = await authRepo.createUser({
        email: 'amine@test.com',
        passwordHash: 'hashed_Password123!',
        firstName: 'Amine',
        lastName: 'Teacher',
        emailVerified: true,
      });

      const loginUseCase = new LoginUseCase(authRepo, hasher, tokenService);
      const result = await loginUseCase.execute({
        email: user.email,
        password: 'Password123!',
      });

      expect(result.accessToken).toBeDefined();
      expect(result.user.email).toBe('amine@test.com');
    });

    it('blocks unverified accounts with AUTH_EMAIL_NOT_VERIFIED', async () => {
      const user = await authRepo.createUser({
        email: 'unverified@test.com',
        passwordHash: 'hashed_Password123!',
        firstName: 'Unverified',
        lastName: 'User',
        emailVerified: false,
      });

      const loginUseCase = new LoginUseCase(authRepo, hasher, tokenService);
      await expect(
        loginUseCase.execute({
          email: user.email,
          password: 'Password123!',
        }),
      ).rejects.toThrow(ForbiddenError);
    });

    it('locks account for 5 minutes after exactly 3 consecutive wrong passwords', async () => {
      const user = await authRepo.createUser({
        email: 'lockout@test.com',
        passwordHash: 'hashed_CorrectPassword!',
        firstName: 'Locked',
        lastName: 'User',
        emailVerified: true,
      });

      const loginUseCase = new LoginUseCase(authRepo, hasher, tokenService, 3, 5);

      // Attempt 1: wrong password (2 attempts left)
      try {
        await loginUseCase.execute({ email: user.email, password: 'Wrong1' });
        expect.unreachable('Should have thrown');
      } catch (err) {
        expect(err).toBeInstanceOf(UnauthorizedError);
        expect((err as UnauthorizedError).code).toBe(ErrorCodes.AUTH_INVALID_CREDENTIALS);
      }

      // Attempt 2: wrong password (1 attempt left)
      try {
        await loginUseCase.execute({ email: user.email, password: 'Wrong2' });
        expect.unreachable('Should have thrown');
      } catch (err) {
        expect(err).toBeInstanceOf(UnauthorizedError);
      }

      // Attempt 3: 3rd wrong password -> TRIGGERS ACCOUNT LOCKOUT!
      try {
        await loginUseCase.execute({ email: user.email, password: 'Wrong3' });
        expect.unreachable('Should have thrown');
      } catch (err) {
        expect(err).toBeInstanceOf(AccountLockedError);
        expect((err as AccountLockedError).code).toBe(ErrorCodes.AUTH_ACCOUNT_LOCKED);
        expect((err as AccountLockedError).message).toContain('Account temporarily locked');
      }

      // Attempt 4 (even with correct password!): blocked while locked
      try {
        await loginUseCase.execute({ email: user.email, password: 'CorrectPassword!' });
        expect.unreachable('Should have thrown');
      } catch (err) {
        expect(err).toBeInstanceOf(AccountLockedError);
      }
    });
  });

  describe('RefreshTokenUseCase — Session Rotation & Reuse Detection', () => {
    it('rotates refresh token and returns new tokens', async () => {
      const user = await authRepo.createUser({
        email: 'session@test.com',
        passwordHash: 'hashed_Pass',
        firstName: 'Session',
        lastName: 'User',
        emailVerified: true,
      });

      const initialToken = 'initial_refresh_token';
      const initialHash = tokenService.hashRefreshToken(initialToken);
      const familyId = crypto.randomUUID();
      await authRepo.saveRefreshToken(user.id, initialHash, familyId, new Date(Date.now() + 86400000));

      const refreshUseCase = new RefreshTokenUseCase(authRepo, tokenService);
      const result = await refreshUseCase.execute({ refreshToken: initialToken });

      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
      expect(result.refreshToken).not.toBe(initialToken);
    });

    it('revokes entire token family when already-used token is re-submitted', async () => {
      const user = await authRepo.createUser({
        email: 'reuse@test.com',
        passwordHash: 'hashed_Pass',
        firstName: 'Reuse',
        lastName: 'User',
        emailVerified: true,
      });

      const stolenToken = 'stolen_refresh_token';
      const stolenHash = tokenService.hashRefreshToken(stolenToken);
      const familyId = crypto.randomUUID();
      await authRepo.saveRefreshToken(user.id, stolenHash, familyId, new Date(Date.now() + 86400000));

      const refreshUseCase = new RefreshTokenUseCase(authRepo, tokenService);

      // 1st use rotates it (marks stolenToken revoked)
      const newSession = await refreshUseCase.execute({ refreshToken: stolenToken });

      // Attacker tries to use the old stolenToken again:
      await expect(
        refreshUseCase.execute({ refreshToken: stolenToken }),
      ).rejects.toThrow(UnauthorizedError);

      // And the legitimate user's new token in that family is now also revoked for safety!
      await expect(
        refreshUseCase.execute({ refreshToken: newSession.refreshToken }),
      ).rejects.toThrow(UnauthorizedError);
    });
  });

  describe('ResetPasswordUseCase', () => {
    it('resets password, clears lockouts, and revokes all active sessions', async () => {
      const user = await authRepo.createUser({
        email: 'reset@test.com',
        passwordHash: 'hashed_OldPass',
        firstName: 'Reset',
        lastName: 'User',
        emailVerified: true,
      });

      // Save reset code
      const rawCode = '654321';
      const codeHash = crypto.createHash('sha256').update(rawCode).digest('hex');
      await authRepo.createPasswordResetCode(user.id, codeHash, new Date(Date.now() + 900000));

      const resetUseCase = new ResetPasswordUseCase(authRepo, hasher);
      const result = await resetUseCase.execute({
        email: user.email,
        code: rawCode,
        newPassword: 'BrandNewSecurePassword123!',
      });

      expect(result.message).toContain('Password has been reset successfully');

      const updatedUser = await authRepo.findUserById(user.id);
      expect(updatedUser?.passwordHash).toBe('hashed_BrandNewSecurePassword123!');
      expect(updatedUser?.failedLoginAttempts).toBe(0);
      expect(updatedUser?.lockedUntil).toBeNull();
    });
  });
});

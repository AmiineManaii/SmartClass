import { describe, it, expect, beforeEach } from 'vitest';
import { TotpService } from '../../src/modules/auth/infrastructure/totp.service.js';
import { Setup2FAUseCase } from '../../src/modules/auth/application/setup-2fa.use-case.js';
import { Verify2FAUseCase } from '../../src/modules/auth/application/verify-2fa.use-case.js';
import { Disable2FAUseCase } from '../../src/modules/auth/application/disable-2fa.use-case.js';
import { Authenticate2FAUseCase } from '../../src/modules/auth/application/authenticate-2fa.use-case.js';
import { LoginUseCase } from '../../src/modules/auth/application/login.use-case.js';
import { JoseTokenServiceAdapter } from '../../src/modules/auth/infrastructure/jose-token-service.adapter.js';
import {
  UserEntity,
  type Role,
  type UserStatus,
} from '../../src/modules/auth/domain/user.entity.js';
import type {
  AuthRepositoryPort,
  CreateUserParams,
  StoredPasswordResetCode,
  StoredRefreshToken,
  StoredVerificationCode,
} from '../../src/modules/auth/domain/auth-repository.port.js';
import type { PasswordHasherPort } from '../../src/modules/auth/domain/password-hasher.port.js';
import { AccountLockedError, UnauthorizedError } from '../../src/shared/errors/app-error.js';

class InMemory2FARepository implements AuthRepositoryPort {
  public users = new Map<string, UserEntity>();
  public secrets = new Map<
    string,
    { twoFactorSecret: string | null; twoFactorEnabled: boolean; twoFactorRecoveryCodes: string[] }
  >();
  public refreshTokens = new Map<string, StoredRefreshToken>();
  public auditLogs: Array<{ action: string; details: unknown }> = [];

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
      emailVerified: params.emailVerified ?? true,
      onboardingCompleted: true,
      failedLoginAttempts: 0,
      lockedUntil: null,
      twoFactorEnabled: false,
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
      twoFactorEnabled: boolean;
      twoFactorSecret: string | null;
      twoFactorRecoveryCodes: string[];
      failedLoginAttempts: number;
      lockedUntil: Date | null;
    }>,
  ): Promise<UserEntity> {
    const user = this.users.get(id);
    if (!user) throw new Error('User not found');

    const updated = new UserEntity({
      id: user.id,
      email: user.email,
      passwordHash: params.passwordHash ?? user.passwordHash,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      birthDate: user.birthDate,
      status: user.status,
      emailVerified: user.emailVerified,
      onboardingCompleted: user.onboardingCompleted,
      failedLoginAttempts: params.failedLoginAttempts ?? user.failedLoginAttempts,
      lockedUntil: params.lockedUntil !== undefined ? params.lockedUntil : user.lockedUntil,
      twoFactorEnabled: params.twoFactorEnabled !== undefined ? params.twoFactorEnabled : user.twoFactorEnabled,
      createdAt: user.createdAt,
      updatedAt: new Date(),
    });
    this.users.set(id, updated);

    if (params.twoFactorSecret !== undefined || params.twoFactorEnabled !== undefined || params.twoFactorRecoveryCodes !== undefined) {
      const existing = this.secrets.get(id) ?? {
        twoFactorSecret: null,
        twoFactorEnabled: false,
        twoFactorRecoveryCodes: [],
      };
      this.secrets.set(id, {
        twoFactorSecret: params.twoFactorSecret !== undefined ? params.twoFactorSecret : existing.twoFactorSecret,
        twoFactorEnabled: params.twoFactorEnabled !== undefined ? params.twoFactorEnabled : existing.twoFactorEnabled,
        twoFactorRecoveryCodes: params.twoFactorRecoveryCodes !== undefined ? params.twoFactorRecoveryCodes : existing.twoFactorRecoveryCodes,
      });
    }

    return updated;
  }

  public async getTwoFactorSecret(userId: string) {
    return this.secrets.get(userId) ?? {
      twoFactorSecret: null,
      twoFactorEnabled: false,
      twoFactorRecoveryCodes: [],
    };
  }

  public async saveAuditLog(params: { action: string; details?: Record<string, unknown> }) {
    this.auditLogs.push({ action: params.action, details: params.details });
  }

  public async getUserAuditLogs() {
    return [];
  }

  public async incrementFailedAttempts(userId: string, maxAttempts: number, lockoutMinutes: number) {
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

  public async resetFailedAttempts(userId: string) {
    await this.updateUser(userId, { failedLoginAttempts: 0, lockedUntil: null });
  }

  public async createVerificationCode() {}
  public async getLatestVerificationCode() { return null; }
  public async incrementVerificationAttempts() { return 1; }
  public async deleteVerificationCodes() {}
  public async createPasswordResetCode() {}
  public async getLatestPasswordResetCode() { return null; }
  public async incrementPasswordResetAttempts() { return 1; }
  public async markPasswordResetCodeUsed() {}
  public async saveRefreshToken(userId: string, tokenHash: string, familyId: string, expiresAt: Date) {
    this.refreshTokens.set(tokenHash, {
      id: crypto.randomUUID(),
      userId,
      tokenHash,
      familyId,
      isRevoked: false,
      expiresAt,
      createdAt: new Date(),
    });
  }
  public async findRefreshToken() { return null; }
  public async revokeRefreshToken() {}
  public async revokeFamily() {}
  public async revokeAllUserTokens() {}
}

class SimpleHasher implements PasswordHasherPort {
  public async hash(p: string) { return `hashed_${p}`; }
  public async verify(p: string, h: string) { return h === `hashed_${p}`; }
}

describe('2FA (Two-Factor Authentication / TOTP) End-to-End Suite', () => {
  let repo: InMemory2FARepository;
  let hasher: SimpleHasher;
  let tokenService: JoseTokenServiceAdapter;
  let totp: TotpService;
  let setup2FA: Setup2FAUseCase;
  let verify2FA: Verify2FAUseCase;
  let disable2FA: Disable2FAUseCase;
  let authenticate2FA: Authenticate2FAUseCase;
  let loginUseCase: LoginUseCase;

  beforeEach(() => {
    repo = new InMemory2FARepository();
    hasher = new SimpleHasher();
    tokenService = new JoseTokenServiceAdapter({
      jwtSecret: 'super-secret-key-that-is-at-least-32-chars-long!',
      accessExpiration: '15m',
    });
    totp = new TotpService();
    setup2FA = new Setup2FAUseCase(repo, totp);
    verify2FA = new Verify2FAUseCase(repo, totp);
    disable2FA = new Disable2FAUseCase(repo, hasher, totp);
    authenticate2FA = new Authenticate2FAUseCase(repo, tokenService, totp, 3, 1);
    loginUseCase = new LoginUseCase(repo, hasher, tokenService, 3, 1);
  });

  it('generates valid RFC 6238 TOTP codes and verifies them with clock drift tolerance', () => {
    const secret = totp.generateSecret();
    expect(secret).toMatch(/^[A-Z2-7]{20,}$/);

    const code = totp.generateCode(secret);
    expect(code).toMatch(/^\d{6}$/);

    // Immediate verification succeeds
    expect(totp.verifyCode(secret, code)).toBe(true);

    // Code from ±30s window succeeds
    const codePast = totp.generateCode(secret, Date.now() - 30000);
    expect(totp.verifyCode(secret, codePast)).toBe(true);

    // Bad code fails
    expect(totp.verifyCode(secret, '000000')).toBe(false);
  });

  it('runs complete 2FA lifecycle: Setup -> Verify -> Login with 2FA -> Disable', async () => {
    const user = await repo.createUser({
      email: 'student.2fa@smartclass.edu',
      passwordHash: 'hashed_Password123!',
      firstName: 'Student',
      lastName: 'Secure',
    });

    // 1. Initial login succeeds normally without 2FA
    const initLogin = await loginUseCase.execute({
      email: user.email,
      password: 'Password123!',
    });
    expect(initLogin.twoFactorRequired).toBe(false);

    // 2. Setup 2FA
    const setupResult = await setup2FA.execute(user.id);
    expect(setupResult.secret).toBeDefined();
    expect(setupResult.otpAuthUrl).toContain('otpauth://totp/');
    expect(setupResult.qrCodeDataUrl).toMatch(/^data:image\/png;base64,/);
    expect(setupResult.recoveryCodes.length).toBe(8);

    // 3. Verify with wrong code fails
    await expect(
      verify2FA.execute({ userId: user.id, code: '999999' }),
    ).rejects.toThrow(UnauthorizedError);

    // 4. Verify with actual generated TOTP code activates 2FA
    const validCode = totp.generateCode(setupResult.secret);
    const verifyResult = await verify2FA.execute({ userId: user.id, code: validCode });
    expect(verifyResult.success).toBe(true);

    const updatedUser = await repo.findUserById(user.id);
    expect(updatedUser?.twoFactorEnabled).toBe(true);

    // 5. Subsequent password login now returns 2FA CHALLENGE
    const challengeLogin = await loginUseCase.execute({
      email: user.email,
      password: 'Password123!',
    });
    expect(challengeLogin.twoFactorRequired).toBe(true);
    if (!challengeLogin.twoFactorRequired) throw new Error('Expected 2FA challenge');
    expect(challengeLogin.tempToken).toBeDefined();

    // 6. Complete login with Authenticate2FA
    const currentCode = totp.generateCode(setupResult.secret);
    const authResult = await authenticate2FA.execute({
      tempToken: challengeLogin.tempToken,
      code: currentCode,
    });
    expect(authResult.accessToken).toBeDefined();
    expect(authResult.refreshToken).toBeDefined();
    expect(authResult.user.email).toBe(user.email);

    // 7. Disable 2FA with current password or code
    const disableResult = await disable2FA.execute({
      userId: user.id,
      password: 'Password123!',
    });
    expect(disableResult.success).toBe(true);

    const disabledUser = await repo.findUserById(user.id);
    expect(disabledUser?.twoFactorEnabled).toBe(false);
  });

  it('allows emergency login using one-time recovery code and consumes it', async () => {
    const user = await repo.createUser({
      email: 'backup.user@smartclass.edu',
      passwordHash: 'hashed_Password123!',
      firstName: 'Backup',
      lastName: 'User',
    });

    const setupResult = await setup2FA.execute(user.id);
    const validCode = totp.generateCode(setupResult.secret);
    await verify2FA.execute({ userId: user.id, code: validCode });

    // Login triggers 2FA
    const loginRes = await loginUseCase.execute({
      email: user.email,
      password: 'Password123!',
    });
    expect(loginRes.twoFactorRequired).toBe(true);
    if (!loginRes.twoFactorRequired) throw new Error();

    // Use recovery code instead of TOTP
    const firstRecoveryCode = setupResult.recoveryCodes[0]!;
    const authResult = await authenticate2FA.execute({
      tempToken: loginRes.tempToken,
      code: firstRecoveryCode,
    });
    expect(authResult.accessToken).toBeDefined();

    // Re-attempt with same recovery code should now fail (one-time use)
    const loginRes2 = await loginUseCase.execute({
      email: user.email,
      password: 'Password123!',
    });
    if (!loginRes2.twoFactorRequired) throw new Error();

    await expect(
      authenticate2FA.execute({
        tempToken: loginRes2.tempToken,
        code: firstRecoveryCode,
      }),
    ).rejects.toThrow(UnauthorizedError);
  });

  it('locks account for 1 minute after 3 failed 2FA attempts', async () => {
    const user = await repo.createUser({
      email: 'lockout.2fa@smartclass.edu',
      passwordHash: 'hashed_Password123!',
      firstName: 'Lockout',
      lastName: 'User',
    });

    const setupResult = await setup2FA.execute(user.id);
    await verify2FA.execute({
      userId: user.id,
      code: totp.generateCode(setupResult.secret),
    });

    const loginRes = await loginUseCase.execute({
      email: user.email,
      password: 'Password123!',
    });
    if (!loginRes.twoFactorRequired) throw new Error();

    // Attempt 1 fail
    await expect(
      authenticate2FA.execute({ tempToken: loginRes.tempToken, code: '000001' }),
    ).rejects.toThrow(UnauthorizedError);

    // Attempt 2 fail
    await expect(
      authenticate2FA.execute({ tempToken: loginRes.tempToken, code: '000002' }),
    ).rejects.toThrow(UnauthorizedError);

    // Attempt 3 fail -> Account locked for 1 minute!
    await expect(
      authenticate2FA.execute({ tempToken: loginRes.tempToken, code: '000003' }),
    ).rejects.toThrow(AccountLockedError);
  });
});

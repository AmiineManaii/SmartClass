import { describe, it, expect } from 'vitest';
import { CheckEmailUseCase } from '../../src/modules/auth/application/check-email.use-case.js';
import { UserEntity } from '../../src/modules/auth/domain/user.entity.js';
import type { AuthRepositoryPort } from '../../src/modules/auth/domain/auth-repository.port.js';

const notImplemented = (): never => {
  throw new Error('not implemented in this fake');
};

const makeUser = (email: string): UserEntity =>
  new UserEntity({
    id: 'user-1',
    email,
    passwordHash: 'hash',
    firstName: 'Salma',
    lastName: 'Benali',
    role: 'STUDENT',
    birthDate: null,
    status: 'ACTIVE',
    emailVerified: false,
    onboardingCompleted: false,
    failedLoginAttempts: 0,
    lockedUntil: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  });

const makeRepo = (existing: UserEntity | null): AuthRepositoryPort => ({
  findUserByEmail: async (email: string) =>
    existing && existing.email.toLowerCase() === email.toLowerCase() ? existing : null,
  findUserById: async () => notImplemented(),
  createUser: async () => notImplemented(),
  updateUser: async () => notImplemented(),
  incrementFailedAttempts: async () => notImplemented(),
  resetFailedAttempts: async () => notImplemented(),
  createVerificationCode: async () => notImplemented(),
  getLatestVerificationCode: async () => notImplemented(),
  incrementVerificationAttempts: async () => notImplemented(),
  deleteVerificationCodes: async () => notImplemented(),
  createPasswordResetCode: async () => notImplemented(),
  getLatestPasswordResetCode: async () => notImplemented(),
  incrementPasswordResetAttempts: async () => notImplemented(),
  markPasswordResetCodeUsed: async () => notImplemented(),
  saveRefreshToken: async () => notImplemented(),
  findRefreshToken: async () => notImplemented(),
  revokeRefreshToken: async () => notImplemented(),
  revokeFamily: async () => notImplemented(),
  revokeAllUserTokens: async () => notImplemented(),
});

describe('Unit: CheckEmailUseCase', () => {
  it('returns available=true when no account uses the email', async () => {
    const useCase = new CheckEmailUseCase(makeRepo(null));

    await expect(useCase.execute('new.user@test.com')).resolves.toEqual({
      available: true,
      email: 'new.user@test.com',
    });
  });

  it('returns available=false when an account already uses the email', async () => {
    const useCase = new CheckEmailUseCase(makeRepo(makeUser('salma@test.com')));

    await expect(useCase.execute('salma@test.com')).resolves.toEqual({
      available: false,
      email: 'salma@test.com',
    });
  });

  it('matches emails case-insensitively like register does', async () => {
    const useCase = new CheckEmailUseCase(makeRepo(makeUser('Salma@Test.com')));

    const result = await useCase.execute('salma@test.com');
    expect(result.available).toBe(false);
  });
});

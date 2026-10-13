import { describe, it, expect } from 'vitest';
import { RegisterUseCase } from '../../src/modules/auth/application/register.use-case.js';
import { SetMyRoleUseCase } from '../../src/modules/users/application/set-my-role.use-case.js';
import { SetUserRoleUseCase } from '../../src/modules/users/application/set-user-role.use-case.js';
import { UserEntity } from '../../src/modules/auth/domain/user.entity.js';
import type {
  AuthRepositoryPort,
  CreateUserParams,
} from '../../src/modules/auth/domain/auth-repository.port.js';
import type { PasswordHasherPort } from '../../src/modules/auth/domain/password-hasher.port.js';
import type { TokenServicePort } from '../../src/modules/auth/domain/token-service.port.js';
import type { EmailPort } from '../../src/modules/auth/domain/email.port.js';
import { ErrorCodes } from '../../src/shared/errors/error-codes.js';

const baseProps = {
  passwordHash: 'hash',
  firstName: 'Test',
  lastName: 'User',
  birthDate: null,
  status: 'ACTIVE' as const,
  emailVerified: true,
  onboardingCompleted: true,
  failedLoginAttempts: 0,
  lockedUntil: null,
  createdAt: new Date(),
  updatedAt: new Date(),
};

const makeUser = (overrides: Partial<{ id: string; email: string; role: 'TEACHER' | 'STUDENT' | 'ADMIN' | null }>) =>
  new UserEntity({
    ...baseProps,
    id: overrides.id ?? 'user-1',
    email: overrides.email ?? 'user@test.com',
    role: overrides.role ?? null,
  });

class FakeAuthRepository implements AuthRepositoryPort {
  public users = new Map<string, UserEntity>();
  public revoked: string[] = [];
  public savedTokens = 0;

  async findUserByEmail(email: string): Promise<UserEntity | null> {
    for (const user of this.users.values()) {
      if (user.email.toLowerCase() === email.toLowerCase()) return user;
    }
    return null;
  }

  async findUserById(id: string): Promise<UserEntity | null> {
    return this.users.get(id) ?? null;
  }

  async createUser(params: CreateUserParams): Promise<UserEntity> {
    const user = makeUser({
      id: `user-${this.users.size + 1}`,
      email: params.email,
      role: params.role ?? null,
    });
    this.users.set(user.id, user);
    return user;
  }

  async updateUser(id: string, params: { role?: 'TEACHER' | 'STUDENT' | 'ADMIN' | null }): Promise<UserEntity> {
    const current = this.users.get(id);
    if (!current) throw new Error('missing user in fake');
    const updated = makeUser({
      id: current.id,
      email: current.email,
      role: params.role !== undefined ? params.role : current.role,
    });
    this.users.set(id, updated);
    return updated;
  }

  async incrementFailedAttempts(): Promise<{ failedAttempts: number; isLocked: boolean; lockedUntil: Date | null }> {
    throw new Error('not implemented in fake');
  }
  async resetFailedAttempts(): Promise<void> {
    throw new Error('not implemented in fake');
  }
  async createVerificationCode(): Promise<void> {
    return;
  }
  async getLatestVerificationCode(): Promise<null> {
    return null;
  }
  async incrementVerificationAttempts(): Promise<number> {
    throw new Error('not implemented in fake');
  }
  async deleteVerificationCodes(): Promise<void> {}
  async createPasswordResetCode(): Promise<void> {
    throw new Error('not implemented in fake');
  }
  async getLatestPasswordResetCode(): Promise<null> {
    return null;
  }
  async incrementPasswordResetAttempts(): Promise<number> {
    throw new Error('not implemented in fake');
  }
  async markPasswordResetCodeUsed(): Promise<void> {
    throw new Error('not implemented in fake');
  }
  async saveRefreshToken(): Promise<void> {
    this.savedTokens += 1;
  }
  async findRefreshToken(): Promise<null> {
    return null;
  }
  async revokeRefreshToken(): Promise<void> {
    throw new Error('not implemented in fake');
  }
  async revokeFamily(): Promise<void> {
    throw new Error('not implemented in fake');
  }
  async revokeAllUserTokens(userId: string): Promise<void> {
    this.revoked.push(userId);
  }
}

const fakeHasher: PasswordHasherPort = {
  hash: async (password: string) => `hashed:${password}`,
  verify: async () => true,
};

const fakeTokens: TokenServicePort = {
  generateAccessToken: async (payload) => ({
    token: `access-${payload.sub}-${payload.role ?? 'none'}`,
    expiresIn: 900,
  }),
  generateRefreshToken: () => 'raw-refresh-token',
  verifyAccessToken: async () => {
    throw new Error('not implemented in fake');
  },
  hashRefreshToken: (token: string) => `hash:${token}`,
};

const fakeEmail: EmailPort = {
  sendVerificationEmail: async () => {},
  sendPasswordResetEmail: async () => {},
};

describe('Unit: RegisterUseCase ADMIN guard', () => {
  it('rejects ADMIN role at public registration with 403', async () => {
    const useCase = new RegisterUseCase(
      new FakeAuthRepository(),
      fakeHasher,
      fakeEmail,
    );

    await expect(
      useCase.execute({
        email: 'evil@test.com',
        password: 'StrongPass123!',
        firstName: 'Evil',
        lastName: 'Admin',
        role: 'ADMIN',
      }),
    ).rejects.toMatchObject({ statusCode: 403, code: ErrorCodes.FORBIDDEN });
  });

  it('still accepts TEACHER and STUDENT roles', async () => {
    const repo = new FakeAuthRepository();
    const useCase = new RegisterUseCase(repo, fakeHasher, fakeEmail);

    for (const role of ['TEACHER', 'STUDENT'] as const) {
      const result = await useCase.execute({
        email: `${role.toLowerCase()}@test.com`,
        password: 'StrongPass123!',
        firstName: 'Test',
        lastName: 'User',
        role,
      });
      expect(result.user.role).toBe(role);
    }
  });

  it('leaves role null when omitted so onboarding can assign it once (RG1)', async () => {
    const repo = new FakeAuthRepository();
    const useCase = new RegisterUseCase(repo, fakeHasher, fakeEmail);

    const result = await useCase.execute({
      email: 'norole@test.com',
      password: 'StrongPass123!',
      firstName: 'Test',
      lastName: 'User',
    });
    expect(result.user.role).toBeNull();
  });
});

describe('Unit: SetMyRoleUseCase', () => {
  it('assigns TEACHER once and issues a fresh token pair', async () => {
    const repo = new FakeAuthRepository();
    repo.users.set('u1', makeUser({ id: 'u1', role: null }));
    const useCase = new SetMyRoleUseCase(repo, fakeTokens);

    const result = await useCase.execute('u1', 'TEACHER');

    expect(result.user.role).toBe('TEACHER');
    expect(result.accessToken).toContain('TEACHER');
    expect(result.refreshToken).toBe('raw-refresh-token');
    expect(repo.revoked).toEqual(['u1']);
    expect(repo.savedTokens).toBe(1);
  });

  it('rejects a second assignment with ROLE_ALREADY_ASSIGNED', async () => {
    const repo = new FakeAuthRepository();
    repo.users.set('u1', makeUser({ id: 'u1', role: 'STUDENT' }));
    const useCase = new SetMyRoleUseCase(repo, fakeTokens);

    await expect(useCase.execute('u1', 'TEACHER')).rejects.toMatchObject({
      statusCode: 409,
      code: ErrorCodes.ROLE_ALREADY_ASSIGNED,
    });
  });

  it('rejects ADMIN self-assignment with 403 even for a role-less account', async () => {
    const repo = new FakeAuthRepository();
    repo.users.set('u1', makeUser({ id: 'u1', role: null }));
    const useCase = new SetMyRoleUseCase(repo, fakeTokens);

    await expect(useCase.execute('u1', 'ADMIN')).rejects.toMatchObject({
      statusCode: 403,
      code: ErrorCodes.FORBIDDEN,
    });
  });

  it('returns 404 for an unknown user', async () => {
    const useCase = new SetMyRoleUseCase(new FakeAuthRepository(), fakeTokens);

    await expect(useCase.execute('ghost', 'STUDENT')).rejects.toMatchObject({
      statusCode: 404,
    });
  });
});

describe('Unit: SetUserRoleUseCase', () => {
  it('lets an admin change another user role and revokes their sessions', async () => {
    const repo = new FakeAuthRepository();
    repo.users.set('target', makeUser({ id: 'target', role: 'STUDENT' }));
    const useCase = new SetUserRoleUseCase(repo);

    const result = await useCase.execute('admin-1', 'target', 'ADMIN');

    expect(result.user.role).toBe('ADMIN');
    expect(repo.revoked).toEqual(['target']);
  });

  it('forbids changing your own role', async () => {
    const repo = new FakeAuthRepository();
    repo.users.set('admin-1', makeUser({ id: 'admin-1', role: 'ADMIN' }));
    const useCase = new SetUserRoleUseCase(repo);

    await expect(useCase.execute('admin-1', 'admin-1', 'STUDENT')).rejects.toMatchObject({
      statusCode: 403,
      code: ErrorCodes.FORBIDDEN,
    });
  });

  it('returns 404 for an unknown target', async () => {
    const useCase = new SetUserRoleUseCase(new FakeAuthRepository());

    await expect(useCase.execute('admin-1', 'ghost', 'TEACHER')).rejects.toMatchObject({
      statusCode: 404,
    });
  });
});

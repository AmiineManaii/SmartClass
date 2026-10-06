import type { Role, UserEntity, UserStatus } from './user.entity.js';

export interface CreateUserParams {
  email: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  role?: Role | null;
  status?: UserStatus;
  emailVerified?: boolean;
}

export interface StoredRefreshToken {
  id: string;
  userId: string;
  tokenHash: string;
  familyId: string;
  isRevoked: boolean;
  expiresAt: Date;
  createdAt: Date;
}

export interface StoredVerificationCode {
  id: string;
  userId: string;
  codeHash: string;
  expiresAt: Date;
  attempts: number;
}

export interface StoredPasswordResetCode {
  id: string;
  userId: string;
  codeHash: string;
  expiresAt: Date;
  usedAt: Date | null;
  attempts: number;
}

export interface AuthRepositoryPort {
  findUserByEmail(email: string): Promise<UserEntity | null>;
  findUserById(id: string): Promise<UserEntity | null>;
  createUser(params: CreateUserParams): Promise<UserEntity>;
  updateUser(id: string, params: {
    passwordHash?: string;
    firstName?: string;
    lastName?: string;
    role?: Role | null;
    birthDate?: Date | null;
    status?: UserStatus;
    emailVerified?: boolean;
    onboardingCompleted?: boolean;
    failedLoginAttempts?: number;
    lockedUntil?: Date | null;
  }): Promise<UserEntity>;

  incrementFailedAttempts(
    userId: string,
    maxAttempts: number,
    lockoutDurationMinutes: number,
  ): Promise<{ failedAttempts: number; isLocked: boolean; lockedUntil: Date | null }>;
  resetFailedAttempts(userId: string): Promise<void>;

  // Email verification codes
  createVerificationCode(userId: string, codeHash: string, expiresAt: Date): Promise<void>;
  getLatestVerificationCode(userId: string): Promise<StoredVerificationCode | null>;
  incrementVerificationAttempts(codeId: string): Promise<number>;
  deleteVerificationCodes(userId: string): Promise<void>;

  // Password reset codes
  createPasswordResetCode(userId: string, codeHash: string, expiresAt: Date): Promise<void>;
  getLatestPasswordResetCode(userId: string): Promise<StoredPasswordResetCode | null>;
  incrementPasswordResetAttempts(codeId: string): Promise<number>;
  markPasswordResetCodeUsed(codeId: string): Promise<void>;

  // Refresh tokens & session family
  saveRefreshToken(userId: string, tokenHash: string, familyId: string, expiresAt: Date): Promise<void>;
  findRefreshToken(tokenHash: string): Promise<StoredRefreshToken | null>;
  revokeRefreshToken(id: string): Promise<void>;
  revokeFamily(familyId: string): Promise<void>;
  revokeAllUserTokens(userId: string): Promise<void>;
}

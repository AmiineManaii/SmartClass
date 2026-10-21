import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import {
  UserEntity,
  type Role,
  type UserStatus,
} from '../domain/user.entity.js';
import type {
  AuthRepositoryPort,
  CreateUserParams,
  StoredPasswordResetCode,
  StoredRefreshToken,
  StoredVerificationCode,
} from '../domain/auth-repository.port.js';

export class PrismaAuthRepositoryAdapter implements AuthRepositoryPort {
  private get prisma() {
    return getPrismaClient();
  }

  private toDomain(raw: {
    id: string;
    email: string;
    passwordHash: string;
    firstName: string;
    lastName: string;
    role: string | null;
    teacherApprovalStatus?: string | null;
    birthDate: Date | null;
    status: string;
    emailVerified: boolean;
    onboardingCompleted: boolean;
    failedLoginAttempts: number;
    lockedUntil: Date | null;
    twoFactorEnabled?: boolean;
    createdAt: Date;
    updatedAt: Date;
  }): UserEntity {
    return new UserEntity({
      id: raw.id,
      email: raw.email,
      passwordHash: raw.passwordHash,
      firstName: raw.firstName,
      lastName: raw.lastName,
      role: (raw.role as Role) || null,
      teacherApprovalStatus: (raw.teacherApprovalStatus as any) || null,
      birthDate: raw.birthDate,
      status: (raw.status as UserStatus) || 'ACTIVE',
      emailVerified: raw.emailVerified,
      onboardingCompleted: raw.onboardingCompleted,
      failedLoginAttempts: raw.failedLoginAttempts,
      lockedUntil: raw.lockedUntil,
      twoFactorEnabled: raw.twoFactorEnabled ?? false,
      createdAt: raw.createdAt,
      updatedAt: raw.updatedAt,
    });
  }

  public async findUserByEmail(email: string): Promise<UserEntity | null> {
    const raw = await this.prisma.user.findUnique({
      where: { email: email.toLowerCase().trim() },
    });
    return raw ? this.toDomain(raw) : null;
  }

  public async findUserById(id: string): Promise<UserEntity | null> {
    const raw = await this.prisma.user.findUnique({
      where: { id },
    });
    return raw ? this.toDomain(raw) : null;
  }

  public async createUser(params: CreateUserParams): Promise<UserEntity> {
    const raw = await this.prisma.user.create({
      data: {
        email: params.email.toLowerCase().trim(),
        passwordHash: params.passwordHash,
        firstName: params.firstName.trim(),
        lastName: params.lastName.trim(),
        role: params.role ?? null,
        teacherApprovalStatus: params.teacherApprovalStatus ?? (params.role === 'TEACHER' ? 'PENDING' : null),
        status: params.status ?? 'ACTIVE',
        emailVerified: params.emailVerified ?? false,
      },
    });
    return this.toDomain(raw);
  }

  public async updateUser(
    id: string,
    params: {
      passwordHash?: string;
      firstName?: string;
      lastName?: string;
      role?: Role | null;
      teacherApprovalStatus?: any;
      birthDate?: Date | null;
      status?: UserStatus;
      emailVerified?: boolean;
      onboardingCompleted?: boolean;
      failedLoginAttempts?: number;
      lockedUntil?: Date | null;
      twoFactorEnabled?: boolean;
      twoFactorSecret?: string | null;
      twoFactorRecoveryCodes?: string[];
    },
  ): Promise<UserEntity> {
    const raw = await this.prisma.user.update({
      where: { id },
      data: params,
    });
    return this.toDomain(raw);
  }

  public async getTwoFactorSecret(userId: string): Promise<{
    twoFactorSecret: string | null;
    twoFactorEnabled: boolean;
    twoFactorRecoveryCodes: string[];
  } | null> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        twoFactorSecret: true,
        twoFactorEnabled: true,
        twoFactorRecoveryCodes: true,
      },
    });
    if (!user) return null;
    return {
      twoFactorSecret: user.twoFactorSecret,
      twoFactorEnabled: user.twoFactorEnabled,
      twoFactorRecoveryCodes: user.twoFactorRecoveryCodes,
    };
  }

  public async saveAuditLog(params: {
    userId?: string;
    action: string;
    targetType: string;
    targetId?: string;
    details?: Record<string, unknown>;
  }): Promise<void> {
    await this.prisma.auditLog.create({
      data: {
        userId: params.userId ?? null,
        action: params.action,
        targetType: params.targetType,
        targetId: params.targetId ?? null,
        details: (params.details ?? {}) as any,
      },
    });
  }

  public async getUserAuditLogs(
    userId: string,
    limit: number = 20,
  ): Promise<Array<{
    id: string;
    action: string;
    targetType: string;
    targetId: string | null;
    details: unknown;
    createdAt: Date;
  }>> {
    return this.prisma.auditLog.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      select: {
        id: true,
        action: true,
        targetType: true,
        targetId: true,
        details: true,
        createdAt: true,
      },
    });
  }

  public async incrementFailedAttempts(
    userId: string,
    maxAttempts: number,
    lockoutDurationMinutes: number,
  ): Promise<{ failedAttempts: number; isLocked: boolean; lockedUntil: Date | null }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { failedLoginAttempts: true },
    });

    const newAttempts = (user?.failedLoginAttempts ?? 0) + 1;

    if (newAttempts >= maxAttempts) {
      const lockedUntil = new Date(Date.now() + lockoutDurationMinutes * 60 * 1000);
      await this.prisma.user.update({
        where: { id: userId },
        data: {
          failedLoginAttempts: newAttempts,
          lockedUntil,
        },
      });
      return { failedAttempts: newAttempts, isLocked: true, lockedUntil };
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        failedLoginAttempts: newAttempts,
      },
    });

    return { failedAttempts: newAttempts, isLocked: false, lockedUntil: null };
  }

  public async resetFailedAttempts(userId: string): Promise<void> {
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        failedLoginAttempts: 0,
        lockedUntil: null,
      },
    });
  }

  public async createVerificationCode(
    userId: string,
    codeHash: string,
    expiresAt: Date,
  ): Promise<void> {
    // Invalidate previous active codes for this user
    await this.deleteVerificationCodes(userId);

    await this.prisma.emailVerificationCode.create({
      data: {
        userId,
        codeHash,
        expiresAt,
      },
    });
  }

  public async getLatestVerificationCode(
    userId: string,
  ): Promise<StoredVerificationCode | null> {
    const raw = await this.prisma.emailVerificationCode.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    if (!raw) return null;

    return {
      id: raw.id,
      userId: raw.userId,
      codeHash: raw.codeHash,
      expiresAt: raw.expiresAt,
      attempts: raw.attempts,
    };
  }

  public async incrementVerificationAttempts(codeId: string): Promise<number> {
    const updated = await this.prisma.emailVerificationCode.update({
      where: { id: codeId },
      data: { attempts: { increment: 1 } },
    });
    return updated.attempts;
  }

  public async deleteVerificationCodes(userId: string): Promise<void> {
    await this.prisma.emailVerificationCode.deleteMany({
      where: { userId },
    });
  }

  public async createPasswordResetCode(
    userId: string,
    codeHash: string,
    expiresAt: Date,
  ): Promise<void> {
    await this.prisma.passwordResetCode.create({
      data: {
        userId,
        codeHash,
        expiresAt,
      },
    });
  }

  public async getLatestPasswordResetCode(
    userId: string,
  ): Promise<StoredPasswordResetCode | null> {
    const raw = await this.prisma.passwordResetCode.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    if (!raw) return null;

    return {
      id: raw.id,
      userId: raw.userId,
      codeHash: raw.codeHash,
      expiresAt: raw.expiresAt,
      usedAt: raw.usedAt,
      attempts: raw.attempts,
    };
  }

  public async incrementPasswordResetAttempts(codeId: string): Promise<number> {
    const updated = await this.prisma.passwordResetCode.update({
      where: { id: codeId },
      data: { attempts: { increment: 1 } },
    });
    return updated.attempts;
  }

  public async markPasswordResetCodeUsed(codeId: string): Promise<void> {
    await this.prisma.passwordResetCode.update({
      where: { id: codeId },
      data: { usedAt: new Date() },
    });
  }

  public async saveRefreshToken(
    userId: string,
    tokenHash: string,
    familyId: string,
    expiresAt: Date,
  ): Promise<void> {
    await this.prisma.refreshToken.create({
      data: {
        userId,
        tokenHash,
        familyId,
        expiresAt,
      },
    });
  }

  public async findRefreshToken(tokenHash: string): Promise<StoredRefreshToken | null> {
    const raw = await this.prisma.refreshToken.findUnique({
      where: { tokenHash },
    });

    if (!raw) return null;

    return {
      id: raw.id,
      userId: raw.userId,
      tokenHash: raw.tokenHash,
      familyId: raw.familyId,
      isRevoked: raw.isRevoked,
      expiresAt: raw.expiresAt,
      createdAt: raw.createdAt,
    };
  }

  public async revokeRefreshToken(id: string): Promise<void> {
    await this.prisma.refreshToken.update({
      where: { id },
      data: { isRevoked: true },
    });
  }

  public async revokeFamily(familyId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { familyId },
      data: { isRevoked: true },
    });
  }

  public async revokeAllUserTokens(userId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { userId },
      data: { isRevoked: true },
    });
  }
}

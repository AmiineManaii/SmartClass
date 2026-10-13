import crypto from 'node:crypto';
import type {
  AuthRepositoryPort,
  SafeUser,
  TokenServicePort,
} from '../../auth/index.js';
import {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export type AssignableRole = 'TEACHER' | 'STUDENT';

export interface SetMyRoleResult {
  message: string;
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: SafeUser;
}

export class SetMyRoleUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly tokenService: TokenServicePort,
    private readonly refreshExpirationDays = 7,
  ) {}

  public async execute(userId: string, role: string): Promise<SetMyRoleResult> {
    const user = await this.authRepository.findUserById(userId);
    if (!user) {
      throw new NotFoundError('User account not found');
    }

    // ADMIN is never self-assignable (provisioned by seed or by an admin):
    // enforced here, not only by Zod, so the 403 survives any caller.
    const assignableRole = assertAssignableRole(role);

    // RG1: a role is assigned exactly once — onboarding cannot overwrite it.
    if (user.role !== null) {
      throw new ConflictError(
        'Account role has already been assigned and cannot be changed here',
        ErrorCodes.ROLE_ALREADY_ASSIGNED,
      );
    }

    const updatedUser = await this.authRepository.updateUser(userId, { role: assignableRole });

    // Old sessions carry the previous (empty) role: revoke everything and
    // issue a fresh pair embedding the new role.
    await this.authRepository.revokeAllUserTokens(userId);

    const { token: accessToken, expiresIn } = await this.tokenService.generateAccessToken({
      sub: updatedUser.id,
      email: updatedUser.email,
      role: updatedUser.role,
      status: updatedUser.status,
    });

    const rawRefreshToken = this.tokenService.generateRefreshToken();
    const tokenHash = this.tokenService.hashRefreshToken(rawRefreshToken);
    const familyId = crypto.randomUUID();
    const refreshExpiresAt = new Date(Date.now() + this.refreshExpirationDays * 24 * 60 * 60 * 1000);

    await this.authRepository.saveRefreshToken(userId, tokenHash, familyId, refreshExpiresAt);

    return {
      message: 'Account role assigned successfully',
      accessToken,
      refreshToken: rawRefreshToken,
      expiresIn,
      user: updatedUser.toSafeUser(),
    };
  }
}

export const assertAssignableRole = (role: string): AssignableRole => {
  if (role !== 'TEACHER' && role !== 'STUDENT') {
    // ADMIN is never self-assignable: provisioned by seed or by an admin.
    throw new ForbiddenError(
      'Administrator accounts must be provisioned by an existing administrator',
    );
  }
  return role;
};

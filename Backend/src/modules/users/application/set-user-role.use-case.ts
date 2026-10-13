import type { AuthRepositoryPort, Role, SafeUser } from '../../auth/index.js';
import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';

export interface SetUserRoleResult {
  message: string;
  user: SafeUser;
}

export class SetUserRoleUseCase {
  constructor(private readonly authRepository: AuthRepositoryPort) {}

  public async execute(
    actorId: string,
    targetId: string,
    role: Role,
  ): Promise<SetUserRoleResult> {
    // Nobody promotes or demotes themselves through this endpoint —
    // self role changes go through PATCH /users/me/role (once only).
    if (actorId === targetId) {
      throw new ForbiddenError('You cannot change your own role through this endpoint');
    }

    const target = await this.authRepository.findUserById(targetId);
    if (!target) {
      throw new NotFoundError('User account not found');
    }

    const updatedUser = await this.authRepository.updateUser(targetId, { role });

    // Outstanding sessions embed the previous role: force re-login so the
    // new role propagates to freshly minted tokens.
    await this.authRepository.revokeAllUserTokens(targetId);

    return {
      message: 'User role updated successfully',
      user: updatedUser.toSafeUser(),
    };
  }
}

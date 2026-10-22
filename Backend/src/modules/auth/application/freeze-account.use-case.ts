import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import { NotFoundError } from '../../../shared/errors/app-error.js';

export interface FreezeAccountResult {
  success: boolean;
  message: string;
}

export class FreezeAccountUseCase {
  constructor(private readonly authRepository: AuthRepositoryPort) {}

  public async execute(userId: string): Promise<FreezeAccountResult> {
    const user = await this.authRepository.findUserById(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    await this.authRepository.updateUser(userId, { status: 'SUSPENDED' });
    await this.authRepository.revokeAllUserTokens(userId);

    if (typeof this.authRepository.saveAuditLog === 'function') {
      await this.authRepository.saveAuditLog({
        userId,
        action: 'AUTH_ACCOUNT_FROZEN',
        targetType: 'USER',
        targetId: userId,
        details: { frozenAt: new Date().toISOString() },
      });
    }

    return {
      success: true,
      message: 'Compte temporairement mis en veille. Reconnexion possible à tout moment.',
    };
  }
}

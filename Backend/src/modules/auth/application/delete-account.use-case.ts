import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { PasswordHasherPort } from '../domain/password-hasher.port.js';
import { NotFoundError, UnauthorizedError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export interface DeleteAccountResult {
  success: boolean;
  message: string;
}

export class DeleteAccountUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly passwordHasher: PasswordHasherPort,
  ) {}

  public async execute(userId: string, passwordConfirmation: string): Promise<DeleteAccountResult> {
    const user = await this.authRepository.findUserById(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    const isMatch = await this.passwordHasher.verify(passwordConfirmation, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedError(
        'Mot de passe incorrect pour la confirmation de suppression.',
        ErrorCodes.AUTH_INVALID_CREDENTIALS,
      );
    }

    if (typeof this.authRepository.saveAuditLog === 'function') {
      await this.authRepository.saveAuditLog({
        userId,
        action: 'AUTH_ACCOUNT_DELETED',
        targetType: 'USER',
        targetId: userId,
        details: { email: user.email, deletedAt: new Date().toISOString() },
      });
    }

    await this.authRepository.deleteUser(userId);

    return {
      success: true,
      message: 'Compte définitivement supprimé conformément à l\'article 17 RGPD.',
    };
  }
}

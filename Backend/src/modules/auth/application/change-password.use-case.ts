import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { PasswordHasherPort } from '../domain/password-hasher.port.js';
import { BadRequestError, NotFoundError } from '../../../shared/errors/app-error.js';

export interface ChangePasswordDTO {
  userId: string;
  currentPassword: string;
  newPassword: string;
  ipAddress?: string;
}

export interface ChangePasswordResult {
  message: string;
}

export class ChangePasswordUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly passwordHasher: PasswordHasherPort,
  ) {}

  public async execute(dto: ChangePasswordDTO): Promise<ChangePasswordResult> {
    const user = await this.authRepository.findUserById(dto.userId);
    if (!user) {
      throw new NotFoundError('Compte utilisateur introuvable');
    }

    const isCurrentValid = await this.passwordHasher.verify(user.passwordHash, dto.currentPassword);
    if (!isCurrentValid) {
      throw new BadRequestError('Le mot de passe actuel est incorrect.', [
        { path: 'currentPassword', message: 'Mot de passe actuel incorrect' },
      ]);
    }

    if (dto.newPassword.length < 8) {
      throw new BadRequestError('Le nouveau mot de passe doit comporter au moins 8 caractères.', [
        { path: 'newPassword', message: 'Longueur minimale : 8 caractères' },
      ]);
    }

    const newHash = await this.passwordHasher.hash(dto.newPassword);

    await this.authRepository.updateUser(user.id, {
      passwordHash: newHash,
      failedLoginAttempts: 0,
      lockedUntil: null,
    });

    await this.authRepository.saveAuditLog({
      userId: user.id,
      action: 'AUTH_PASSWORD_CHANGED',
      targetType: 'User',
      targetId: user.id,
      details: {
        ipAddress: dto.ipAddress ?? 'unknown',
        timestamp: new Date().toISOString(),
      },
    });

    return {
      message: 'Mot de passe mis à jour avec succès.',
    };
  }
}

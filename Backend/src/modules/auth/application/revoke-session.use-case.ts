import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import { NotFoundError } from '../../../shared/errors/app-error.js';

export class RevokeSessionUseCase {
  constructor(private readonly authRepository: AuthRepositoryPort) {}

  public async execute(userId: string, sessionId: string): Promise<{ message: string }> {
    const success = await this.authRepository.revokeUserSessionById(userId, sessionId);
    if (!success) {
      throw new NotFoundError('Session introuvable ou déjà révoquée.');
    }

    await this.authRepository.saveAuditLog({
      userId,
      action: 'AUTH_SESSION_REVOKED',
      targetType: 'Session',
      targetId: sessionId,
      details: { timestamp: new Date().toISOString() },
    });

    return {
      message: 'Session révoquée avec succès.',
    };
  }
}

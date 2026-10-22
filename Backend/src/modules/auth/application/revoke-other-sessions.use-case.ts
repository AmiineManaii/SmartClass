import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';

export class RevokeOtherSessionsUseCase {
  constructor(private readonly authRepository: AuthRepositoryPort) {}

  public async execute(userId: string, currentSessionId?: string): Promise<{ message: string; revokedCount: number }> {
    const revokedCount = await this.authRepository.revokeOtherUserSessions(userId, currentSessionId);

    await this.authRepository.saveAuditLog({
      userId,
      action: 'AUTH_ALL_SESSIONS_REVOKED',
      targetType: 'User',
      targetId: userId,
      details: { revokedCount, timestamp: new Date().toISOString() },
    });

    return {
      message: 'Toutes les autres sessions ont été révoquées.',
      revokedCount,
    };
  }
}

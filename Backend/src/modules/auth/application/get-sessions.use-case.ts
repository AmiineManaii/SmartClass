import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';

export interface UserSessionDTO {
  id: string;
  createdAt: string;
  expiresAt: string;
  isCurrent: boolean;
  device: string;
  ipAddress: string;
  location: string;
}

export class GetSessionsUseCase {
  constructor(private readonly authRepository: AuthRepositoryPort) {}

  public async execute(userId: string, currentTokenHash?: string): Promise<UserSessionDTO[]> {
    const rawSessions = await this.authRepository.getActiveUserSessions(userId);
    const auditLogs = await this.authRepository.getUserAuditLogs(userId, 20);

    const latestLoginLog = auditLogs.find((l) =>
      l.action === 'AUTH_LOGIN_SUCCESS' || l.action === 'AUTH_2FA_SUCCESS',
    );
    const details = (latestLoginLog?.details as Record<string, unknown>) || {};
    const defaultIp = (details.ipAddress as string) || '127.0.0.1';

    return rawSessions.map((session, index) => {
      const isCurrent = currentTokenHash ? session.tokenHash === currentTokenHash : index === 0;

      return {
        id: session.id,
        createdAt: session.createdAt.toISOString(),
        expiresAt: session.expiresAt.toISOString(),
        isCurrent,
        device: isCurrent ? 'Session active (Cet appareil)' : `Appareil connecté #${index + 1}`,
        ipAddress: defaultIp,
        location: defaultIp.startsWith('192.') || defaultIp.startsWith('127.') || defaultIp.startsWith('10.')
          ? 'Réseau local sécurisé'
          : 'Connexion distante',
      };
    });
  }
}

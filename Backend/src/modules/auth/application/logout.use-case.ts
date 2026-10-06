import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { TokenServicePort } from '../domain/token-service.port.js';

export interface LogoutDTO {
  refreshToken?: string;
}

export interface LogoutResult {
  message: string;
}

export class LogoutUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly tokenService: TokenServicePort,
  ) {}

  public async execute(dto: LogoutDTO): Promise<LogoutResult> {
    if (dto.refreshToken) {
      const tokenHash = this.tokenService.hashRefreshToken(dto.refreshToken.trim());
      const storedToken = await this.authRepository.findRefreshToken(tokenHash);
      if (storedToken && !storedToken.isRevoked) {
        await this.authRepository.revokeRefreshToken(storedToken.id);
      }
    }

    return {
      message: 'Logged out successfully.',
    };
  }
}

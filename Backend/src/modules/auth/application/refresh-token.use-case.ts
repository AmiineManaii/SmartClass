import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { TokenServicePort } from '../domain/token-service.port.js';
import { UnauthorizedError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export interface RefreshTokenDTO {
  refreshToken: string;
}

export interface RefreshTokenResult {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export class RefreshTokenUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly tokenService: TokenServicePort,
    private readonly refreshExpirationDays = 7,
  ) {}

  public async execute(dto: RefreshTokenDTO): Promise<RefreshTokenResult> {
    const tokenHash = this.tokenService.hashRefreshToken(dto.refreshToken.trim());
    const storedToken = await this.authRepository.findRefreshToken(tokenHash);

    if (!storedToken) {
      throw new UnauthorizedError('Invalid refresh token', ErrorCodes.AUTH_TOKEN_INVALID);
    }

    // Reuse detection: If a revoked token is used, someone might have stolen it!
    if (storedToken.isRevoked) {
      await this.authRepository.revokeFamily(storedToken.familyId);
      throw new UnauthorizedError(
        'Token reuse detected. All sessions in this security family have been revoked.',
        ErrorCodes.AUTH_REFRESH_REUSED,
      );
    }

    // Check expiration
    if (storedToken.expiresAt.getTime() < Date.now()) {
      throw new UnauthorizedError(
        'Refresh token has expired. Please log in again.',
        ErrorCodes.AUTH_TOKEN_EXPIRED,
      );
    }

    // Fetch user
    const user = await this.authRepository.findUserById(storedToken.userId);
    if (!user || user.status === 'SUSPENDED') {
      throw new UnauthorizedError(
        'User account not found or suspended',
        ErrorCodes.AUTH_TOKEN_INVALID,
      );
    }

    // Rotate token: revoke old token and create new one in the same family
    await this.authRepository.revokeRefreshToken(storedToken.id);

    const newRawRefreshToken = this.tokenService.generateRefreshToken();
    const newTokenHash = this.tokenService.hashRefreshToken(newRawRefreshToken);
    const refreshExpiresAt = new Date(Date.now() + this.refreshExpirationDays * 24 * 60 * 60 * 1000);

    await this.authRepository.saveRefreshToken(
      user.id,
      newTokenHash,
      storedToken.familyId,
      refreshExpiresAt,
    );

    const { token: accessToken, expiresIn } = await this.tokenService.generateAccessToken({
      sub: user.id,
      email: user.email,
      role: user.role,
      status: user.status,
    });

    return {
      accessToken,
      refreshToken: newRawRefreshToken,
      expiresIn,
    };
  }
}

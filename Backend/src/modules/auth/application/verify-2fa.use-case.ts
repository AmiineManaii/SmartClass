import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { TotpService } from '../infrastructure/totp.service.js';
import { BadRequestError, NotFoundError, UnauthorizedError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export interface Verify2FADTO {
  userId: string;
  code: string;
  ipAddress?: string;
}

export class Verify2FAUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly totpService: TotpService,
  ) {}

  public async execute(dto: Verify2FADTO): Promise<{ success: boolean; message: string }> {
    const user = await this.authRepository.findUserById(dto.userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    const secrets = await this.authRepository.getTwoFactorSecret(user.id);
    if (!secrets?.twoFactorSecret) {
      throw new BadRequestError('2FA setup has not been initiated. Please call /setup first.');
    }

    const isValid = this.totpService.verifyCode(secrets.twoFactorSecret, dto.code);
    if (!isValid) {
      await this.authRepository.saveAuditLog({
        userId: user.id,
        action: 'AUTH_2FA_SETUP_FAILED',
        targetType: 'User',
        targetId: user.id,
        details: { ipAddress: dto.ipAddress ?? 'unknown' },
      });
      throw new UnauthorizedError(
        'Invalid 6-digit verification code. Please check your authenticator application.',
        ErrorCodes.AUTH_INVALID_CREDENTIALS,
      );
    }

    // Activate 2FA
    await this.authRepository.updateUser(user.id, {
      twoFactorEnabled: true,
    });

    await this.authRepository.saveAuditLog({
      userId: user.id,
      action: 'AUTH_2FA_ENABLED',
      targetType: 'User',
      targetId: user.id,
      details: { ipAddress: dto.ipAddress ?? 'unknown', method: 'TOTP' },
    });

    return {
      success: true,
      message: 'Two-factor authentication successfully activated',
    };
  }
}

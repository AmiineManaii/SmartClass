import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { PasswordHasherPort } from '../domain/password-hasher.port.js';
import type { TotpService } from '../infrastructure/totp.service.js';
import { BadRequestError, NotFoundError, UnauthorizedError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export interface Disable2FADTO {
  userId: string;
  code?: string;
  password?: string;
  ipAddress?: string;
}

export class Disable2FAUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly passwordHasher: PasswordHasherPort,
    private readonly totpService: TotpService,
  ) {}

  public async execute(dto: Disable2FADTO): Promise<{ success: boolean; message: string }> {
    const user = await this.authRepository.findUserById(dto.userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    if (!user.twoFactorEnabled) {
      throw new BadRequestError('Two-factor authentication is not currently active');
    }

    // Require either a valid TOTP code OR the current account password
    let authorized = false;

    if (dto.code) {
      const secrets = await this.authRepository.getTwoFactorSecret(user.id);
      if (secrets?.twoFactorSecret) {
        authorized = this.totpService.verifyCode(secrets.twoFactorSecret, dto.code);
      }
    } else if (dto.password) {
      authorized = await this.passwordHasher.verify(dto.password, user.passwordHash);
    }

    if (!authorized) {
      await this.authRepository.saveAuditLog({
        userId: user.id,
        action: 'AUTH_2FA_DISABLE_FAILED',
        targetType: 'User',
        targetId: user.id,
        details: { ipAddress: dto.ipAddress ?? 'unknown' },
      });
      throw new UnauthorizedError(
        'Invalid 2FA code or password provided to disable 2FA',
        ErrorCodes.AUTH_INVALID_CREDENTIALS,
      );
    }

    // Clear 2FA credentials
    await this.authRepository.updateUser(user.id, {
      twoFactorEnabled: false,
      twoFactorSecret: null,
      twoFactorRecoveryCodes: [],
    });

    await this.authRepository.saveAuditLog({
      userId: user.id,
      action: 'AUTH_2FA_DISABLED',
      targetType: 'User',
      targetId: user.id,
      details: { ipAddress: dto.ipAddress ?? 'unknown' },
    });

    return {
      success: true,
      message: 'Two-factor authentication disabled successfully',
    };
  }
}

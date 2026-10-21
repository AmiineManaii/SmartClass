import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { TotpService } from '../infrastructure/totp.service.js';
import { NotFoundError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export interface Setup2FAResult {
  secret: string;
  otpAuthUrl: string;
  qrCodeDataUrl: string;
  recoveryCodes: string[];
}

export class Setup2FAUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly totpService: TotpService,
  ) {}

  public async execute(userId: string): Promise<Setup2FAResult> {
    const user = await this.authRepository.findUserById(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    // Generate fresh secret & recovery codes
    const secret = this.totpService.generateSecret();
    const otpAuthUrl = this.totpService.getOtpAuthUrl(user.email, secret);
    const qrCodeDataUrl = await this.totpService.generateQrCodeDataUrl(otpAuthUrl);
    const recoveryCodes = this.totpService.generateRecoveryCodes(8);
    const hashedRecoveryCodes = recoveryCodes.map((code) =>
      this.totpService.hashRecoveryCode(code),
    );

    // Persist pending secret & recovery codes (2FA remains disabled until verified with a valid code)
    await this.authRepository.updateUser(user.id, {
      twoFactorSecret: secret,
      twoFactorRecoveryCodes: hashedRecoveryCodes,
    });

    return {
      secret,
      otpAuthUrl,
      qrCodeDataUrl,
      recoveryCodes,
    };
  }
}

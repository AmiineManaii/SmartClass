import crypto from 'node:crypto';
import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { TokenServicePort } from '../domain/token-service.port.js';
import type { TotpService } from '../infrastructure/totp.service.js';
import type { SafeUser } from '../domain/user.entity.js';
import {
  AccountLockedError,
  ForbiddenError,
  NotFoundError,
  UnauthorizedError,
} from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export interface Authenticate2FADTO {
  tempToken: string;
  code: string;
  rememberMe?: boolean;
  ipAddress?: string;
}

export interface Authenticate2FAResult {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: SafeUser;
}

export class Authenticate2FAUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly tokenService: TokenServicePort,
    private readonly totpService: TotpService,
    private readonly maxAttempts = 3,
    private readonly lockoutDurationMinutes = 1,
    private readonly refreshExpirationDays = 7,
  ) {}

  public async execute(dto: Authenticate2FADTO): Promise<Authenticate2FAResult> {
    // 1. Verify the temporary 2FA token
    const { userId } = await this.tokenService.verifyTwoFactorTempToken(dto.tempToken);

    // 2. Fetch user
    const user = await this.authRepository.findUserById(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    // 3. Check lockout
    if (user.isLocked()) {
      const remainingSeconds = user.getLockoutRemainingSeconds();
      throw new AccountLockedError(
        `Account temporarily locked due to consecutive failed attempts. Please try again after ${Math.ceil(remainingSeconds / 60)} minute(s).`,
        [{ remainingSeconds, lockedUntil: user.lockedUntil?.toISOString() }],
      );
    }

    if (user.status === 'SUSPENDED') {
      throw new ForbiddenError(
        'Your account has been suspended.',
        ErrorCodes.AUTH_USER_SUSPENDED,
      );
    }

    // 4. Retrieve 2FA secret and recovery codes
    const secrets = await this.authRepository.getTwoFactorSecret(user.id);
    if (!secrets?.twoFactorEnabled || !secrets.twoFactorSecret) {
      throw new UnauthorizedError(
        'Two-factor authentication is not configured for this account',
        ErrorCodes.AUTH_INVALID_CREDENTIALS,
      );
    }

    // 5. Verify either TOTP code or Recovery Code
    let isValid = this.totpService.verifyCode(secrets.twoFactorSecret, dto.code);
    let recoveryCodeUsed = false;

    if (!isValid && secrets.twoFactorRecoveryCodes && secrets.twoFactorRecoveryCodes.length > 0) {
      const hashedInput = this.totpService.hashRecoveryCode(dto.code);
      const codeIndex = secrets.twoFactorRecoveryCodes.indexOf(hashedInput);
      if (codeIndex !== -1) {
        isValid = true;
        recoveryCodeUsed = true;
        // Consume one-time recovery code
        const updatedRecoveryCodes = [...secrets.twoFactorRecoveryCodes];
        updatedRecoveryCodes.splice(codeIndex, 1);
        await this.authRepository.updateUser(user.id, {
          twoFactorRecoveryCodes: updatedRecoveryCodes,
        });
      }
    }

    // 6. Handle failure (count against max attempts to prevent 2FA brute force)
    if (!isValid) {
      const { failedAttempts, isLocked, lockedUntil } =
        await this.authRepository.incrementFailedAttempts(
          user.id,
          this.maxAttempts,
          this.lockoutDurationMinutes,
        );

      await this.authRepository.saveAuditLog({
        userId: user.id,
        action: 'AUTH_2FA_FAILED',
        targetType: 'User',
        targetId: user.id,
        details: { ipAddress: dto.ipAddress ?? 'unknown', failedAttempts },
      });

      if (isLocked) {
        const remainingSeconds = this.lockoutDurationMinutes * 60;
        await this.authRepository.saveAuditLog({
          userId: user.id,
          action: 'AUTH_ACCOUNT_LOCKED',
          targetType: 'User',
          targetId: user.id,
          details: { ipAddress: dto.ipAddress ?? 'unknown', lockoutDurationMinutes: this.lockoutDurationMinutes },
        });

        throw new AccountLockedError(
          `Account temporarily locked for ${this.lockoutDurationMinutes} minute(s) due to consecutive failed attempts.`,
          [{ remainingSeconds, lockedUntil: lockedUntil?.toISOString() }],
        );
      }

      const remainingAttempts = Math.max(0, this.maxAttempts - failedAttempts);
      throw new UnauthorizedError(
        `Invalid authentication code. You have ${remainingAttempts} attempt(s) remaining.`,
        ErrorCodes.AUTH_INVALID_CREDENTIALS,
        [{ remainingAttempts }],
      );
    }

    // 7. Successful 2FA verification: reset failed attempts
    if (user.failedLoginAttempts > 0 || user.lockedUntil !== null) {
      await this.authRepository.resetFailedAttempts(user.id);
    }

    await this.authRepository.saveAuditLog({
      userId: user.id,
      action: 'AUTH_LOGIN_SUCCESS',
      targetType: 'User',
      targetId: user.id,
      details: {
        ipAddress: dto.ipAddress ?? 'unknown',
        method: recoveryCodeUsed ? 'RECOVERY_CODE' : 'TOTP_2FA',
      },
    });

    // 8. Generate full session tokens
    const { token: accessToken, expiresIn } = await this.tokenService.generateAccessToken({
      sub: user.id,
      email: user.email,
      role: user.role,
      status: user.status,
      teacherApprovalStatus: user.teacherApprovalStatus,
    });

    const rawRefreshToken = this.tokenService.generateRefreshToken();
    const tokenHash = this.tokenService.hashRefreshToken(rawRefreshToken);
    const familyId = crypto.randomUUID();
    const days = dto.rememberMe ? 30 : this.refreshExpirationDays;
    const refreshExpiresAt = new Date(Date.now() + days * 24 * 60 * 60 * 1000);

    await this.authRepository.saveRefreshToken(user.id, tokenHash, familyId, refreshExpiresAt);

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      expiresIn,
      user: user.toSafeUser(),
    };
  }
}

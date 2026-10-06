import crypto from 'node:crypto';
import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { PasswordHasherPort } from '../domain/password-hasher.port.js';
import { BadRequestError } from '../../../shared/errors/app-error.js';

export interface ResetPasswordDTO {
  email: string;
  code: string;
  newPassword: string;
}

export interface ResetPasswordResult {
  message: string;
}

export class ResetPasswordUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly passwordHasher: PasswordHasherPort,
  ) {}

  public async execute(dto: ResetPasswordDTO): Promise<ResetPasswordResult> {
    const user = await this.authRepository.findUserByEmail(dto.email);
    if (!user) {
      throw new BadRequestError('Invalid password reset request', [
        { path: 'email', message: 'No account associated with this email' },
      ]);
    }

    const storedCode = await this.authRepository.getLatestPasswordResetCode(user.id);
    if (!storedCode) {
      throw new BadRequestError(
        'No password reset code found. Please request a new code.',
        [{ path: 'code', message: 'No active reset code found' }],
      );
    }

    if (storedCode.usedAt !== null) {
      throw new BadRequestError(
        'This password reset code has already been used. Please request a new code.',
        [{ path: 'code', message: 'Code already used' }],
      );
    }

    if (storedCode.expiresAt.getTime() < Date.now()) {
      throw new BadRequestError(
        'Password reset code has expired. Please request a new code.',
        [{ path: 'code', message: 'Code expired' }],
      );
    }

    if (storedCode.attempts >= 5) {
      throw new BadRequestError(
        'Too many failed attempts. Please request a new password reset code.',
        [{ path: 'code', message: 'Maximum attempts exceeded' }],
      );
    }

    const providedHash = crypto.createHash('sha256').update(dto.code.trim()).digest('hex');
    if (providedHash !== storedCode.codeHash) {
      const currentAttempts = await this.authRepository.incrementPasswordResetAttempts(storedCode.id);
      const remainingAttempts = Math.max(0, 5 - currentAttempts);
      throw new BadRequestError(
        `Invalid password reset code. ${remainingAttempts} attempt(s) remaining.`,
        [{ path: 'code', message: 'Code does not match', remainingAttempts }],
      );
    }

    // Hash new password with Argon2id
    const newPasswordHash = await this.passwordHasher.hash(dto.newPassword);

    // Update password, clear any lockouts, mark code as used
    await this.authRepository.updateUser(user.id, {
      passwordHash: newPasswordHash,
      failedLoginAttempts: 0,
      lockedUntil: null,
    });

    await this.authRepository.markPasswordResetCodeUsed(storedCode.id);

    // Security best practice: revoke all existing sessions when password changes
    await this.authRepository.revokeAllUserTokens(user.id);

    return {
      message: 'Password has been reset successfully. You can now log in with your new password.',
    };
  }
}

import crypto from 'node:crypto';
import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { TokenServicePort } from '../domain/token-service.port.js';
import type { SafeUser } from '../domain/user.entity.js';
import { BadRequestError } from '../../../shared/errors/app-error.js';

export interface VerifyEmailDTO {
  email: string;
  code: string;
}

export interface VerifyEmailResult {
  message: string;
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: SafeUser;
}

export class VerifyEmailUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly tokenService: TokenServicePort,
    private readonly refreshExpirationDays = 7,
  ) {}

  public async execute(dto: VerifyEmailDTO): Promise<VerifyEmailResult> {
    const user = await this.authRepository.findUserByEmail(dto.email);
    if (!user) {
      throw new BadRequestError('Invalid email verification request', [
        { path: 'email', message: 'No account associated with this email' },
      ]);
    }

    if (user.emailVerified) {
      throw new BadRequestError('This email is already verified', [
        { path: 'email', message: 'Account email has already been verified' },
      ]);
    }

    const storedCode = await this.authRepository.getLatestVerificationCode(user.id);
    if (!storedCode) {
      throw new BadRequestError(
        'No verification code found. Please request a new code.',
        [{ path: 'code', message: 'No active verification code found' }],
      );
    }

    if (storedCode.expiresAt.getTime() < Date.now()) {
      throw new BadRequestError(
        'Verification code has expired. Please request a new code.',
        [{ path: 'code', message: 'Code expired' }],
      );
    }

    if (storedCode.attempts >= 5) {
      throw new BadRequestError(
        'Too many failed attempts. Please request a new verification code.',
        [{ path: 'code', message: 'Maximum verification attempts exceeded' }],
      );
    }

    const providedHash = crypto.createHash('sha256').update(dto.code.trim()).digest('hex');
    if (providedHash !== storedCode.codeHash) {
      const currentAttempts = await this.authRepository.incrementVerificationAttempts(storedCode.id);
      const remainingAttempts = Math.max(0, 5 - currentAttempts);
      throw new BadRequestError(
        `Invalid verification code. ${remainingAttempts} attempt(s) remaining.`,
        [{ path: 'code', message: 'Code does not match', remainingAttempts }],
      );
    }

    // Mark email as verified and delete used codes
    const updatedUser = await this.authRepository.updateUser(user.id, {
      emailVerified: true,
    });
    await this.authRepository.deleteVerificationCodes(user.id);

    // Issue initial JWT session
    const { token: accessToken, expiresIn } = await this.tokenService.generateAccessToken({
      sub: updatedUser.id,
      email: updatedUser.email,
      role: updatedUser.role,
      status: updatedUser.status,
    });

    const rawRefreshToken = this.tokenService.generateRefreshToken();
    const tokenHash = this.tokenService.hashRefreshToken(rawRefreshToken);
    const familyId = crypto.randomUUID();
    const refreshExpiresAt = new Date(Date.now() + this.refreshExpirationDays * 24 * 60 * 60 * 1000);

    await this.authRepository.saveRefreshToken(updatedUser.id, tokenHash, familyId, refreshExpiresAt);

    return {
      message: 'Email verified successfully. Welcome to SmartClass!',
      accessToken,
      refreshToken: rawRefreshToken,
      expiresIn,
      user: updatedUser.toSafeUser(),
    };
  }
}

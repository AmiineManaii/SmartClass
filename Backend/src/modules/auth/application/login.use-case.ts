import crypto from 'node:crypto';
import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { PasswordHasherPort } from '../domain/password-hasher.port.js';
import type { TokenServicePort } from '../domain/token-service.port.js';
import type { SafeUser } from '../domain/user.entity.js';
import {
  AccountLockedError,
  ForbiddenError,
  UnauthorizedError,
} from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export interface LoginDTO {
  email: string;
  password: string;
}

export interface LoginResult {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: SafeUser;
}

export class LoginUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly passwordHasher: PasswordHasherPort,
    private readonly tokenService: TokenServicePort,
    private readonly maxAttempts = 3,
    private readonly lockoutDurationMinutes = 5,
    private readonly refreshExpirationDays = 7,
  ) {}

  public async execute(dto: LoginDTO): Promise<LoginResult> {
    const user = await this.authRepository.findUserByEmail(dto.email);

    if (!user) {
      // Mitigate timing attack
      await this.passwordHasher.verify(
        'dummy-password-to-equalize-timing',
        '$argon2id$v=19$m=65536,t=3,p=4$dummyhashdummyhashdummyhash$dummyhashdummyhashdummyhash',
      );
      throw new UnauthorizedError('Invalid email or password', ErrorCodes.AUTH_INVALID_CREDENTIALS);
    }

    // 1. Check if account is temporarily locked
    if (user.isLocked()) {
      const remainingSeconds = user.getLockoutRemainingSeconds();
      const remainingMinutes = Math.ceil(remainingSeconds / 60);
      throw new AccountLockedError(
        `Account temporarily locked due to 3 consecutive failed login attempts. Please try again after ${remainingMinutes} minute(s).`,
        [
          {
            remainingSeconds,
            lockedUntil: user.lockedUntil?.toISOString(),
          },
        ],
      );
    }

    // 2. Verify password with Argon2id
    const isPasswordValid = await this.passwordHasher.verify(dto.password, user.passwordHash);

    if (!isPasswordValid) {
      const { failedAttempts, isLocked, lockedUntil } =
        await this.authRepository.incrementFailedAttempts(
          user.id,
          this.maxAttempts,
          this.lockoutDurationMinutes,
        );

      if (isLocked) {
        const remainingSeconds = this.lockoutDurationMinutes * 60;
        throw new AccountLockedError(
          `Account temporarily locked for ${this.lockoutDurationMinutes} minutes due to 3 consecutive failed login attempts.`,
          [
            {
              remainingSeconds,
              lockedUntil: lockedUntil?.toISOString(),
            },
          ],
        );
      }

      const remainingAttempts = Math.max(0, this.maxAttempts - failedAttempts);
      throw new UnauthorizedError(
        `Invalid email or password. You have ${remainingAttempts} attempt(s) remaining before account lockout.`,
        ErrorCodes.AUTH_INVALID_CREDENTIALS,
        [{ remainingAttempts }],
      );
    }

    // 3. Check account status & email verification
    if (user.status === 'SUSPENDED') {
      throw new ForbiddenError(
        'Your account has been suspended. Please contact an administrator.',
        ErrorCodes.AUTH_USER_SUSPENDED,
      );
    }

    if (!user.emailVerified) {
      throw new ForbiddenError(
        'Please verify your email address before logging in.',
        ErrorCodes.AUTH_EMAIL_NOT_VERIFIED,
        [{ email: user.email }],
      );
    }

    // 4. Successful login: reset failed attempts
    if (user.failedLoginAttempts > 0 || user.lockedUntil !== null) {
      await this.authRepository.resetFailedAttempts(user.id);
    }

    // 5. Generate session tokens (short-lived access + rotating refresh token)
    const { token: accessToken, expiresIn } = await this.tokenService.generateAccessToken({
      sub: user.id,
      email: user.email,
      role: user.role,
      status: user.status,
    });

    const rawRefreshToken = this.tokenService.generateRefreshToken();
    const tokenHash = this.tokenService.hashRefreshToken(rawRefreshToken);
    const familyId = crypto.randomUUID();
    const refreshExpiresAt = new Date(Date.now() + this.refreshExpirationDays * 24 * 60 * 60 * 1000);

    await this.authRepository.saveRefreshToken(user.id, tokenHash, familyId, refreshExpiresAt);

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      expiresIn,
      user: user.toSafeUser(),
    };
  }
}

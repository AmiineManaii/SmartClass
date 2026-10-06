import crypto from 'node:crypto';
import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { EmailPort } from '../domain/email.port.js';

export interface ResendVerificationDTO {
  email: string;
}

export interface ResendVerificationResult {
  message: string;
}

export class ResendVerificationUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly emailService: EmailPort,
    private readonly codeExpirationMinutes = 15,
  ) {}

  public async execute(dto: ResendVerificationDTO): Promise<ResendVerificationResult> {
    const user = await this.authRepository.findUserByEmail(dto.email);

    // Generic response to prevent user enumeration if email does not exist
    if (!user) {
      return {
        message: 'If an unverified account exists with that email, a verification code has been sent.',
      };
    }

    if (user.emailVerified) {
      return {
        message: 'This email is already verified. You can log in directly.',
      };
    }

    // Generate fresh 6-digit OTP code
    const rawCode = Math.floor(100000 + Math.random() * 900000).toString();
    const codeHash = crypto.createHash('sha256').update(rawCode).digest('hex');
    const expiresAt = new Date(Date.now() + this.codeExpirationMinutes * 60 * 1000);

    await this.authRepository.createVerificationCode(user.id, codeHash, expiresAt);
    await this.emailService.sendVerificationEmail(user.email, user.firstName, rawCode);

    return {
      message: 'A new verification code has been sent to your email address.',
    };
  }
}

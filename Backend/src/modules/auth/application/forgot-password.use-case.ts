import crypto from 'node:crypto';
import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { EmailPort } from '../domain/email.port.js';

export interface ForgotPasswordDTO {
  email: string;
}

export interface ForgotPasswordResult {
  message: string;
}

export class ForgotPasswordUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly emailService: EmailPort,
    private readonly codeExpirationMinutes = 15,
  ) {}

  public async execute(dto: ForgotPasswordDTO): Promise<ForgotPasswordResult> {
    const user = await this.authRepository.findUserByEmail(dto.email);

    // Generic response to prevent user enumeration
    if (!user) {
      return {
        message: 'If an account with that email exists, a password reset code has been sent.',
      };
    }

    // Generate 6-digit OTP code for password reset
    const rawCode = Math.floor(100000 + Math.random() * 900000).toString();
    const codeHash = crypto.createHash('sha256').update(rawCode).digest('hex');
    const expiresAt = new Date(Date.now() + this.codeExpirationMinutes * 60 * 1000);

    await this.authRepository.createPasswordResetCode(user.id, codeHash, expiresAt);
    await this.emailService.sendPasswordResetEmail(user.email, user.firstName, rawCode);

    return {
      message: 'If an account with that email exists, a password reset code has been sent.',
    };
  }
}

import crypto from 'node:crypto';
import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { PasswordHasherPort } from '../domain/password-hasher.port.js';
import type { EmailPort } from '../domain/email.port.js';
import type { Role, SafeUser } from '../domain/user.entity.js';
import { ConflictError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export interface RegisterDTO {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  role?: Role | null;
}

export interface RegisterResult {
  message: string;
  user: SafeUser;
}

export class RegisterUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly passwordHasher: PasswordHasherPort,
    private readonly emailService: EmailPort,
    private readonly codeExpirationMinutes = 15,
  ) {}

  public async execute(dto: RegisterDTO): Promise<RegisterResult> {
    const existingUser = await this.authRepository.findUserByEmail(dto.email);
    if (existingUser) {
      throw new ConflictError(
        'An account with this email address already exists',
        ErrorCodes.EMAIL_ALREADY_USED,
      );
    }

    const passwordHash = await this.passwordHasher.hash(dto.password);

    const newUser = await this.authRepository.createUser({
      email: dto.email,
      passwordHash,
      firstName: dto.firstName,
      lastName: dto.lastName,
      role: dto.role ?? null,
      emailVerified: false,
    });

    // Generate 6-digit OTP code for email verification
    const rawCode = Math.floor(100000 + Math.random() * 900000).toString();
    const codeHash = crypto.createHash('sha256').update(rawCode).digest('hex');
    const expiresAt = new Date(Date.now() + this.codeExpirationMinutes * 60 * 1000);

    await this.authRepository.createVerificationCode(newUser.id, codeHash, expiresAt);

    // Send verification email asynchronously
    await this.emailService.sendVerificationEmail(newUser.email, newUser.firstName, rawCode);

    return {
      message: 'Registration successful. A verification code has been sent to your email.',
      user: newUser.toSafeUser(),
    };
  }
}

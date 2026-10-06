import { Router, type RequestHandler } from 'express';
import { getEnv } from '../../config/env.js';
import type { AuthRepositoryPort } from './domain/auth-repository.port.js';
import type { PasswordHasherPort } from './domain/password-hasher.port.js';
import type { TokenServicePort } from './domain/token-service.port.js';
import type { EmailPort } from './domain/email.port.js';
import { PrismaAuthRepositoryAdapter } from './infrastructure/prisma-auth-repository.adapter.js';
import { Argon2PasswordHasherAdapter } from './infrastructure/argon2-password-hasher.adapter.js';
import { JoseTokenServiceAdapter } from './infrastructure/jose-token-service.adapter.js';
import { NodemailerSmtpEmailAdapter } from './infrastructure/nodemailer-smtp-email.adapter.js';
import { RegisterUseCase } from './application/register.use-case.js';
import { VerifyEmailUseCase } from './application/verify-email.use-case.js';
import { ResendVerificationUseCase } from './application/resend-verification.use-case.js';
import { LoginUseCase } from './application/login.use-case.js';
import { RefreshTokenUseCase } from './application/refresh-token.use-case.js';
import { ForgotPasswordUseCase } from './application/forgot-password.use-case.js';
import { ResetPasswordUseCase } from './application/reset-password.use-case.js';
import { LogoutUseCase } from './application/logout.use-case.js';
import { GetMeUseCase } from './application/get-me.use-case.js';
import { UpdateProfileUseCase } from './application/update-profile.use-case.js';
import { AuthController } from './presentation/auth.controller.js';
import { createAuthRouter } from './presentation/auth.routes.js';
import {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
} from './presentation/auth.middleware.js';
import type { Role } from './domain/user.entity.js';

export interface AuthModuleOptions {
  authRepository?: AuthRepositoryPort;
  passwordHasher?: PasswordHasherPort;
  tokenService?: TokenServicePort;
  emailService?: EmailPort;
  authRateLimiter?: RequestHandler;
  maxAttempts?: number;
  lockoutDurationMinutes?: number;
  refreshExpirationDays?: number;
}

export interface AuthModule {
  router: Router;
  controller: AuthController;
  authenticateMiddleware: RequestHandler;
  requireRoleMiddleware: (allowedRoles: Role[]) => RequestHandler;
  tokenService: TokenServicePort;
  authRepository: AuthRepositoryPort;
  emailService: EmailPort;
}

export const createAuthModule = (options: AuthModuleOptions = {}): AuthModule => {
  const env = getEnv();

  const authRepository = options.authRepository ?? new PrismaAuthRepositoryAdapter();
  const passwordHasher = options.passwordHasher ?? new Argon2PasswordHasherAdapter();
  const tokenService =
    options.tokenService ??
    new JoseTokenServiceAdapter({
      jwtSecret: env.JWT_SECRET,
      accessExpiration: env.JWT_ACCESS_EXPIRATION,
    });
  const emailService = options.emailService ?? new NodemailerSmtpEmailAdapter(env);

  const maxAttempts = options.maxAttempts ?? env.LOCKOUT_MAX_ATTEMPTS;
  const lockoutDurationMinutes = options.lockoutDurationMinutes ?? env.LOCKOUT_DURATION_MINUTES;
  const refreshExpirationDays = options.refreshExpirationDays ?? env.JWT_REFRESH_EXPIRATION_DAYS;

  // Use cases
  const registerUseCase = new RegisterUseCase(
    authRepository,
    passwordHasher,
    emailService,
    env.VERIFICATION_CODE_EXPIRATION_MINUTES,
  );
  const verifyEmailUseCase = new VerifyEmailUseCase(
    authRepository,
    tokenService,
    refreshExpirationDays,
  );
  const resendVerificationUseCase = new ResendVerificationUseCase(
    authRepository,
    emailService,
    env.VERIFICATION_CODE_EXPIRATION_MINUTES,
  );
  const loginUseCase = new LoginUseCase(
    authRepository,
    passwordHasher,
    tokenService,
    maxAttempts,
    lockoutDurationMinutes,
    refreshExpirationDays,
  );
  const refreshTokenUseCase = new RefreshTokenUseCase(
    authRepository,
    tokenService,
    refreshExpirationDays,
  );
  const forgotPasswordUseCase = new ForgotPasswordUseCase(
    authRepository,
    emailService,
    env.PASSWORD_RESET_EXPIRATION_MINUTES,
  );
  const resetPasswordUseCase = new ResetPasswordUseCase(authRepository, passwordHasher);
  const logoutUseCase = new LogoutUseCase(authRepository, tokenService);
  const getMeUseCase = new GetMeUseCase(authRepository);
  const updateProfileUseCase = new UpdateProfileUseCase(authRepository);

  const controller = new AuthController(
    registerUseCase,
    verifyEmailUseCase,
    resendVerificationUseCase,
    loginUseCase,
    refreshTokenUseCase,
    forgotPasswordUseCase,
    resetPasswordUseCase,
    logoutUseCase,
    getMeUseCase,
    updateProfileUseCase,
  );

  const authenticateMiddleware = createAuthenticateMiddleware(tokenService);

  const router = createAuthRouter({
    controller,
    authenticateMiddleware,
    authRateLimiter: options.authRateLimiter,
  });

  return {
    router,
    controller,
    authenticateMiddleware,
    requireRoleMiddleware: createRequireRoleMiddleware,
    tokenService,
    authRepository,
    emailService,
  };
};

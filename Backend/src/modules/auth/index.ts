export { createAuthModule, type AuthModule, type AuthModuleOptions } from './auth.module.js';
export {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
  type AuthenticatedUser,
} from './presentation/auth.middleware.js';
export { NodemailerSmtpEmailAdapter } from './infrastructure/nodemailer-smtp-email.adapter.js';
export { ConsoleEmailAdapter } from './infrastructure/console-email.adapter.js';
export { UpdateProfileUseCase } from './application/update-profile.use-case.js';
export { roleSchema, updateProfileSchema, type UpdateProfileInput } from './presentation/auth.validation.js';
export type { SafeUser, UserEntity, Role, UserStatus } from './domain/user.entity.js';
export type { AuthTokens, TokenPayload } from './domain/auth-tokens.js';
export type { AuthRepositoryPort } from './domain/auth-repository.port.js';
export type { PasswordHasherPort } from './domain/password-hasher.port.js';
export type { TokenServicePort } from './domain/token-service.port.js';
export type { EmailPort } from './domain/email.port.js';


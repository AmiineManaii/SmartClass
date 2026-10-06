export { createAuthModule, type AuthModule, type AuthModuleOptions } from './auth.module.js';
export { createAuthenticateMiddleware, type AuthenticatedUser } from './presentation/auth.middleware.js';
export type { SafeUser, UserEntity, Role, UserStatus } from './domain/user.entity.js';
export type { AuthTokens, TokenPayload } from './domain/auth-tokens.js';
export type { AuthRepositoryPort } from './domain/auth-repository.port.js';
export type { PasswordHasherPort } from './domain/password-hasher.port.js';
export type { TokenServicePort } from './domain/token-service.port.js';
export type { EmailPort } from './domain/email.port.js';

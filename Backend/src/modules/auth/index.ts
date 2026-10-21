export { createAuthModule, type AuthModule, type AuthModuleOptions } from './auth.module.js';
export {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
  createRequireApprovedTeacherMiddleware,
  type AuthenticatedUser,
} from './presentation/auth.middleware.js';
export { NodemailerSmtpEmailAdapter } from './infrastructure/nodemailer-smtp-email.adapter.js';
export { ConsoleEmailAdapter } from './infrastructure/console-email.adapter.js';
export { UpdateProfileUseCase } from './application/update-profile.use-case.js';
export { roleSchema, updateProfileSchema, type UpdateProfileInput } from './presentation/auth.validation.js';
export type { SafeUser, UserEntity, Role, UserStatus, TeacherApprovalStatus } from './domain/user.entity.js';
export type { AuthTokens, TokenPayload } from './domain/auth-tokens.js';
export type { AuthRepositoryPort } from './domain/auth-repository.port.js';
export type { PasswordHasherPort } from './domain/password-hasher.port.js';
export type { TokenServicePort } from './domain/token-service.port.js';
export type { EmailPort } from './domain/email.port.js';
export { TotpService } from './infrastructure/totp.service.js';
export { Setup2FAUseCase, type Setup2FAResult } from './application/setup-2fa.use-case.js';
export { Verify2FAUseCase, type Verify2FADTO } from './application/verify-2fa.use-case.js';
export { Disable2FAUseCase, type Disable2FADTO } from './application/disable-2fa.use-case.js';
export { Authenticate2FAUseCase, type Authenticate2FADTO, type Authenticate2FAResult } from './application/authenticate-2fa.use-case.js';
export { GetAuditLogsUseCase, type AuditLogItem } from './application/get-audit-logs.use-case.js';


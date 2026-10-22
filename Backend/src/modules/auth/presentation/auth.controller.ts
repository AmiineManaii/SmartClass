import type { Request, Response, NextFunction } from 'express';
import type { RegisterUseCase } from '../application/register.use-case.js';
import type { VerifyEmailUseCase } from '../application/verify-email.use-case.js';
import type { CheckEmailUseCase } from '../application/check-email.use-case.js';
import type { ResendVerificationUseCase } from '../application/resend-verification.use-case.js';
import type { LoginUseCase } from '../application/login.use-case.js';
import type { RefreshTokenUseCase } from '../application/refresh-token.use-case.js';
import type { ForgotPasswordUseCase } from '../application/forgot-password.use-case.js';
import type { ResetPasswordUseCase } from '../application/reset-password.use-case.js';
import type { LogoutUseCase } from '../application/logout.use-case.js';
import type { GetMeUseCase } from '../application/get-me.use-case.js';
import type { UpdateProfileUseCase } from '../application/update-profile.use-case.js';
import type { Setup2FAUseCase } from '../application/setup-2fa.use-case.js';
import type { Verify2FAUseCase } from '../application/verify-2fa.use-case.js';
import type { Disable2FAUseCase } from '../application/disable-2fa.use-case.js';
import type { Authenticate2FAUseCase } from '../application/authenticate-2fa.use-case.js';
import type { GetAuditLogsUseCase } from '../application/get-audit-logs.use-case.js';
import type { ChangePasswordUseCase } from '../application/change-password.use-case.js';
import type { GetSessionsUseCase } from '../application/get-sessions.use-case.js';
import type { RevokeSessionUseCase } from '../application/revoke-session.use-case.js';
import type { RevokeOtherSessionsUseCase } from '../application/revoke-other-sessions.use-case.js';
import type { FreezeAccountUseCase } from '../application/freeze-account.use-case.js';
import type { DeleteAccountUseCase } from '../application/delete-account.use-case.js';
import { UnauthorizedError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export class AuthController {
  constructor(
    private readonly registerUseCase: RegisterUseCase,
    private readonly verifyEmailUseCase: VerifyEmailUseCase,
    private readonly checkEmailUseCase: CheckEmailUseCase,
    private readonly resendVerificationUseCase: ResendVerificationUseCase,
    private readonly loginUseCase: LoginUseCase,
    private readonly refreshTokenUseCase: RefreshTokenUseCase,
    private readonly forgotPasswordUseCase: ForgotPasswordUseCase,
    private readonly resetPasswordUseCase: ResetPasswordUseCase,
    private readonly logoutUseCase: LogoutUseCase,
    private readonly getMeUseCase: GetMeUseCase,
    private readonly updateProfileUseCase: UpdateProfileUseCase,
    private readonly setup2FAUseCase: Setup2FAUseCase,
    private readonly verify2FAUseCase: Verify2FAUseCase,
    private readonly disable2FAUseCase: Disable2FAUseCase,
    private readonly authenticate2FAUseCase: Authenticate2FAUseCase,
    private readonly getAuditLogsUseCase: GetAuditLogsUseCase,
    private readonly changePasswordUseCase: ChangePasswordUseCase,
    private readonly getSessionsUseCase: GetSessionsUseCase,
    private readonly revokeSessionUseCase: RevokeSessionUseCase,
    private readonly revokeOtherSessionsUseCase: RevokeOtherSessionsUseCase,
    private readonly freezeAccountUseCase: FreezeAccountUseCase,
    private readonly deleteAccountUseCase: DeleteAccountUseCase,
  ) {}

  public register = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.registerUseCase.execute(req.body);
      res.status(201).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public verifyEmail = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.verifyEmailUseCase.execute(req.body);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public checkEmail = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.checkEmailUseCase.execute(req.body.email);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public resendVerification = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.resendVerificationUseCase.execute(req.body);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public login = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const clientIp = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.ip || req.socket.remoteAddress;
      const result = await this.loginUseCase.execute({
        ...req.body,
        ipAddress: clientIp,
      });

      // If 2FA is required, return challenge token without setting refresh cookie
      if (result.twoFactorRequired) {
        res.status(200).json({
          data: result,
        });
        return;
      }

      const isRememberMe = req.body?.rememberMe === true;
      const maxAgeMs = (isRememberMe ? 30 : 7) * 24 * 60 * 60 * 1000;

      // Set hardened httpOnly cookie for web browser sessions
      res.cookie('smartclass_refresh_token', result.refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        path: '/api/v1/auth',
        maxAge: maxAgeMs,
      });

      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public authenticate2fa = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const clientIp = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.ip || req.socket.remoteAddress;
      const result = await this.authenticate2FAUseCase.execute({
        ...req.body,
        ipAddress: clientIp,
      });

      const isRememberMe = req.body?.rememberMe === true;
      const maxAgeMs = (isRememberMe ? 30 : 7) * 24 * 60 * 60 * 1000;

      res.cookie('smartclass_refresh_token', result.refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        path: '/api/v1/auth',
        maxAge: maxAgeMs,
      });

      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public setup2fa = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const result = await this.setup2FAUseCase.execute(req.user.id);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public verify2fa = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const clientIp = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.ip || req.socket.remoteAddress;
      const result = await this.verify2FAUseCase.execute({
        userId: req.user.id,
        code: req.body.code,
        ipAddress: clientIp,
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public disable2fa = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const clientIp = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.ip || req.socket.remoteAddress;
      const result = await this.disable2FAUseCase.execute({
        userId: req.user.id,
        code: req.body.code,
        password: req.body.password,
        ipAddress: clientIp,
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public getAuditLogs = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 20));
      const result = await this.getAuditLogsUseCase.execute(req.user.id, limit);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public refreshToken = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      // 1. Try body refreshToken
      let refreshToken = req.body?.refreshToken;

      // 2. Fallback to httpOnly cookie if body is omitted or empty
      if (!refreshToken && req.headers.cookie) {
        const match = req.headers.cookie.match(/smartclass_refresh_token=([^;]+)/);
        if (match && match[1]) {
          refreshToken = decodeURIComponent(match[1].trim());
        }
      }

      if (!refreshToken) {
        throw new UnauthorizedError('Refresh token is required', ErrorCodes.AUTH_TOKEN_INVALID);
      }

      const result = await this.refreshTokenUseCase.execute({ refreshToken });

      // Rotate the cookie
      res.cookie('smartclass_refresh_token', result.refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        path: '/api/v1/auth',
      });

      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public forgotPassword = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.forgotPasswordUseCase.execute(req.body);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public resetPassword = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.resetPasswordUseCase.execute(req.body);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public logout = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      let refreshToken = req.body?.refreshToken;
      if (!refreshToken && req.headers.cookie) {
        const match = req.headers.cookie.match(/smartclass_refresh_token=([^;]+)/);
        if (match && match[1]) {
          refreshToken = decodeURIComponent(match[1].trim());
        }
      }

      if (refreshToken) {
        await this.logoutUseCase.execute({ refreshToken });
      }

      res.clearCookie('smartclass_refresh_token', {
        path: '/api/v1/auth',
      });

      res.status(200).json({
        data: { message: 'Logged out successfully.' },
      });
    } catch (err) {
      next(err);
    }
  };

  public getMe = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const result = await this.getMeUseCase.execute(req.user.id);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public updateProfile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const result = await this.updateProfileUseCase.execute(req.user.id, req.body);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public changePassword = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const clientIp = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.ip || req.socket.remoteAddress;
      const result = await this.changePasswordUseCase.execute({
        userId: req.user.id,
        currentPassword: req.body.currentPassword,
        newPassword: req.body.newPassword,
        ipAddress: clientIp,
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public getSessions = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const result = await this.getSessionsUseCase.execute(req.user.id);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public revokeSession = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const sessionId = req.params.id as string;
      const result = await this.revokeSessionUseCase.execute(req.user.id, sessionId);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public revokeOtherSessions = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const result = await this.revokeOtherSessionsUseCase.execute(req.user.id);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public freezeAccount = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const result = await this.freezeAccountUseCase.execute(req.user.id);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public deleteAccount = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const { password } = req.body;
      const result = await this.deleteAccountUseCase.execute(req.user.id, password);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };
}

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
      const result = await this.loginUseCase.execute(req.body);

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

  public refreshToken = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      // 1. Try body refreshToken
      let refreshToken = req.body?.refreshToken;

      // 2. Fallback to httpOnly cookie if body is omitted or empty
      if (!refreshToken && req.headers.cookie) {
        const match = req.headers.cookie.match(/smartclass_refresh_token=([^;]+)/);
        if (match) {
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
        if (match) {
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
}

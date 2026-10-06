import type { Request, Response, NextFunction } from 'express';
import type { RegisterUseCase } from '../application/register.use-case.js';
import type { VerifyEmailUseCase } from '../application/verify-email.use-case.js';
import type { ResendVerificationUseCase } from '../application/resend-verification.use-case.js';
import type { LoginUseCase } from '../application/login.use-case.js';
import type { RefreshTokenUseCase } from '../application/refresh-token.use-case.js';
import type { ForgotPasswordUseCase } from '../application/forgot-password.use-case.js';
import type { ResetPasswordUseCase } from '../application/reset-password.use-case.js';
import type { LogoutUseCase } from '../application/logout.use-case.js';
import type { GetMeUseCase } from '../application/get-me.use-case.js';
import { UnauthorizedError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export class AuthController {
  constructor(
    private readonly registerUseCase: RegisterUseCase,
    private readonly verifyEmailUseCase: VerifyEmailUseCase,
    private readonly resendVerificationUseCase: ResendVerificationUseCase,
    private readonly loginUseCase: LoginUseCase,
    private readonly refreshTokenUseCase: RefreshTokenUseCase,
    private readonly forgotPasswordUseCase: ForgotPasswordUseCase,
    private readonly resetPasswordUseCase: ResetPasswordUseCase,
    private readonly logoutUseCase: LogoutUseCase,
    private readonly getMeUseCase: GetMeUseCase,
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
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public refreshToken = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.refreshTokenUseCase.execute(req.body);
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
      const result = await this.logoutUseCase.execute(req.body);
      res.status(200).json({
        data: result,
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
}

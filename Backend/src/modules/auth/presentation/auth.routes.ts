import { Router, type RequestHandler } from 'express';
import type { AuthController } from './auth.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import {
  registerSchema,
  loginSchema,
  verifyEmailSchema,
  resendVerificationSchema,
  refreshTokenSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  logoutSchema,
  updateProfileSchema,
} from './auth.validation.js';

export interface AuthRouterOptions {
  controller: AuthController;
  authenticateMiddleware: RequestHandler;
  authRateLimiter?: RequestHandler;
}

export const createAuthRouter = (options: AuthRouterOptions): Router => {
  const router = Router();
  const { controller, authenticateMiddleware, authRateLimiter } = options;

  const rateLimitMw = authRateLimiter ? [authRateLimiter] : [];

  router.post(
    '/register',
    ...rateLimitMw,
    validate({ body: registerSchema }),
    controller.register,
  );

  router.post(
    '/verify-email',
    validate({ body: verifyEmailSchema }),
    controller.verifyEmail,
  );

  router.post(
    '/resend-verification',
    ...rateLimitMw,
    validate({ body: resendVerificationSchema }),
    controller.resendVerification,
  );

  router.post(
    '/login',
    ...rateLimitMw,
    validate({ body: loginSchema }),
    controller.login,
  );

  router.post(
    '/refresh',
    validate({ body: refreshTokenSchema }),
    controller.refreshToken,
  );

  router.post(
    '/forgot-password',
    ...rateLimitMw,
    validate({ body: forgotPasswordSchema }),
    controller.forgotPassword,
  );

  router.post(
    '/reset-password',
    validate({ body: resetPasswordSchema }),
    controller.resetPassword,
  );

  router.post(
    '/logout',
    validate({ body: logoutSchema }),
    controller.logout,
  );

  router.get(
    '/me',
    authenticateMiddleware,
    controller.getMe,
  );

  router.get(
    '/profile',
    authenticateMiddleware,
    controller.getMe,
  );

  router.patch(
    '/profile',
    authenticateMiddleware,
    validate({ body: updateProfileSchema }),
    controller.updateProfile,
  );

  return router;
};

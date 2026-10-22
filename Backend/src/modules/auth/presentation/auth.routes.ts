import { Router, type RequestHandler } from 'express';
import type { AuthController } from './auth.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import {
  registerSchema,
  loginSchema,
  verifyEmailSchema,
  checkEmailSchema,
  resendVerificationSchema,
  refreshTokenSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  logoutSchema,
  updateProfileSchema,
  verify2faSchema,
  disable2faSchema,
  authenticate2faSchema,
  changePasswordSchema,
  deleteAccountSchema,
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
    '/check-email',
    ...rateLimitMw,
    validate({ body: checkEmailSchema }),
    controller.checkEmail,
  );

  router.post(
    '/login',
    ...rateLimitMw,
    validate({ body: loginSchema }),
    controller.login,
  );

  // 2FA login completion endpoint (after password check returns twoFactorRequired: true)
  router.post(
    '/2fa/authenticate',
    ...rateLimitMw,
    validate({ body: authenticate2faSchema }),
    controller.authenticate2fa,
  );

  // 2FA Setup, Verify, Disable (requires authenticated session)
  router.post(
    '/2fa/setup',
    authenticateMiddleware,
    controller.setup2fa,
  );

  router.post(
    '/2fa/verify',
    authenticateMiddleware,
    validate({ body: verify2faSchema }),
    controller.verify2fa,
  );

  router.post(
    '/2fa/disable',
    authenticateMiddleware,
    validate({ body: disable2faSchema }),
    controller.disable2fa,
  );

  // Security audit logs for the authenticated user
  router.get(
    '/audit-logs',
    authenticateMiddleware,
    controller.getAuditLogs,
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

  router.post(
    '/change-password',
    authenticateMiddleware,
    validate({ body: changePasswordSchema }),
    controller.changePassword,
  );

  router.get(
    '/sessions',
    authenticateMiddleware,
    controller.getSessions,
  );

  router.delete(
    '/sessions/:id',
    authenticateMiddleware,
    controller.revokeSession,
  );

  router.delete(
    '/sessions',
    authenticateMiddleware,
    controller.revokeOtherSessions,
  );

  router.post(
    '/freeze-account',
    authenticateMiddleware,
    controller.freezeAccount,
  );

  router.post(
    '/delete-account',
    authenticateMiddleware,
    validate({ body: deleteAccountSchema }),
    controller.deleteAccount,
  );

  router.delete(
    '/delete-account',
    authenticateMiddleware,
    validate({ body: deleteAccountSchema }),
    controller.deleteAccount,
  );

  return router;
};

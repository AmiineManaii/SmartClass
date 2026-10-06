import { z } from 'zod';

const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_\-#])[A-Za-z\d@$!%*?&_\-#]{8,}$/;
const passwordMessage =
  'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one digit, and one special character (@$!%*?&_-#)';

export const roleSchema = z.preprocess((val) => {
  if (typeof val !== 'string') return val;
  const normalized = val.trim().toUpperCase();
  if (
    normalized === 'PROFESOR' ||
    normalized === 'PROFESSEUR' ||
    normalized === 'ENSEIGNANT' ||
    normalized === 'TEACHER'
  ) {
    return 'TEACHER';
  }
  if (
    normalized === 'STUDENT' ||
    normalized === 'ETUDIANT' ||
    normalized === 'ÉTUDIANT'
  ) {
    return 'STUDENT';
  }
  if (normalized === 'ADMIN' || normalized === 'ADMINISTRATEUR') {
    return 'ADMIN';
  }
  return normalized;
}, z.enum(['TEACHER', 'STUDENT', 'ADMIN']));

export const registerSchema = z
  .object({
    email: z.string().trim().email('Invalid email address').max(255),
    password: z.string().min(8, 'Password must be at least 8 characters long').regex(passwordRegex, passwordMessage),
    firstName: z.string().trim().min(2, 'First name must be at least 2 characters').max(100),
    lastName: z.string().trim().min(2, 'Last name must be at least 2 characters').max(100),
    role: roleSchema.default('STUDENT'),
  })
  .strict();

export const loginSchema = z
  .object({
    email: z.string().trim().email('Invalid email address'),
    password: z.string().min(1, 'Password is required'),
  })
  .strict();

export const verifyEmailSchema = z
  .object({
    email: z.string().trim().email('Invalid email address'),
    code: z
      .string()
      .trim()
      .length(6, 'Verification code must be exactly 6 digits')
      .regex(/^\d{6}$/, 'Verification code must contain only digits'),
  })
  .strict();

export const resendVerificationSchema = z
  .object({
    email: z.string().trim().email('Invalid email address'),
  })
  .strict();

export const refreshTokenSchema = z
  .object({
    refreshToken: z.string().trim().min(10, 'Invalid refresh token format'),
  })
  .strict();

export const forgotPasswordSchema = z
  .object({
    email: z.string().trim().email('Invalid email address'),
  })
  .strict();

export const resetPasswordSchema = z
  .object({
    email: z.string().trim().email('Invalid email address'),
    code: z
      .string()
      .trim()
      .length(6, 'Reset code must be exactly 6 digits')
      .regex(/^\d{6}$/, 'Reset code must contain only digits'),
    newPassword: z.string().min(8, 'Password must be at least 8 characters long').regex(passwordRegex, passwordMessage),
  })
  .strict();

export const logoutSchema = z
  .object({
    refreshToken: z.string().trim().optional(),
  })
  .strict();

export const updateProfileSchema = z
  .object({
    firstName: z.string().trim().min(2, 'First name must be at least 2 characters').max(100).optional(),
    lastName: z.string().trim().min(2, 'Last name must be at least 2 characters').max(100).optional(),
    birthDate: z
      .string()
      .regex(/^\d{4}-\d{2}-\d{2}$/, 'Birth date must be in YYYY-MM-DD format')
      .nullable()
      .optional(),
    onboardingCompleted: z.boolean().optional(),
  })
  .strict();

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type VerifyEmailInput = z.infer<typeof verifyEmailSchema>;
export type ResendVerificationInput = z.infer<typeof resendVerificationSchema>;
export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>;
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;
export type LogoutInput = z.infer<typeof logoutSchema>;
export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;

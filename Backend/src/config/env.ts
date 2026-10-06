import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  CORS_ORIGINS: z
    .string()
    .default('http://localhost:3000,http://localhost:5000')
    .transform((val) =>
      val
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean),
    ),
  TRUST_PROXY: z.string().default('0'),
  RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(60000),
  RATE_LIMIT_MAX: z.coerce.number().int().positive().default(100),
  // Auth configuration
  JWT_SECRET: z
    .string()
    .min(32, 'JWT_SECRET must be at least 32 characters long')
    .default('smartclass-super-secret-jwt-key-min-32-chars-2026!'),
  JWT_ACCESS_EXPIRATION: z.string().default('15m'),
  JWT_REFRESH_EXPIRATION_DAYS: z.coerce.number().int().positive().default(7),
  LOCKOUT_MAX_ATTEMPTS: z.coerce.number().int().positive().default(3),
  LOCKOUT_DURATION_MINUTES: z.coerce.number().int().positive().default(5),
  VERIFICATION_CODE_EXPIRATION_MINUTES: z.coerce.number().int().positive().default(15),
  PASSWORD_RESET_EXPIRATION_MINUTES: z.coerce.number().int().positive().default(15),
  // SMTP Email configuration
  SMTP_HOST: z.string().default('smtp.gmail.com'),
  SMTP_PORT: z.coerce.number().int().positive().default(587),
  SMTP_SECURE: z
    .preprocess((val) => val === 'true' || val === true, z.boolean())
    .default(false),
  SMTP_USER: z.string().default('faroukmessay006@gmail.com'),
  SMTP_PASS: z.string().optional().default(''),
  SMTP_FROM: z.string().default('SmartClass <faroukmessay006@gmail.com>'),
});

export type Env = z.infer<typeof envSchema>;

export const parseEnv = (rawEnv: NodeJS.ProcessEnv = process.env): Env => {
  const result = envSchema.safeParse(rawEnv);

  if (!result.success) {
    const formattedErrors = result.error.errors
      .map((err) => `  - ${err.path.join('.')}: ${err.message}`)
      .join('\n');
    console.error(`\x1b[31m[CONFIG ERROR] Invalid environment variables:\n${formattedErrors}\x1b[0m`);
    throw new Error(`Invalid environment variables:\n${formattedErrors}`);
  }

  return result.data;
};

// Fail-fast singleton for application runtime
let cachedEnv: Env | null = null;

export const getEnv = (): Env => {
  if (!cachedEnv) {
    cachedEnv = parseEnv(process.env);
  }
  return cachedEnv;
};

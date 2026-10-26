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
  LOCKOUT_DURATION_MINUTES: z.coerce.number().int().positive().default(1),
  VERIFICATION_CODE_EXPIRATION_MINUTES: z.coerce.number().int().positive().default(15),
  PASSWORD_RESET_EXPIRATION_MINUTES: z.coerce.number().int().positive().default(15),
  // SMTP Email configuration
  SMTP_HOST: z.string().default('smtp.gmail.com'),
  SMTP_PORT: z.coerce.number().int().positive().default(587),
  SMTP_SECURE: z.preprocess((val) => val === 'true' || val === true, z.boolean()).default(false),
  SMTP_USER: z.string().default('faroukmessay006@gmail.com'),
  SMTP_PASS: z.string().optional().default(''),
  SMTP_FROM: z.string().default('SmartClass <faroukmessay006@gmail.com>'),
  // Local LLM gateway (Ollama, OpenAI-compatible API).
  AI_BASE_URL: z.string().default('http://host.docker.internal:11434'),
  AI_MODEL: z.string().default('hf.co/unsloth/Qwen3.5-4B-GGUF:Q4_1'),
  // Fallback Ollama model when the primary model is unreachable or errors.
  AI_FALLBACK_MODEL: z.string().default('hf.co/unsloth/Qwen3.5-9B-GGUF:UD-Q2_K_XL'),
  AI_API_KEY: z.string().optional().default(''),
  AI_TIMEOUT_MS: z.coerce.number().int().positive().default(300000),
  AI_STATUS_TIMEOUT_MS: z.coerce.number().int().positive().default(5000),
  AI_MAX_TOKENS: z.coerce.number().int().positive().default(32768),
  AI_TEMPERATURE: z.coerce.number().min(0).max(2).default(0.7),
  AI_MAX_SOURCE_CHARS: z.coerce.number().int().positive().default(16000),
  AI_ENABLE_WEB_SEARCH: z
    .preprocess((val) => val === 'true' || val === true, z.boolean())
    .default(true),
  AI_ENABLE_THINKING: z
    .preprocess((val) => val === 'true' || val === true, z.boolean())
    .default(true),
  AI_MAX_TOOL_ITERATIONS: z.coerce.number().int().positive().default(10),
  // Local embedding server (Ollama, RG27 — no third-party LLM APIs).
  // EmbeddingGemma outputs 768-dim vectors (course_passages.embedding).
  EMBEDDING_BASE_URL: z.string().default('http://host.docker.internal:11434'),
  EMBEDDING_MODEL: z.string().default('embeddinggemma-2'),
  EMBEDDING_TIMEOUT_MS: z.coerce.number().int().positive().default(10000),
  // Optional Ollama official API key for cloud search/inference upgrade.
  OLLAMA_API_KEY: z.string().optional().default(''),
  // ComfyUI image generation (section illustrations, SDXL workflow
  // image_sdxl_simple.json at 512x512). Empty = disabled: the adapter
  // answers IMAGE_SERVICE_UNAVAILABLE. This base is the origin the BACKEND
  // calls (from its container: host.docker.internal works, LAN IP may not).
  COMFYUI_BASE_URL: z.string().optional().default(''),
  // Origin embedded in the imageUrl returned to the app, which resolves the
  // host itself (host.docker.internal is Docker-only). Empty = reuse
  // COMFYUI_BASE_URL. Use your LAN IP when testing from a device (ComfyUI
  // must then listen on 0.0.0.0).
  COMFYUI_PUBLIC_URL: z.string().optional().default(''),
  // SearxNG instance for web image search (inside Docker: http://searxng:8080 or http://localhost:8080)
  SEARXNG_URL: z.string().default('http://searxng:8080'),
  // Model for search prompt reformulation (sam860/lucy:1.7b)
  OLLAMA_REFORMULATE_MODEL: z.string().default('sam860/lucy:1.7b'),
  // LiveKit WebRTC SFU configuration
  LIVEKIT_URL: z.string().optional().default(''),
  LIVEKIT_PUBLIC_URL: z.string().optional().default(''),
  LIVEKIT_API_KEY: z.string().optional().default(''),
  LIVEKIT_API_SECRET: z
    .string()
    .optional()
    .refine((val) => !val || val.length >= 32, {
      message: 'LIVEKIT_API_SECRET must be at least 32 characters when provided',
    })
    .default(''),
  LIVEKIT_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(600),
  SESSION_JOIN_OPENS_MINUTES: z.coerce.number().int().positive().default(5),
  SESSION_EMPTY_ROOM_TIMEOUT_MINUTES: z.coerce.number().int().positive().default(10),
});

export type Env = z.infer<typeof envSchema>;

export const parseEnv = (rawEnv: NodeJS.ProcessEnv = process.env): Env => {
  const result = envSchema.safeParse(rawEnv);

  if (!result.success) {
    const formattedErrors = result.error.errors
      .map((err) => `  - ${err.path.join('.')}: ${err.message}`)
      .join('\n');
    console.error(
      `\x1b[31m[CONFIG ERROR] Invalid environment variables:\n${formattedErrors}\x1b[0m`,
    );
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

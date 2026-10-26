import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

describe('Env Config', () => {
  const validEnv = {
    NODE_ENV: 'development',
    PORT: '3000',
    LOG_LEVEL: 'info',
    DATABASE_URL: 'postgresql://user:pass@localhost:5432/db',
    CORS_ORIGINS: 'http://localhost:3000,http://localhost:5000',
    TRUST_PROXY: '0',
    RATE_LIMIT_WINDOW_MS: '60000',
    RATE_LIMIT_MAX: '100',
  };

  const originalEnv = process.env;

  beforeEach(() => {
    vi.resetModules();
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it('parses a valid environment', async () => {
    const { parseEnv } = await import('../../src/config/env.js');
    const result = parseEnv(validEnv as unknown as NodeJS.ProcessEnv);

    expect(result.NODE_ENV).toBe('development');
    expect(result.PORT).toBe(3000);
    expect(result.LOG_LEVEL).toBe('info');
    expect(result.DATABASE_URL).toBe('postgresql://user:pass@localhost:5432/db');
    expect(result.CORS_ORIGINS).toEqual(['http://localhost:3000', 'http://localhost:5000']);
    expect(result.RATE_LIMIT_WINDOW_MS).toBe(60000);
    expect(result.RATE_LIMIT_MAX).toBe(100);
  });

  it('applies defaults for optional values', async () => {
    const { parseEnv } = await import('../../src/config/env.js');
    const minimal = {
      DATABASE_URL: 'postgresql://user:pass@localhost:5432/db',
    };
    const result = parseEnv(minimal as unknown as NodeJS.ProcessEnv);

    expect(result.NODE_ENV).toBe('development');
    expect(result.PORT).toBe(3000);
    expect(result.LOG_LEVEL).toBe('info');
    expect(result.RATE_LIMIT_WINDOW_MS).toBe(60000);
    expect(result.RATE_LIMIT_MAX).toBe(100);
  });

  it('throws on missing DATABASE_URL', async () => {
    const { parseEnv } = await import('../../src/config/env.js');
    const noDb = { ...validEnv } as Record<string, string>;
    delete noDb.DATABASE_URL;

    expect(() => parseEnv(noDb as unknown as NodeJS.ProcessEnv)).toThrow();
  });

  it('throws on invalid NODE_ENV', async () => {
    const { parseEnv } = await import('../../src/config/env.js');
    const badNodeEnv = { ...validEnv, NODE_ENV: 'staging' };

    expect(() => parseEnv(badNodeEnv as unknown as NodeJS.ProcessEnv)).toThrow();
  });

  it('coerces PORT from string to number', async () => {
    const { parseEnv } = await import('../../src/config/env.js');
    const result = parseEnv({ ...validEnv, PORT: '8080' } as unknown as NodeJS.ProcessEnv);
    expect(result.PORT).toBe(8080);
  });

  it('splits CORS_ORIGINS into array', async () => {
    const { parseEnv } = await import('../../src/config/env.js');
    const result = parseEnv({
      ...validEnv,
      CORS_ORIGINS: 'http://a.com, http://b.com , http://c.com',
    } as unknown as NodeJS.ProcessEnv);
    expect(result.CORS_ORIGINS).toEqual(['http://a.com', 'http://b.com', 'http://c.com']);
  });

  it('sets defaults for LiveKit environment variables', async () => {
    const { parseEnv } = await import('../../src/config/env.js');
    const result = parseEnv(validEnv as unknown as NodeJS.ProcessEnv);

    expect(result.LIVEKIT_URL).toBe('');
    expect(result.LIVEKIT_PUBLIC_URL).toBe('');
    expect(result.LIVEKIT_API_KEY).toBe('');
    expect(result.LIVEKIT_API_SECRET).toBe('');
    expect(result.LIVEKIT_TOKEN_TTL_SECONDS).toBe(600);
    expect(result.SESSION_JOIN_OPENS_MINUTES).toBe(5);
    expect(result.SESSION_EMPTY_ROOM_TIMEOUT_MINUTES).toBe(10);
  });

  it('validates LIVEKIT_API_SECRET requires minimum 32 chars when provided', async () => {
    const { parseEnv } = await import('../../src/config/env.js');
    expect(() =>
      parseEnv({
        ...validEnv,
        LIVEKIT_API_SECRET: 'short-secret',
      } as unknown as NodeJS.ProcessEnv),
    ).toThrow();

    const result = parseEnv({
      ...validEnv,
      LIVEKIT_API_SECRET: 'a'.repeat(32),
    } as unknown as NodeJS.ProcessEnv);
    expect(result.LIVEKIT_API_SECRET).toBe('a'.repeat(32));
  });
});

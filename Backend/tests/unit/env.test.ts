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
});

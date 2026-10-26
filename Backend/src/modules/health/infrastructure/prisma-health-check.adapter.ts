import type {
  HealthCheckPort,
  DatabaseHealthResult,
  LiveKitHealthResult,
} from '../domain/health-check.port.js';
import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import { getEnv } from '../../../config/env.js';

export class PrismaHealthCheckAdapter implements HealthCheckPort {
  private readonly timeoutMs: number;
  private readonly livekitUrlOverride?: string;

  constructor(timeoutMs = 3000, livekitUrlOverride?: string) {
    this.timeoutMs = timeoutMs;
    this.livekitUrlOverride = livekitUrlOverride;
  }

  public async checkDatabase(): Promise<DatabaseHealthResult> {
    const start = Date.now();
    const prisma = getPrismaClient();

    try {
      const timeoutPromise = new Promise<never>((_, reject) =>
        setTimeout(
          () => reject(new Error(`Database health check timed out after ${this.timeoutMs}ms`)),
          this.timeoutMs,
        ),
      );

      const queryPromise = prisma.$queryRaw`SELECT 1`;

      await Promise.race([queryPromise, timeoutPromise]);
      const latencyMs = Date.now() - start;

      return {
        isHealthy: true,
        latencyMs,
      };
    } catch (err) {
      const latencyMs = Date.now() - start;
      const errorMessage = err instanceof Error ? err.message : 'Unknown database error';

      return {
        isHealthy: false,
        latencyMs,
        error: errorMessage,
      };
    }
  }

  public async checkLiveKit(): Promise<LiveKitHealthResult> {
    const url = this.livekitUrlOverride ?? getEnv().LIVEKIT_URL;
    if (!url || url.trim() === '') {
      return { status: 'not_configured' };
    }

    const start = Date.now();
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeoutMs);
      try {
        await fetch(url, { signal: controller.signal });
      } finally {
        clearTimeout(timeoutId);
      }
      return {
        status: 'up',
        latencyMs: Date.now() - start,
      };
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'LiveKit connection failed';
      return {
        status: 'down',
        error: errorMessage,
      };
    }
  }
}

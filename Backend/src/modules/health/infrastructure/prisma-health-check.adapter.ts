import type { HealthCheckPort, DatabaseHealthResult } from '../domain/health-check.port.js';
import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';

export class PrismaHealthCheckAdapter implements HealthCheckPort {
  private readonly timeoutMs: number;

  constructor(timeoutMs = 3000) {
    this.timeoutMs = timeoutMs;
  }

  public async checkDatabase(): Promise<DatabaseHealthResult> {
    const start = Date.now();
    const prisma = getPrismaClient();

    try {
      const timeoutPromise = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error(`Database health check timed out after ${this.timeoutMs}ms`)), this.timeoutMs),
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
}

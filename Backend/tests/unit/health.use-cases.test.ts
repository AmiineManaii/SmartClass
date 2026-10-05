import { describe, it, expect } from 'vitest';
import { GetLivenessUseCase } from '../../src/modules/health/application/get-liveness.use-case.js';
import { GetReadinessUseCase } from '../../src/modules/health/application/get-readiness.use-case.js';
import type {
  HealthCheckPort,
  DatabaseHealthResult,
} from '../../src/modules/health/domain/health-check.port.js';
import { ServiceUnavailableError } from '../../src/shared/errors/index.js';

class MockHealthCheckPort implements HealthCheckPort {
  constructor(private readonly result: DatabaseHealthResult) {}

  public async checkDatabase(): Promise<DatabaseHealthResult> {
    return this.result;
  }
}

describe('Health Module Use Cases', () => {
  describe('GetLivenessUseCase', () => {
    it('should return status ok and non-negative uptime', () => {
      const useCase = new GetLivenessUseCase();
      const result = useCase.execute();

      expect(result.status).toBe('ok');
      expect(typeof result.uptime).toBe('number');
      expect(result.uptime).toBeGreaterThanOrEqual(0);
    });
  });

  describe('GetReadinessUseCase', () => {
    it('should return status ok and database latency when database is healthy', async () => {
      const mockPort = new MockHealthCheckPort({
        isHealthy: true,
        latencyMs: 12,
      });
      const useCase = new GetReadinessUseCase(mockPort);

      const result = await useCase.execute();

      expect(result.status).toBe('ok');
      expect(new Date(result.timestamp).toISOString()).toBe(result.timestamp);
      expect(result.services.database.status).toBe('up');
      expect(result.services.database.latencyMs).toBe(12);
    });

    it('should throw ServiceUnavailableError when database is down', async () => {
      const mockPort = new MockHealthCheckPort({
        isHealthy: false,
        latencyMs: 0,
        error: 'Database connection failed: ECONNREFUSED',
      });
      const useCase = new GetReadinessUseCase(mockPort);

      await expect(useCase.execute()).rejects.toThrow(ServiceUnavailableError);

      try {
        await useCase.execute();
      } catch (err) {
        const error = err as ServiceUnavailableError;
        expect(error.statusCode).toBe(503);
        expect(error.code).toBe('SERVICE_UNAVAILABLE');
        expect(error.details).toEqual([
          {
            service: 'database',
            status: 'down',
            error: 'Database connection failed: ECONNREFUSED',
          },
        ]);
      }
    });

    it('should provide default error message if error is omitted on unhealthy status', async () => {
      const mockPort = new MockHealthCheckPort({
        isHealthy: false,
        latencyMs: 0,
      });
      const useCase = new GetReadinessUseCase(mockPort);

      try {
        await useCase.execute();
        expect.unreachable('Should have thrown');
      } catch (err) {
        const error = err as ServiceUnavailableError;
        expect(error.details).toEqual([
          {
            service: 'database',
            status: 'down',
            error: 'Connection failed',
          },
        ]);
      }
    });
  });
});

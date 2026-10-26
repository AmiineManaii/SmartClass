import { describe, it, expect } from 'vitest';
import { GetLivenessUseCase } from '../../src/modules/health/application/get-liveness.use-case.js';
import { GetReadinessUseCase } from '../../src/modules/health/application/get-readiness.use-case.js';
import type {
  HealthCheckPort,
  DatabaseHealthResult,
  LiveKitHealthResult,
} from '../../src/modules/health/domain/health-check.port.js';
import { ServiceUnavailableError } from '../../src/shared/errors/index.js';

class MockHealthCheckPort implements HealthCheckPort {
  constructor(
    private readonly dbResult: DatabaseHealthResult,
    private readonly livekitResult: LiveKitHealthResult = { status: 'up', latencyMs: 5 },
  ) {}

  public async checkDatabase(): Promise<DatabaseHealthResult> {
    return this.dbResult;
  }

  public async checkLiveKit(): Promise<LiveKitHealthResult> {
    return this.livekitResult;
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
    it('should return status ok and service details when database and livekit are healthy', async () => {
      const mockPort = new MockHealthCheckPort(
        { isHealthy: true, latencyMs: 12 },
        { status: 'up', latencyMs: 5 },
      );
      const useCase = new GetReadinessUseCase(mockPort);

      const result = await useCase.execute();

      expect(result.status).toBe('ok');
      expect(new Date(result.timestamp).toISOString()).toBe(result.timestamp);
      expect(result.services.database.status).toBe('up');
      expect(result.services.database.latencyMs).toBe(12);
      expect(result.services.livekit.status).toBe('up');
      expect(result.services.livekit.latencyMs).toBe(5);
    });

    it('should return status ok even when livekit is down (non-critical)', async () => {
      const mockPort = new MockHealthCheckPort(
        { isHealthy: true, latencyMs: 10 },
        { status: 'down', error: 'ECONNREFUSED' },
      );
      const useCase = new GetReadinessUseCase(mockPort);

      const result = await useCase.execute();

      expect(result.status).toBe('ok');
      expect(result.services.database.status).toBe('up');
      expect(result.services.livekit.status).toBe('down');
      expect(result.services.livekit.error).toBe('ECONNREFUSED');
    });

    it('should return status ok when livekit is not configured', async () => {
      const mockPort = new MockHealthCheckPort(
        { isHealthy: true, latencyMs: 8 },
        { status: 'not_configured' },
      );
      const useCase = new GetReadinessUseCase(mockPort);

      const result = await useCase.execute();

      expect(result.status).toBe('ok');
      expect(result.services.database.status).toBe('up');
      expect(result.services.livekit.status).toBe('not_configured');
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

import type { HealthCheckPort } from '../domain/health-check.port.js';
import { ServiceUnavailableError } from '../../../shared/errors/index.js';

export interface ReadinessResult {
  status: 'ok';
  timestamp: string;
  services: {
    database: {
      status: 'up';
      latencyMs: number;
    };
  };
}

export class GetReadinessUseCase {
  constructor(private readonly healthCheckPort: HealthCheckPort) {}

  public async execute(): Promise<ReadinessResult> {
    const dbResult = await this.healthCheckPort.checkDatabase();

    if (!dbResult.isHealthy) {
      throw new ServiceUnavailableError('Database service unavailable', [
        {
          service: 'database',
          status: 'down',
          error: dbResult.error ?? 'Connection failed',
        },
      ]);
    }

    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      services: {
        database: {
          status: 'up',
          latencyMs: dbResult.latencyMs,
        },
      },
    };
  }
}

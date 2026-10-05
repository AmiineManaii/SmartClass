import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import type {
  HealthCheckPort,
  DatabaseHealthResult,
} from '../../src/modules/health/domain/health-check.port.js';

class StubHealthCheckPort implements HealthCheckPort {
  constructor(private result: DatabaseHealthResult) {}

  public setResult(result: DatabaseHealthResult) {
    this.result = result;
  }

  public async checkDatabase(): Promise<DatabaseHealthResult> {
    return this.result;
  }
}

describe('Integration: Health Endpoints', () => {
  it('GET /health/live returns 200 with status ok and uptime', async () => {
    const app = createApp({ skipLogging: true });
    const res = await request(app).get('/health/live');

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      status: 'ok',
      uptime: expect.any(Number),
    });
    expect(res.headers['x-request-id']).toBeDefined();
  });

  it('GET /health/ready returns 200 with database status up when DB is healthy', async () => {
    const port = new StubHealthCheckPort({ isHealthy: true, latencyMs: 5 });
    const app = createApp({
      skipLogging: true,
      healthModuleOptions: { healthCheckPort: port },
    });

    const res = await request(app).get('/health/ready');

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.services.database.status).toBe('up');
    expect(res.body.services.database.latencyMs).toBe(5);
    expect(res.headers['x-request-id']).toBeDefined();
  });

  it('GET /health/ready returns 503 SERVICE_UNAVAILABLE when DB check fails', async () => {
    const port = new StubHealthCheckPort({
      isHealthy: false,
      latencyMs: 0,
      error: 'Connection timed out',
    });
    const app = createApp({
      skipLogging: true,
      healthModuleOptions: { healthCheckPort: port },
    });

    const res = await request(app).get('/health/ready');

    expect(res.status).toBe(503);
    expect(res.body.error).toBeDefined();
    expect(res.body.error.code).toBe('SERVICE_UNAVAILABLE');
    expect(res.body.error.message).toBe('Database service unavailable');
    expect(res.body.error.details).toEqual([
      {
        service: 'database',
        status: 'down',
        error: 'Connection timed out',
      },
    ]);
    expect(res.body.error.requestId).toBeDefined();
  });
});

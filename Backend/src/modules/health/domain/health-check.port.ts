export interface DatabaseHealthResult {
  isHealthy: boolean;
  latencyMs: number;
  error?: string;
}

export interface HealthCheckPort {
  checkDatabase(): Promise<DatabaseHealthResult>;
}

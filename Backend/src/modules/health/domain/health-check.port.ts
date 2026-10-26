export interface DatabaseHealthResult {
  isHealthy: boolean;
  latencyMs: number;
  error?: string;
}

export interface LiveKitHealthResult {
  status: 'up' | 'down' | 'not_configured';
  latencyMs?: number;
  error?: string;
}

export interface HealthCheckPort {
  checkDatabase(): Promise<DatabaseHealthResult>;
  checkLiveKit(): Promise<LiveKitHealthResult>;
}

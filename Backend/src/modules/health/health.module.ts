import { Router } from 'express';
import { PrismaHealthCheckAdapter } from './infrastructure/prisma-health-check.adapter.js';
import { GetLivenessUseCase } from './application/get-liveness.use-case.js';
import { GetReadinessUseCase } from './application/get-readiness.use-case.js';
import { HealthController } from './presentation/health.controller.js';
import { createHealthRouter } from './presentation/health.routes.js';
import type { HealthCheckPort } from './domain/health-check.port.js';

export interface HealthModuleOptions {
  healthCheckPort?: HealthCheckPort;
}

export const createHealthModule = (
  options: HealthModuleOptions = {},
): { router: Router; controller: HealthController } => {
  const healthCheckPort = options.healthCheckPort ?? new PrismaHealthCheckAdapter();
  const getLivenessUseCase = new GetLivenessUseCase();
  const getReadinessUseCase = new GetReadinessUseCase(healthCheckPort);
  const controller = new HealthController(getLivenessUseCase, getReadinessUseCase);
  const router = createHealthRouter(controller);

  return { router, controller };
};

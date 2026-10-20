import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import { getEnv } from '../../config/env.js';

let prismaInstance: PrismaClient | null = null;
let pgPoolInstance: pg.Pool | null = null;

export const getPrismaClient = (): PrismaClient => {
  if (!prismaInstance) {
    const adapter = new PrismaPg(getPgPool());
    prismaInstance = new PrismaClient({ adapter });
  }
  return prismaInstance;
};

export const disconnectPrisma = async (): Promise<void> => {
  if (prismaInstance) {
    await prismaInstance.$disconnect();
    prismaInstance = null;
  }
  if (pgPoolInstance) {
    await pgPoolInstance.end();
    pgPoolInstance = null;
  }
};

/**
 * Shared `pg.Pool`. Exposed so adapters that need raw SQL Prisma cannot
 * express (e.g. pgvector `Unsupported("vector")` columns) can run
 * parameterized queries without opening their own pool.
 */
export const getPgPool = (): pg.Pool => {
  if (!pgPoolInstance) {
    const env = getEnv();
    pgPoolInstance = new pg.Pool({ connectionString: env.DATABASE_URL });
  }
  return pgPoolInstance;
};

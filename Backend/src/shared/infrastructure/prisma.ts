import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import { getEnv } from '../../config/env.js';

let prismaInstance: PrismaClient | null = null;
let pgPoolInstance: pg.Pool | null = null;

export const getPrismaClient = (): PrismaClient => {
  if (!prismaInstance) {
    const env = getEnv();
    pgPoolInstance = new pg.Pool({ connectionString: env.DATABASE_URL });
    const adapter = new PrismaPg(pgPoolInstance);
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

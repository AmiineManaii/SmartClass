/// <reference types="node" />
import * as fs from 'node:fs';
import * as path from 'node:path';
import * as process from 'node:process';
import { defineConfig } from 'prisma/config';

// Automatically load .env if process.env.DATABASE_URL is not set
if (!process.env.DATABASE_URL) {
  const envPath = path.resolve(process.cwd(), '.env');
  if (fs.existsSync(envPath)) {
    try {
      process.loadEnvFile(envPath);
    } catch {
      // ignore
    }
  }
}

let dbUrl = process.env.DATABASE_URL;
// When running directly on the host (outside Docker network), map container hostname 'db' to localhost
const isInsideDocker = fs.existsSync('/.dockerenv');
if (!isInsideDocker && dbUrl && dbUrl.includes('@db:5432')) {
  dbUrl = dbUrl.replace('@db:5432', '@127.0.0.1:5432');
}

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
  },
  datasource: {
    url: dbUrl || 'postgresql://smartclass:smartclass_dev_password@127.0.0.1:5432/smartclass',
  },
});

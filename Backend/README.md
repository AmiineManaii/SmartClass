# SmartClass Backend

Backend REST API for **SmartClass**, built with Node.js 24 LTS, Express 5, TypeScript (strict ESM), Prisma 7 ORM, and PostgreSQL 17 with `pgvector`.

---

## Architecture Overview

The backend follows **Clean Architecture** and **Hexagonal Architecture** principles, partitioned into modular bounded contexts:

```
Backend/
├── prisma/
│   ├── migrations/            # Version-controlled SQL migrations
│   ├── schema.prisma          # Prisma schema (PostgreSQL 17 + pgvector)
│   └── prisma.config.ts       # Prisma 7 configuration file
├── src/
│   ├── config/                # Fail-fast environment variable validation (Zod)
│   ├── modules/               # Bounded contexts (Clean Architecture)
│   │   ├── health/            # Reference module (Domain, Application, Infra, Presentation)
│   │   └── auth/              # Auth module (Argon2id, OTP, Lockout, Token Rotation)
│   ├── shared/                # Shared kernel
│   │   ├── errors/            # Standardized AppError hierarchy
│   │   ├── http/              # Middlewares: requestId, errorHandler, notFound, validate, rateLimiter
│   │   │   └── pagination/    # Offset & cursor keyset pagination helpers
│   │   └── infrastructure/    # Singleton Prisma client, Pino logger with redaction
│   ├── app.ts                 # Express application factory (createApp)
│   ├── main.ts                # Bootstrap & graceful shutdown (SIGINT/SIGTERM)
│   └── routes.ts              # API v1 routes aggregation
└── tests/
    ├── unit/                  # Fast in-memory unit tests (Vitest)
    └── integration/           # HTTP integration tests (Supertest)
```

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [Node.js](https://nodejs.org/) v24.x LTS (for local development)
- [npm](https://www.npmjs.com/) v10+

---

## Quick Start (Docker)

1. **Configure Environment**:
   ```bash
   cp .env.example .env
   ```

2. **Start Services** (Postgres + pgvector and API in development mode):
   ```bash
   docker compose up -d --build
   ```

3. **Verify Health**:
   ```bash
   # Liveness check
   curl http://localhost:3000/health/live

   # Readiness check (verifies database connectivity)
   curl http://localhost:3000/health/ready
   ```

4. **Stop Services**:
   ```bash
   docker compose down
   # Or to purge database volume:
   docker compose down -v
   ```

---

## Local Development (Without Docker for Node)

If running PostgreSQL locally or via Docker:

1. **Install Dependencies**:
   ```bash
   npm install
   ```

2. **Run Migrations & Generate Prisma Client**:
   ```bash
   npm run db:migrate
   ```

3. **Start Development Server**:
   ```bash
   npm run dev
   ```

---

## Available Scripts

| Script | Description |
|---|---|
| `npm run dev` | Starts server with live-reloading via `tsx watch` |
| `npm run build` | Compiles TypeScript to `dist/` |
| `npm start` | Runs compiled production server (`node dist/main.js`) |
| `npm test` | Runs all unit and integration tests via `vitest run` |
| `npm run test:watch` | Runs Vitest in watch mode |
| `npm run lint` | Lints codebase with ESLint (flat config) |
| `npm run typecheck` | Validates TypeScript types (`tsc --noEmit`) |
| `npm run db:migrate` | Runs database migrations in development (`prisma migrate dev`) |
| `npm run db:deploy` | Applies pending migrations in production (`prisma migrate deploy`) |

---

## Environment Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `NODE_ENV` | `development \| test \| production` | `development` | Runtime environment |
| `PORT` | `number` | `3000` | HTTP listening port |
| `LOG_LEVEL` | `string` | `info` | Logging verbosity (`debug`, `info`, `warn`, `error`) |
| `DATABASE_URL` | `string` | **Required** | PostgreSQL connection URL |
| `CORS_ORIGINS` | `string` (comma-separated) | `http://localhost:3000,http://localhost:5000` | Allowed CORS origins |
| `TRUST_PROXY` | `string` | `0` | Express reverse proxy trust setting |
| `RATE_LIMIT_WINDOW_MS` | `number` | `60000` | Rate limit window in ms (1 minute) |
| `RATE_LIMIT_MAX` | `number` | `100` | Max requests per IP per window on `/api/v1` |
| `JWT_SECRET` | `string` (min 32 chars) | Dev fallback | Secret used to sign HS256 JWT access tokens |
| `JWT_ACCESS_EXPIRATION` | `string` | `15m` | Lifetime of short-lived JWT access tokens |
| `JWT_REFRESH_EXPIRATION_DAYS` | `number` | `30` | Refresh token duration in days |
| `LOCKOUT_MAX_ATTEMPTS` | `number` | `3` | Max consecutive wrong password attempts before lockout |
| `LOCKOUT_DURATION_MINUTES` | `number` | `5` | Lockout duration in minutes (HTTP 423) |
| `VERIFICATION_CODE_EXPIRATION_MINUTES` | `number` | `15` | Expiration of email OTP verification code |
| `PASSWORD_RESET_EXPIRATION_MINUTES` | `number` | `15` | Expiration of password reset OTP code |
| `SMTP_HOST` | `string` | `smtp.gmail.com` | SMTP email gateway host |
| `SMTP_PORT` | `number` | `587` | SMTP port |
| `SMTP_SECURE` | `boolean` | `false` | TLS secure connection |
| `SMTP_USER` | `string` | `faroukmessay006@gmail.com` | SMTP authenticated email username |
| `SMTP_PASS` | `string` | Empty (dev fallback) | Gmail App Password (16 characters) |
| `SMTP_FROM` | `string` | `SmartClass <faroukmessay006@gmail.com>` | Sender header address |

---

## Authentication Endpoints (Sprint 1, UC8)

All authentication endpoints are mounted under `/api/v1/auth`. Supports **3 account roles**: `STUDENT` (Étudiant), `TEACHER` (Professeur), `ADMIN` (Administrateur).

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/api/v1/auth/register` | Register user (`STUDENT`, `TEACHER`, or `ADMIN`), sends 6-digit email OTP | No |
| `POST` | `/api/v1/auth/verify-email` | Verify email with OTP, marks account verified | No |
| `POST` | `/api/v1/auth/resend-verification` | Request a new verification OTP | No |
| `POST` | `/api/v1/auth/login` | Login with email + password (3 failed attempts -> 5 min lockout) | No |
| `POST` | `/api/v1/auth/refresh` | Rotate refresh token with session reuse detection | No |
| `POST` | `/api/v1/auth/forgot-password` | Request 6-digit password reset OTP (constant-time response) | No |
| `POST` | `/api/v1/auth/reset-password` | Reset password using email OTP, revokes all sessions | No |
| `POST` | `/api/v1/auth/logout` | Revoke current refresh token session | No |
| `GET` | `/api/v1/auth/me` | Fetch authenticated user profile | Yes (`Bearer <token>`) |
| `GET` | `/api/v1/auth/profile` | Fetch complete account & profile data for mobile screen | Yes (`Bearer <token>`) |
| `PATCH` | `/api/v1/auth/profile` | Update account profile (`firstName`, `lastName`, `birthDate`, `onboardingCompleted`) | Yes (`Bearer <token>`) |

---

## API Contracts & Documentation

Hand-written OpenAPI 3.1 specifications are located in [`contracts/`](../contracts/):
- [`contracts/README.md`](../contracts/README.md): Index and contract-first guidelines
- [`contracts/common.yaml`](../contracts/common.yaml): Standard error envelopes, pagination, security schemas
- [`contracts/health.openapi.yaml`](../contracts/health.openapi.yaml): Health module specification
- [`contracts/auth.openapi.yaml`](../contracts/auth.openapi.yaml): Authentication & security specification

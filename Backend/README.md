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
| `SMTP_USER` | `string` | `user@example.com` | SMTP authenticated email username |
| `SMTP_PASS` | `string` | Empty (dev fallback) | Gmail App Password (16 characters) |
| `SMTP_FROM` | `string` | `SmartClass <noreply@smartclass.local>` | Sender header address |
| `LIVEKIT_URL` | `string` | Empty / `http://livekit:7880` | Internal LiveKit SFU signaling URL for backend |
| `LIVEKIT_PUBLIC_URL` | `string` | Empty / `ws://localhost:7880` | Public LiveKit SFU URL advertised to Flutter clients |
| `LIVEKIT_API_KEY` | `string` | Empty / `devkey` | LiveKit API Key for room management and token minting |
| `LIVEKIT_API_SECRET` | `string` | Empty (min 32 chars) | LiveKit API Secret |
| `LIVEKIT_TOKEN_TTL_SECONDS` | `number` | `600` | Token time-to-live in seconds (10 minutes) |
| `SESSION_JOIN_OPENS_MINUTES` | `number` | `5` | Minutes prior to start when students can join lobby |
| `SESSION_EMPTY_ROOM_TIMEOUT_MINUTES` | `number` | `10` | Timeout before an empty room is collected by LiveKit |

---

## LiveKit WebRTC SFU Setup & Production Deployment

SmartClass utilizes a self-hosted [LiveKit](https://livekit.io/) SFU server (`livekit/livekit-server:v1.13.10`) for live group video sessions with full RG27 data privacy compliance.

### Port & Protocol Specifications

| Port | Protocol | Scope | Purpose |
|---|---|---|---|
| **7880** | TCP (HTTP/WS) | Public / Ingress | Signaling, client WebSocket connection, Server SDK API |
| **7881** | TCP | Public / Ingress | ICE over TCP fallback for restrictive corporate/campus firewalls |
| **7882** | UDP | Public / Ingress | ICE UDP multiplexer (transports all WebRTC audio/video/screen tracks) |
| **3478** | UDP | Public / Ingress | Built-in TURN server for mobile carrier symmetric NAT traversal |
| **5349** | TLS / TCP | Public / Ingress | Built-in TURNS (TURN over TLS) |

### Production Deployment & Hardening Guidelines

1. **Mandatory HTTPS & WSS for Web**:
   - WebRTC APIs (`navigator.mediaDevices.getUserMedia`, `getDisplayMedia`) are blocked by modern browsers (Chrome, Firefox, Safari) on insecure origins (HTTP/WS) except on `localhost`.
   - Production requires valid TLS certificates (e.g., via Let's Encrypt / Certbot / Caddy reverse proxy) with `https://` for the API and `wss://` for LiveKit signaling.
2. **DNS & Public URL Configuration**:
   - Set `LIVEKIT_URL=http://livekit:7880` for backend container-to-container calls.
   - Set `LIVEKIT_PUBLIC_URL=wss://live.smartclass.yourdomain.com` for client connections.
   - In `livekit.yaml`, set `rtc.use_external_ip: true` in production or specify `rtc.node_ip: <PUBLIC_IP>` so ICE candidates advertise the routable public IP.
3. **Symmetric Mobile NAT & Built-in TURN**:
   - For mobile devices connected over cellular 4G/5G carriers, symmetric NAT frequently blocks direct peer-to-SFU UDP. Enable LiveKit's built-in TURN server by configuring `turn.enabled: true` and mapping UDP port 3478.
4. **Firewall & Cloud Security Groups**:
   - Allow Inbound: TCP 7880, TCP 7881, UDP 7882, UDP 3478.
   - Outbound: Unrestricted (or stateful return traffic).
5. **Local Docker Desktop & WSL2 Caveats**:
   - Docker Desktop on Windows routes through a WSL2 VM. Ensure Windows Defender Firewall allows inbound traffic on UDP port 7882.
   - For local physical phones on LAN, set `LIVEKIT_PUBLIC_URL=ws://<LAN_IP>:7880`. If UDP is blocked by Windows firewall, LiveKit will fall back to ICE TCP port 7881.

---

## Videoconference & Live Sessions Endpoints (Sprint 5, UC3/UC4)

All live session endpoints are mounted under `/api/v1/videoconference`.

| Method | Endpoint | Description | Auth & Role Required |
|---|---|---|---|
| `GET` | `/timetable` | Weekly timetable view scoped to class group | Authenticated |
| `POST` | `/sessions` | Create scheduled or immediate live session | Approved TEACHER or ADMIN |
| `GET` | `/sessions` | List sessions with role filtering (`tab=live\|scheduled\|past`) | Authenticated (class scoped) |
| `GET` | `/sessions/:id` | Get session details (hides `roomName` from non-hosts) | Authenticated (class member) |
| `PATCH` | `/sessions/:id` | Update scheduled session metadata/timing | Host or ADMIN |
| `POST` | `/sessions/:id/cancel` | Cancel scheduled session with reason | Host or ADMIN |
| `POST` | `/sessions/:id/start` | Start live session & provision LiveKit room | Host or ADMIN |
| `POST` | `/sessions/:id/join-token` | Issue signed LiveKit participant JWT token | Authenticated (class member) |
| `POST` | `/sessions/:id/end` | Explicitly complete session & close LiveKit room | Host or ADMIN |
| `POST` | `/sessions/:id/leave` | Record participant departure interval | Authenticated |
| `GET` | `/sessions/:id/participants` | View attendance intervals and active participants | Host or ADMIN |
| `POST` | `/sessions/:id/participants/:userId/mute` | Server-side track muting for a participant | Host or ADMIN |
| `POST` | `/sessions/:id/mute-all` | Mute all participant microphones | Host or ADMIN |
| `POST` | `/sessions/:id/participants/:userId/remove` | Eject participant and ban from rejoining | Host or ADMIN |
| `GET` | `/sessions/:id/messages` | Paginated canonical in-call chat history | Authenticated (session audience) |
| `POST` | `/sessions/:id/messages` | Post persistent in-call chat message | Authenticated (session audience) |
| `PATCH` | `/sessions/:id/chat-settings` | Lock/unlock participant chat messaging | Host or ADMIN |
| `POST` | `/webhooks/livekit` | LiveKit server webhook ingestion (HMAC verified) | LiveKit SFU |
| `GET` | `/me/next-session` | Reactive feed of active or imminent live session | Authenticated |
| `GET` | `/events` | Real-time SSE push stream for session & chat events | Authenticated |

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

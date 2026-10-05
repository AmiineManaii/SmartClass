# PROMPT — Initialize the SmartClass Backend

> Paste everything below the line into Antigravity (Planning mode recommended).
> Open the **monorepo root** as the workspace (the folder containing `front/`, `backend/`, `docs/`), so the agent can see all of them.
> Before pasting: `BACKEND_CONTEXT.md` goes in `backend/`; `SmartClass_Cadrage.html` (and optionally `FRONTEND_CONTEXT.md`) go in `docs/`. The `contracts/` folder is created by the agent.

---

## 1. Role & mission

You are a **senior backend engineer and software architect**. Initialize the backend of **SmartClass**, an AI-assisted learning platform (teachers, students, admins). The **Flutter mobile/web frontend already exists**; the backend does not.

**Your mission now is the INITIALIZATION ONLY**: a backend that is fully scaffolded, **runs in Docker, and reports healthy**, with the folder structure in place, the cross-cutting foundations (security, rate limiting, pagination, error handling, logging, validation) ready, one **reference module (`health`)** that demonstrates the Clean Architecture end to end, and the **`contracts/` folder** where every API is documented as an OpenAPI YAML contract (contract-first).

You are **not** building product features (auth, groups, courses, exams…) in this task. They will come later, one at a time, each in its own request.

## 2. The context file (mandatory habit)

`BACKEND_CONTEXT.md` is the project's technical memory. You must:

1. **Read it entirely before doing anything**, and re-read the relevant sections before every later task.
2. Follow it strictly (architecture, conventions, forbidden practices, error codes, pagination, rate limits, security checklist, package policy).
3. **Update it at the end of this task**: §1.2 (installed packages), §16 (status), §18 (journal and any deviation).

If something in the cadrage (`../docs/SmartClass_Cadrage.html`, relative to `backend/`) or the context is ambiguous or missing, **do not invent it**: list it as an open question in your final report and in §18 of the context file.

## 3. How to work

- **Plan first**: produce an implementation plan (phases, files, risks), then execute phase by phase.
- **Verify after every phase** with real commands. Do not start the next phase until the current one passes.
- **Never rely on memory for versions or setup.** Check the current versions (`npm view <package> version`) and the official docs for Prisma, Express 5, express-rate-limit and Zod. Confirm Docker image tags exist before using them.
- **No placeholders** in implemented parts: no `TODO`, no fake data, no commented-out code, no stub pretending to work. Folders for features that are not implemented yet get only a `.gitkeep`.
- **Host machine is Windows + Docker Desktop (WSL2).** Use cross-platform commands only: no bash-only syntax in `npm` scripts, **no `.sh` files** (CRLF breaks them inside Linux containers). Add `.gitattributes` (`* text=auto eol=lf`) and `.editorconfig`.
- **Do not create any extra "agent/rules" files** (no `AGENTS.md`, `GEMINI.md`, etc.). The only knowledge files are `BACKEND_CONTEXT.md` and the docs given.
- Use small **Conventional Commits** at the end of each phase.
- Ask me only for **blocking** decisions; otherwise decide, and record the decision in `BACKEND_CONTEXT.md` §18.

## 4. Technology decisions (fixed, do not re-debate)

- **Node.js 24 LTS**, **TypeScript strict (ESM)**, **npm**
- **Express 5** (native async error handling; mind the path-to-regexp v8 route syntax)
- **PostgreSQL 17** with pgvector (image `pgvector/pgvector:pg17`)
- **Prisma** (latest stable — follow its *current official setup* for PostgreSQL, including any driver-adapter/config file it requires)
- **Zod** for validation (requests and environment)
- **pino** + **pino-http** for logs
- **helmet** + **cors** for HTTP security
- **express-rate-limit** with the default in-memory store (Redis comes later, when we have several instances)
- **Vitest** + **Supertest** for tests
- **ESLint** + **Prettier**
- **Docker** multi-stage + **docker-compose** (`api` + `db` only)

### Package policy (strict)

Install **only** what this initialization needs:

- Runtime: `express`, `zod`, `@prisma/client` (plus whatever Prisma's current PostgreSQL setup requires, e.g. `pg` / an adapter), `pino`, `pino-http`, `helmet`, `cors`, `express-rate-limit`
- Dev: `typescript`, `tsx`, `prisma`, `@types/node`, `@types/express`, `@types/cors`, `vitest`, `supertest`, `@types/supertest`, `eslint`, `@eslint/js`, `typescript-eslint`, `eslint-config-prettier`, `prettier`, `pino-pretty`
- Environment loading: **no `dotenv`** — Docker injects env vars via `env_file`; locally use Node's `--env-file`.
- OpenAPI contracts are **hand-written YAML files**; no OpenAPI library is installed. For validation use a **one-off `npx` command** that is *not* added to `package.json`.

**Do NOT install** (they will be chosen later, feature by feature, together with me): `jose`, `argon2`, `ioredis` / `rate-limit-redis`, `bullmq`, `socket.io`, `@aws-sdk/*`, `multer`, any OpenAPI/Swagger library, `husky`, ESLint boundary plugins, or anything else not listed above. If you believe another package is truly required, **stop and ask**.

## 5. Architecture (Clean Architecture, modular monolith)

One deployable app, split into **modules** (one per bounded context / frontend feature). Each module has the same 4 layers.

**Request flow**
```
HTTP → Route → [validate / auth / rate-limit] → Controller → UseCase → Repository (port) ⇠ PrismaRepository → PostgreSQL
```

**Module layout**
```
modules/<name>/
├── domain/          # entities, ports (interfaces), domain errors, pure business rules
├── application/     # use-cases (one class = one action), input/output DTOs
├── infrastructure/  # Prisma repositories, external adapters, DB↔domain mappers
├── presentation/    # Express routes, thin controllers, Zod schemas, HTTP mappers
└── index.ts         # public façade (the only entry point other modules may import)
```

**Layer rules**

| Layer | Responsibility | May depend on |
|-------|----------------|---------------|
| Domain | Entities, business rules, ports, domain errors | **Nothing** (pure TS: no Express, Prisma or Zod) |
| Application | Use-cases, orchestration, business authorization | Domain |
| Infrastructure | Implements the domain ports (Prisma, adapters) | Domain |
| Presentation | HTTP concerns only | Application, `shared/http` |

- A controller does exactly: *read the validated request → call ONE use-case → map the result → respond*. **No business logic in controllers, routes or middlewares.**
- Prisma lives **only** in `infrastructure/` (and `shared/infrastructure`).
- A module never imports another module's internals — only its `index.ts`.
- Dependency Inversion: ports are defined in the domain and implemented in infrastructure; wiring is done **manually** in a composition root per module (`<name>.module.ts`) — no decorators, no DI framework.

**Design patterns to apply**: Repository, Use-Case, Dependency Injection (manual), Adapter/Port, Factory (`createApp`, `createRateLimiter`), Mapper/DTO (never expose a raw Prisma entity), Chain of Responsibility (middleware pipeline), Error hierarchy.
**Principles**: SOLID, KISS, DRY (no over-abstraction), YAGNI, 12-Factor (env config, logs to stdout, stateless, graceful shutdown), fail-fast config, least privilege.

**Folder tree to create**
```
backend/
├── BACKEND_CONTEXT.md
├── prisma/            # schema.prisma, migrations/
├── src/
│   ├── main.ts        # bootstrap + graceful shutdown
│   ├── app.ts         # createApp() — no listen(), so tests can use it
│   ├── routes.ts      # mounts /api/v1/<module>
│   ├── config/        # env.ts
│   ├── shared/
│   │   ├── errors/
│   │   ├── http/      # middlewares, validate(), pagination, rate limiters
│   │   └── infrastructure/  # prisma client, logger
│   └── modules/
│       ├── health/    # IMPLEMENTED (reference module, 4 layers)
│       └── auth/ users/ groups/ courses/ exams/ videoconference/ collaboration/ ai-assistant/ notifications/   # empty (.gitkeep)
├── tests/             # unit/ integration/
├── Dockerfile  docker-compose.yml  .env.example  .dockerignore  .gitignore  .gitattributes  .editorconfig
└── package.json  tsconfig.json  eslint.config.mjs  vitest.config.ts
```
**Repository layout (monorepo).** The workspace root contains `front/` (Flutter app, do not touch), `docs/` (cadrage, frontend context), and `backend/`. You work inside **`backend/`**, which holds everything in the tree above, **except** that you also create a new sibling folder at the monorepo root:
```
<monorepo root>/
├── front/        # Flutter app — NOT part of this task
├── docs/         # SmartClass_Cadrage.html, FRONTEND_CONTEXT.md — read-only
├── backend/      # everything described above
└── contracts/    # NEW — OpenAPI contracts (see §6.10)
```
(If the real folder names differ, e.g. `frontend/`, adapt and note it in `BACKEND_CONTEXT.md`.) Note that `docs/` is **not** inside `backend/`.

## 6. Cross-cutting rules to implement

### 6.1 API conventions
- Base path `/api/v1`. Health endpoints live outside versioning: `/health/live`, `/health/ready`.
- JSON in camelCase, dates ISO-8601 UTC, ids UUID, enums SCREAMING_SNAKE_CASE.
- Success: `{ "data": ..., "meta"?: {...} }`.
- **Every error** uses exactly this shape:
```json
{ "error": { "code": "VALIDATION_ERROR", "message": "Invalid request", "details": [], "requestId": "..." } }
```
- Stable error codes (never renamed): `BAD_REQUEST`(400), `AUTH_INVALID_CREDENTIALS` / `AUTH_TOKEN_EXPIRED` / `AUTH_TOKEN_INVALID` / `AUTH_REFRESH_REUSED`(401), `FORBIDDEN` / `ROLE_ALREADY_ASSIGNED`(403), `NOT_FOUND`(404), `EMAIL_ALREADY_USED` / `CONFLICT`(409), `VALIDATION_ERROR`(422, with `details: [{path, message}]`), `RATE_LIMITED`(429, with `Retry-After`), `INTERNAL_ERROR`(500), `SERVICE_UNAVAILABLE`(503). Implement the catalogue now even though auth ones are used later.
- The backend returns a stable `code` + a neutral English `message`; the **Flutter app translates by code** (the frontend forbids hardcoded UI text), so never rely on `message` for display.

### 6.2 Error handling
`AppError` base class + `BadRequestError`, `UnauthorizedError`, `ForbiddenError`, `NotFoundError`, `ConflictError`, `ValidationError`, `TooManyRequestsError`, `ServiceUnavailableError`. One central 4-argument error-handler middleware produces the envelope above. **Never leak stack traces in production.** Unknown errors become `INTERNAL_ERROR` (full detail only in logs).

### 6.3 Middleware order
requestId (accept/emit `X-Request-Id`) → pino-http → helmet → CORS (allowlist from env, never `*` with credentials) → JSON body parser (limit `1mb`) → global rate limit on `/api/v1` → routes → 404 handler (standard envelope) → error handler. Hide `x-powered-by`. Configure `trust proxy` from env.

### 6.4 Validation
A `validate({ body, query, params })` middleware using Zod with **`.strict()`** schemas (unknown fields rejected). Failures → `422 VALIDATION_ERROR` with `details[{path,message}]`. No mass assignment: never pass `req.body` straight to Prisma.

### 6.5 Pagination (mandatory for any list endpoint)
Build **one shared helper** in `shared/http/pagination` (no endpoint uses it yet, it is unit-tested):
- **Offset**: `?page=1&limit=20` (default 20, **max 100**) → `meta: { page, limit, total, totalPages, hasNextPage, hasPreviousPage }`. Helper returns `skip/take` and builds the meta.
- **Cursor (keyset)**: `?cursor=<opaque base64>&limit=20` on `(createdAt, id)` → `meta: { limit, nextCursor, hasMore }`. Helper encodes/decodes the cursor safely (invalid cursor → `400 BAD_REQUEST`).
- Shared Zod schemas for both query shapes; deterministic ordering (`createdAt` + `id`); sorting/filtering through a whitelist; an empty list is `200` with `data: []`.

### 6.6 Rate limiting
`express-rate-limit`, in-memory store, standard `RateLimit-*` headers, `429` with `Retry-After` and body code `RATE_LIMITED`, IPv6-safe key generation (use the library's official helper). Provide a **`createRateLimiter(options)` factory** and apply the **global limiter on `/api/v1`: 100 requests/minute per IP**, configurable through `RATE_LIMIT_WINDOW_MS` and `RATE_LIMIT_MAX`. `/health/*` is **exempt**. (Stricter login/register/refresh limiters will be added with auth later; the factory must make that trivial.)

### 6.7 Security checklist
helmet; CORS allowlist; strict Zod on every input; body-size limit; parameterized queries only (never `$queryRawUnsafe` or concatenated SQL); never return raw entities (DTO mappers); secrets only from env and never logged; **pino redaction** of `authorization`, `cookie`, `password`, `refreshToken`, `token`; no `console.log`; no stack traces in production; non-root Docker user; no secrets in the image; DB port bound to `127.0.0.1`; server timeouts configured; graceful shutdown.

### 6.8 Config
`src/config/env.ts` validates the environment with Zod and **fails fast** with a readable message. It is the **only** place allowed to read `process.env`. Variables: `NODE_ENV`, `PORT`, `LOG_LEVEL`, `DATABASE_URL`, `CORS_ORIGINS` (comma-separated), `TRUST_PROXY`, `RATE_LIMIT_WINDOW_MS`, `RATE_LIMIT_MAX`, plus `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` for compose. `.env.example` is complete with no real secrets; `.env` is git-ignored.

### 6.9 Forbidden
`any` / `@ts-ignore` without a written reason · `process.env` outside `env.ts` · `console.log` · Prisma/Express/Zod inside `domain/` · business logic in controllers · list endpoints without pagination · errors without a stable `code` · secrets in the repo, logs or image · CPU-blocking work in the event loop · installing packages outside §4 · creating or changing an endpoint without updating its OpenAPI contract.

### 6.10 API contracts (`contracts/`, OpenAPI 3.1 YAML, contract-first)

`contracts/` is the **README of the API**: one hand-written OpenAPI file per module so that whoever builds the Flutter app can read exactly what each endpoint requires (e.g. `POST /auth/register` needs `email`, `password`…) and returns, without digging into the backend code.

Layout:
```
contracts/
├── README.md             # how to use + INDEX TABLE (module → file → status)
├── common.yaml           # shared components
├── health.openapi.yaml   # the only contract with real endpoints in this task
└── <module>.openapi.yaml # one per module, created when that module is built (auth.openapi.yaml, users.openapi.yaml, groups.openapi.yaml…)
```

Rules (also written into `contracts/README.md` and `BACKEND_CONTEXT.md` §5.1):
- **One module = one file**, named exactly like the module folder: `<module>.openapi.yaml` (kebab-case).
- **Contract-first**: write or update the contract *before* implementing or changing an endpoint, then code to match it. **Same task = contract + Zod schema + tests + README index.** A contract that diverges from the code is a bug.
- Every operation has: unique camelCase `operationId`, `tags: [<module>]`, `summary`, `description` (cite the business rules RG involved), `security` (`bearerAuth`, or `[]` when public), a `requestBody` with `required` fields, types and constraints (`minLength`, `maxLength`, `format`, `enum`), **`additionalProperties: false`** (mirrors Zod `.strict()`), at least one `example`, and **every possible response**: the success plus each error with its stable `error.code`.
- Shared pieces live only in `common.yaml` and are referenced with `$ref: './common.yaml#/components/...'`; never copied.
- Field names and enum values in the contract are the real JSON ones (camelCase, English enums).
- `servers`: `/api/v1`, except `health.openapi.yaml` which uses `/` (health routes are outside `/api/v1`).
- Each operation carries **`x-status: planned | implemented`**, mirrored in the README index table. `planned` = contract defined, endpoint not coded yet.
- If the frontend developer finds something missing (a field, an error, an endpoint), it is **added to the contract first** (`x-status: planned`), then the backend implements it.

`common.yaml` must be a valid OpenAPI 3.1 document (`openapi`, `info`, `components`) containing:
- `schemas`: `ErrorResponse` (the error envelope of §6.1, with the `code` enum from the stable catalogue), `ErrorDetail` (`path`, `message`), `PaginationOffsetMeta`, `PaginationCursorMeta` (exactly as in §6.5)
- `parameters`: `PageParam`, `LimitParam` (default 20, max 100), `CursorParam`, `SortParam`
- `securitySchemes`: `bearerAuth` (HTTP bearer, JWT)
- `responses`: `BadRequest`, `Unauthorized`, `Forbidden`, `NotFound`, `Conflict`, `ValidationError`, `TooManyRequests` (with the `Retry-After` header), `InternalError`, `ServiceUnavailable`

`contracts/README.md` (English, short) contains: purpose, folder layout, the rules above, the **contract-first workflow** (propose contract → review → implement → mark `implemented`), how the frontend dev requests missing things, the one-off validation command, and the **index table**:

| Module | File | Base path | Status |
|--------|------|-----------|--------|
| health | `health.openapi.yaml` | `/` | implemented |
| auth, users, groups, courses, exams, videoconference, collaboration, ai-assistant, notifications | not created yet | `/api/v1/...` | planned (file created when the module is built) |

## 7. Phases

### Phase 1 — Scaffold & tooling
Create the folder tree, `package.json` (scripts: `dev`, `build`, `start`, `lint`, `typecheck`, `test`, `test:watch`, `db:migrate`, `db:deploy`), strict `tsconfig` (`noUncheckedIndexedAccess`; path alias `@/*`), ESLint flat config + Prettier, Vitest config, `.gitignore`, `.dockerignore`, `.gitattributes`, `.editorconfig`, `.env.example`.
**Verify:** `npm run lint` and `npm run typecheck` pass.

### Phase 2 — Docker
- `Dockerfile` multi-stage `dev → build → production`; Debian-slim Node base; the `production` target runs as the non-root `node` user with `NODE_ENV=production` and prod dependencies only; a Node-based `HEALTHCHECK` (no `curl` dependency).
- `docker-compose.yml` with `api` (target `dev`, bind-mounted source with hot reload via `tsx watch`, anonymous volume for `node_modules`, `env_file`) and `db` (`pgvector/pgvector:pg17`, named volume, `pg_isready` healthcheck, port bound to `127.0.0.1:5432`). `api` uses `depends_on: condition: service_healthy`. The api start command runs `prisma migrate deploy` then the dev server, **inline** (no script file).
**Verify:** `docker compose up -d --build` → `docker compose ps` shows `api` and `db` **healthy**.

### Phase 3 — Shared kernel
Implement §6: `env.ts`, logger, request id, error classes + catalogue + handler, `validate()`, pagination helper, rate-limiter factory + global limiter, `createApp()` / `main.ts` with graceful shutdown (SIGTERM/SIGINT → stop accepting → drain → close Prisma → exit, 10 s timeout).
**Verify:** lint + typecheck + unit tests for the pagination helper, error handler, `validate()` and the env loader.

### Phase 4 — Prisma & database
Conventions: English PascalCase models, `@@map` snake_case plural tables, `@map` snake_case columns, UUID ids, `Timestamptz`, indexes on FKs and queried columns.
- Enums: `Role { TEACHER, STUDENT, ADMIN }`, `UserStatus { ACTIVE, SUSPENDED }`.
- Model `User`: `id`, `email` (unique, stored lowercase), `passwordHash`, `firstName`, `lastName`, `role Role?` (**nullable** until the user picks a role after sign-up), `birthDate DateTime? @db.Date`, `status UserStatus @default(ACTIVE)`, `onboardingCompleted Boolean @default(false)`, `createdAt`, `updatedAt`.
- First migration also runs `CREATE EXTENSION IF NOT EXISTS vector`.
- A Prisma client provider in `shared/infrastructure`.
**Verify:** migrations apply from scratch (`docker compose down -v && docker compose up -d --build`) and are re-runnable.

### Phase 5 — `health` module (reference, all 4 layers)
- Domain: `HealthCheckPort` (e.g. `checkDatabase()`), result types.
- Application: `GetLivenessUseCase`, `GetReadinessUseCase`.
- Infrastructure: `PrismaHealthCheck` implementing the port (`SELECT 1`, short timeout).
- Presentation: routes + controller + mapper; wired in `health.module.ts` and exposed via `index.ts`.
- `GET /health/live` → `200 { status: "ok", uptime }` (no dependency calls). `GET /health/ready` → `200` when the DB is up, otherwise `503` with per-dependency detail (`SERVICE_UNAVAILABLE`).
**Verify:** stopping `db` makes `/health/ready` return `503` while `/health/live` stays `200`; restarting `db` recovers.

### Phase 6 — Contracts
Create `contracts/` at the monorepo root as described in §6.10: `README.md`, `common.yaml`, and `health.openapi.yaml` documenting `GET /health/live` and `GET /health/ready` **exactly as implemented** (flat `{ status, uptime }` for live; for ready the `200` body and the `503` error envelope with per-dependency `details`), both marked `x-status: implemented`.
**Verify:** (1) validate the YAML with a **one-off** command such as `npx --yes @redocly/cli@latest lint contracts/*.yaml` (do **not** add it to `package.json`; if it cannot run, say so and parse the YAML another way, and report it); (2) call the real endpoints and confirm the responses match the documented shapes.

### Phase 7 — Tests & documentation
- Unit tests: pagination helper (offset + cursor), error classes/handler, `validate()`, env loader, health use-cases with an in-memory fake port.
- Integration tests (Supertest on `createApp()`): health endpoints, unknown route → `404` standard envelope, malformed JSON → `400`, rate limit exceeded → `429` with `Retry-After` and `RATE_LIMITED`, error envelope always contains `requestId`.
- Add a short `README.md` (prerequisites, `docker compose up`, env setup, scripts, how to run tests). Do **not** duplicate `BACKEND_CONTEXT.md`.
- Update `BACKEND_CONTEXT.md` (§1.2 installed packages, §16 status, §18 journal/deviations, and the real folder names if they differ).
**Verify:** `docker compose exec api npm run lint && npm run typecheck && npm test` are all green.

## 8. Acceptance criteria (all must be true — show the output of each)

1. `docker compose up -d --build` → `docker compose ps`: `api` and `db` both **healthy**.
2. `GET http://localhost:3000/health/live` → `200`; `GET /health/ready` → `200` with the database `up`.
3. Stopping `db` → `/health/ready` is `503`, `/health/live` still `200`; after restart it recovers.
4. `docker compose exec api npm run lint`, `typecheck`, `test` → all pass.
5. `docker compose down` then `up -d` (data kept) → still healthy; `down -v` then `up` → migrations re-apply cleanly.
6. The folder tree matches §5, including the empty future modules.
7. No secret committed; `.env.example` complete; `.env` ignored; the production image runs as non-root.
8. Only the packages of §4 are installed; none from the "Do NOT install" list.
9. `contracts/` exists at the monorepo root with `README.md`, `common.yaml` and `health.openapi.yaml`; the YAML validates as OpenAPI 3.1 (show the one-off validation output) and matches the real responses.
10. `BACKEND_CONTEXT.md` updated.

## 9. Final report (use this format)

1. **What was delivered**, by phase (short).
2. **Verification evidence**: the commands above and their results.
3. **Decisions & deviations** from this prompt or the context file, with the reason.
4. **Open questions** (anything ambiguous in the cadrage; for example, business rules cited but not worded).
5. **Next step suggestion**: Sprint 1 (auth + users + groups). It starts **contract-first**: we write `auth.openapi.yaml` (e.g. what `POST /auth/register` requires) before any code, and we choose the needed packages together before starting.

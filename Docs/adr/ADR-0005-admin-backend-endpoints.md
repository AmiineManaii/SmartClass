# ADR-0005: Admin Backend Endpoints (users / groups / exams / videoconference)

## Status
Accepted (2026-10-11)

## Context
The Flutter admin module (`lib/features/admin/`, see ADR-0004) shipped
mock-first: 7 screens backed by `MockAdminDataSource` because no backend
module existed beyond `auth` + `health`. The admin UI needs real
persistence for class management, assignments, timetable and fraud
reporting. No new packages are required.

## Decision
- Implement 14 endpoints across 4 new modules, each in strict Clean
  Architecture (domain / application / infrastructure / presentation +
  facade `index.ts`), reusing the auth module's `authenticateMiddleware`
  and `requireRoleMiddleware` (single token-truth source, wired in
  `routes.ts`):
  - `users`: `GET /api/v1/users` (offset paginated directory, role/search
    filters) — ADMIN-only (PII, least privilege).
  - `groups`: `GET /groups` (offset, level/search filters, member &
    teacher counts, referent), `POST /groups` (DRAFT/PUBLISHED),
    `GET /groups/:id`, `POST /groups/:id/members` (atomic, STUDENT-only,
    duplicates → 409 `ROLE_ALREADY_ASSIGNED`), `POST
    /groups/:id/teachers` (upsert by (group, teacher), TEACHER-only).
  - `exams` (integrity slice only): `GET /exams/fraud-reports` (cursor
    keyset per shared convention), `GET /exams/fraud-reports/summary`
    (no integrity rate — no exams denominator exists yet),
    `PATCH /exams/fraud-reports/:id` (CLOSED is terminal → 409).
  - `videoconference` (timetable slice only): `GET
    /videoconference/timetable` (bounded Mon–Sat week, documented
    pagination exception).
- New Prisma models `ClassGroup`, `GroupMember`, `TeacherAssignment`,
  `TimetableSlot`, `FraudReport` (+ enums), migration
  `20261011002231_admin_modules`; glossary names respected
  (`ClassGroup`, `GroupMember`, `FraudEvent`→`FraudReport` per glossary
  `RapportIntegrite`→`IntegrityReport` naming spirit).
- Shared fix (required by the new GET endpoints): `validate()` no longer
  reassigns Express 5 getter-only `req.query`; validated values are read
  via new `validatedQuery()` helper, and sort whitelists are enforced in
  Zod via new `sortQuerySchema()` (→ 422 per contract).
- Demo seed (`prisma/seed.ts`, `db:seed`, idempotent): ADMIN + teachers +
  students + class + week slots + fraud report for manual/E2E testing.

## Alternatives Considered
- **Aggregate `/admin/overview` endpoint** — rejected (YAGNI): the client
  composes stats from list totals + fraud summary; avoids inventing
  aggregation semantics.
- **Integrity percentage computed from reports** — rejected as dishonest:
  no exam-session denominator exists; the rate stays out of the contract
  until the full exams module lands.
- **`TimetableSlot.teacher` embedded name only (no FK)** — rejected:
  FK + `SetNull` preserves referential integrity while surviving teacher
  deletion; the display name is composed server-side.
- **Cursor pagination everywhere** — rejected: the shared convention table
  prescribes offset for groupes/cours/utilisateurs; cursor only where
  prescribed (fraud events).

## Consequences
- Positive: admin UI has a complete real backend to wire against; 91/91
  tests green; contracts + index + journal updated in the same task.
- Negative: `updateRole`-style gaps remain (role changes still have no
  endpoint); TEACHER-scoped reads and archive flow are explicitly planned,
  not built.

## Trade-offs
Admin-only RBAC today (simple, least privilege) over teacher-scoped reads
(more endpoints, more IDOR surface) — widened when the exams/courses
contracts require it. Audit durability (snapshot names on fraud reports,
`SetNull` FKs) over strict normalization.

# ADR-0006: Live Email-Availability Check During Registration

## Status
Accepted (2026-10-11)

## Context
During registration, users only learned that an email was already taken
*after* submitting the form (409 `EMAIL_ALREADY_USED` from
`POST /auth/register`). The requirement: warn immediately while typing
whether the address already belongs to another account.

## Decision
- New endpoint `POST /api/v1/auth/check-email` (`{email}` →
  `{available, email}`), implemented as `CheckEmailUseCase` over the
  existing `findUserByEmail` port method — the duplicate condition mirrors
  register exactly (any existing account counts, case-insensitively per the
  Prisma adapter normalization).
- Same protections as the sibling auth routes: Zod-strict body, shared
  auth rate limiter, neutral English messages, stable codes only.
- Flutter: `checkEmailAvailability` threaded through datasource →
  repository → notifier **without touching global auth state**; the
  register page debounces calls (600 ms), guards stale responses, shows an
  inline spinner + the existing `email_already_exists` message. The submit
  path (409 → resend → verify-email) is unchanged as fallback.

## Alternatives Considered
- **Rely on register 409 only** — rejected: it answers the question one
  round-trip too late, which is exactly the reported UX gap.
- **GET with query param** — rejected: auth module convention is POST +
  JSON body for all email-input operations; keeps email out of logs/URLs.
- **Client-side only check** — impossible: only the server knows.

## Consequences
- Positive: immediate feedback; no new packages; 8 new tests (unit +
  integration); contract-first (`auth.openapi.yaml`).
- Negative: the response is an account-existence oracle by design.

## Trade-offs
Enumeration exposure is accepted and documented (contract + here) because
the register 409 already revealed the same fact — the endpoint only makes
the existing oracle explicit, cheaper, and rate-limited, while revealing
nothing beyond a boolean (no names, roles, or states).

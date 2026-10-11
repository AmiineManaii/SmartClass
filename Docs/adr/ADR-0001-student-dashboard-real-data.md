# ADR-0001: Student Dashboard Shows Real Data Only (No Mocks)

## Status
Accepted (2026-10-10)

## Context
The student dashboard (`StudentDashboardView`) rendered hardcoded mock data:
streak/goal stats, an invented live session, invented courses and homework,
a hardcoded notification badge (`2`), and a mock degree line. The backend
exposes no dashboard endpoints yet (only `auth` + `health` are implemented;
see `contracts/README.md`), and the user explicitly required the dashboard
to display their real information.

## Decision
- Identity comes exclusively from the authenticated session (`AuthState`
  from `GET /api/v1/auth/me`): display name, with email as subtitle.
  Fallbacks (`student_greeting_default`, hidden email line) cover legitimately
  absent values — they never invent data.
- All class-dependent content (live session, courses, homework) is gated
  behind `studentClassMembershipProvider`. Unknown membership (or fetch
  failure) renders `NoClassNotice` ("contact your administration") instead
  of invented content (fail-safe default).
- The notification bell keeps no counter; tap shows the honest empty state
  (`notifications_empty`) until the notifications module lands.

## Alternatives Considered
- **Keep mocks until endpoints land** — rejected: directly contradicts the
  explicit requirement and ships false information (fake grades, fake lives).
- **Hide the whole dashboard when data is missing** — rejected: identity,
  AI Studio entry points and navigation remain useful without a class.

## Consequences
- Positive: zero false information; every future endpoint plugs into a
  documented provider seam without UI rework.
- Negative: first-run dashboard looks sparse (greeting + notice) until the
  groups/courses/exams contracts land.

## Trade-offs
Truthfulness and user trust are prioritised over visual richness.

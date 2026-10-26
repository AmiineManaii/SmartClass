# ADR-0002: Membership Gate with Documented Provider Seams

## Status
Accepted (2026-10-10)

## Context
No backend endpoint exposes class membership, today's sessions, enrolled
courses, or homework yet (groups/courses/exams/videoconference contracts
are 📋 planned). The dashboard still needs a coherent structure ready to
receive real data, without polling and without mocks.

## Decision
- `lib/features/home/application/providers/student_dashboard_provider.dart`
  exposes four seam providers, each with a `TODO(<module>-contract)` comment
  naming the future repository call:
  - `studentClassMembershipProvider: FutureProvider<StudentClassMembership?>`
    → `null` until `GET /api/v1/groups/memberships` lands.
  - `studentTodayLiveProvider: FutureProvider<TodayLiveSession?>` → `null`
    until the today's-course calendar endpoint lands.
  - `studentEnrolledCoursesProvider` / `studentAssignmentsProvider` →
    empty lists until the courses/exams contracts land.
- `FutureProvider` (not plain `Provider`) is used so the seam already has
  the async shape of a future HTTP call, including loading/error states
  handled by the UI (`AsyncValue.when`).
- The mock datasource (`mock_student_dashboard_datasource.dart`) and the
  streak/goal widget were deleted, not deprecated.
- Refresh is user-triggered (`RefreshIndicator` → targeted `ref.invalidate`),
  never periodic.

## Alternatives Considered
- **Plain `Provider` returning null/[]** — rejected: would require reshaping
  providers and UI states when the async endpoints land.
- **Local persistence of a fake membership** — rejected: invents enrollment
  state the backend cannot confirm.

## Consequences
- Positive: wiring a future endpoint = changing one provider body + deleting
  its TODO; UI already handles loading/data/error/empty.
- Negative: four providers resolve to empty today; sections show empty states.

## Trade-offs
A small amount of "empty-state" UI today buys zero-rework integration
tomorrow. Failure mode default (error → notice) avoids ever showing stale
or invented class data.

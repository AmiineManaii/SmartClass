# ADR-0003: Remove Streak/Goal Widgets and Fake Notification Badge

## Status
Accepted (2026-10-10)

## Context
The dashboard showed "SÉRIE ACTIVE / OBJECTIF HEBDO" stat cards and a
notification bell with a hardcoded badge (`2`), all fed by mock values
with no backend counterpart. The user explicitly required their removal.

## Decision
- Delete `StudentMotivationCards` (streak + weekly goal) entirely, including
  the `StudentMotivationStats` model and its provider.
- Remove the hardcoded notification badge; the bell remains as a header
  affordance and reports the honest empty state (`notifications_empty`)
  until the notifications module (planned) provides real data.
- No "equivalent" replacement widgets: engagement metrics will be
  reintroduced only when a backend source of truth exists.

## Alternatives Considered
- **Keep the widgets with zeroed values** ("0 days", "0%") — rejected:
  implies a tracking system that does not exist; misleading.
- **Compute streak/goal locally on-device** — rejected: unverifiable,
  diverges from future server values, adds unplanned scope.

## Consequences
- Positive: no misleading metrics; smaller widget tree.
- Negative: dashboard loses two visual anchors until real metrics land.

## Trade-offs
Correctness over decoration. Re-adding later is cheap (new provider +
new widget, same layout slot).

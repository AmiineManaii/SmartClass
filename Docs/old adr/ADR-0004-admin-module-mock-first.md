# ADR-0004: Admin Module Ships Mock-First, Real Identity Only

## Status
Accepted (2026-10-10)

## Context
Seven admin mockups landed (`tableau de bord`, `gestion des classes`,
`créer classe`, `ajouter étudiants`, `affecter enseignants`, `emplois du
temps`, `rapports de fraude`). Backend analysis shows ONLY `auth` + `health`
endpoints are implemented (`contracts/README.md` ✅); `users`, `groups`,
`courses`, `exams`, `videoconference` modules are empty scaffolds (📋 planned,
0 TS files). The user directive: real data where endpoints are ready, mocks
where they are not.

## Decision
- New `lib/features/admin/` bounded context (dashboard, classes, create,
  students, teachers, planning, frauds) backed 100% by
  `MockAdminDataSource` behind the `AdminRepository` interface — one seam to
  swap per endpoint when contracts land (each repository method carries its
  future endpoint as a TODO comment).
- The ONLY real data on admin screens is the admin identity
  (`AuthState.displayName` from `GET /api/v1/auth/me`); greeting falls back
  to the `Administrateur` role label, never a mock name.
- Role-aware shell: `_BottomNavBar` switches items on `auth.role`
  (Tableau/Classes/Planning/Fraudes/Paramètres for admin); `/admin/*`
  routes are guard-redirected to `/home` for non-admin roles;
  `HomePage` branches to `AdminDashboardView` for `role == 'admin'`.
- Counters/badges are computed from loaded lists (no hardcoded `84`, `26`);
  week dates derive from the real current week (`DateTime.now()` Monday
  anchor); day names via `intl DateFormat` (locale-aware, no hardcoded days).
- Action buttons without a backend (sanction, export, create…) show the
  localized `feature_coming_soon` feedback instead of dead taps or fake
  success states.

## Alternatives Considered
- **Wait for backend modules** — rejected: blocks all admin UI progress;
  mock-first with a clean seam is the established project pattern.
- **Separate admin shell route** — rejected: duplicating `MainScaffold`
  doubles navigation maintenance; role-aware items reuse one shell.
- **Hardcode mockup numbers in UI** — rejected: counts must derive from
  data so the UI stays correct when real lists arrive.

## Consequences
- Positive: 7 complete screens, 0 errors, consistent with teacher/student
  patterns; each future contract maps to exactly one provider/datasource
  change.
- Negative: admin numbers are illustrative until users/groups/exams
  contracts land; write actions are UI-only (snackbar confirmations).

## Trade-offs
Scope fidelity (all 7 mockups, full navigation) is prioritised over live
data that cannot exist yet; honesty is preserved by computing everything
derivable and marking the rest as mock-sourced in code.

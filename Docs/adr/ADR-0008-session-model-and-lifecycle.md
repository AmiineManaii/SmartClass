# ADR-0008: Session Model, Lifecycle, and Room Resource Reconnection

## Status
Accepted (2026-10-25)

## Context
Video sessions in SmartClass represent structured educational meetings between a teacher and their enrolled students (`ClassGroup`). Teachers need to either start an impromptu live class ("Start now") or schedule a future session ("Schedule"). During a live session, network hiccups, browser refreshes, or device battery events may cause the teacher (host) or students to disconnect temporarily. If an empty room resource automatically terminated the entire business session, accidental drops would catastrophically end active classes.

## Decision
1. **Class-Attached Model**: Every `VideoSession` is strictly attached to an existing `ClassGroup` (`groupId`). Standalone or unattached rooms are prohibited. Class membership gates visibility, join authorization, and attendance recording.
2. **Lifecycle State Machine**:
   - `SCHEDULED -> IN_PROGRESS -> COMPLETED`
   - `SCHEDULED -> CANCELED`
   - Terminal states are strictly `COMPLETED` and `CANCELED`. A completed or canceled session cannot transition back to another state.
3. **"Start Now" vs "Schedule"**:
   - "Start now" creates a session with `startsAt = now()`, immediately transitioning to `IN_PROGRESS`.
   - "Schedule" sets a future `startsAt`.
4. **Decoupling Business Session from Media Room Lifecycle**:
   - The logical session remains `IN_PROGRESS` until the host or administrator explicitly executes "End for everyone" (`POST /videoconference/sessions/:id/end`).
   - If all participants leave or disconnect, the underlying LiveKit media room resource may time out and be garbage-collected by the LiveKit server after `SESSION_EMPTY_ROOM_TIMEOUT_MINUTES`.
   - When the teacher or an authorized participant rejoins, the SmartClass API checks that the business session is still `IN_PROGRESS` and idempotently ensures/recreates the LiveKit room with the exact same room identifier before issuing a join token.
5. **Join Window & Lobby**:
   - Students can open the in-app pre-join lobby up to `SESSION_JOIN_OPENS_MINUTES` (default: 5 minutes) before `startsAt`.
   - Media connection to LiveKit is denied to students until the session transitions to `IN_PROGRESS` (i.e. once the host starts the session).
6. **Attendance Tracking**:
   - Participant attendance is tracked as discrete time intervals `[joinedAt, leftAt]`, aggregated when the session completes.

## Alternatives Considered
- **Auto-completing session when room is empty** — Rejected: A teacher losing Wi-Fi for 45 seconds would cause the session to permanently close, kicking all students out and preventing re-entry.
- **Unattached / Ad-hoc rooms** — Rejected: Leaves orphan rooms, bypasses class membership security, and prevents automated student attendance auditing.

## Consequences
- **Positive**: Resilient against network drops; clean authorization; teachers can safely reload or switch devices; clear, predictable state machine for UI countdowns and badges.
- **Negative**: The backend must track logical status in Postgres independently of LiveKit server state and implement idempotent room recreation upon rejoin.

## Trade-offs
Separating logical session state from physical SFU room state requires slightly more backend logic but is essential for real-world network resilience in schools.

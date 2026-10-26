# ADR-0009: Realtime Architecture: REST + SSE Push + LiveKit Media (No Polling, No Socket.IO)

## Status
Accepted (2026-10-25)

## Context
SmartClass applications (Flutter on Web, Android, iOS, Desktop) require immediate notifications when:
- A session status changes (e.g. teacher starts live, ends live, cancels session).
- A chat message is sent in a live session.
- A student is muted or removed by the host.
- A student dashboard updates countdowns for an imminent session.

Project rules strictly prohibit:
1. Client polling (`Timer.periodic` making periodic HTTP requests).
2. Unnecessary complex real-time connection layers (e.g. Socket.IO) when simpler, robust primitives exist.

## Decision
Adopt a three-tier separation of concerns:
1. **LiveKit WebRTC Channel**:
   - Transmits audio, video, and screen-share tracks.
   - Handles ephemeral in-room signaling and transient data packets (such as hand-raising notifications).
2. **Authenticated REST Endpoints**:
   - Handles all client commands and state mutations (`POST /videoconference/sessions/:id/start`, `POST /videoconference/sessions/:id/messages`, etc.).
   - Persists all domain data canonically in PostgreSQL (sessions, attendance, chat messages with idempotency keys `clientMessageId`).
   - Serves paginated history queries.
3. **Authenticated Server-Sent Events (SSE)**:
   - Endpoint: `GET /api/v1/videoconference/events`.
   - Single long-lived HTTP SSE connection per authenticated user.
   - Pushes unidirectional `session.*` events (e.g., `session.status-changed`, `session.chat-message-created`, `session.participant-joined`, `session.participant-removed`).
   - The backend persists domain entities (e.g., a chat message) in PostgreSQL first, then broadcasts to the authorized session audience via an in-memory event hub (scale-out via Redis pub/sub).
4. **Client-Side Clock Offset & Countdowns**:
   - The server includes its canonical UTC timestamp in session payloads (`startsAt`, `serverTime`).
   - The client calculates the clock skew offset: `offset = serverTime - localTime`.
   - Countdown widgets tick locally using an in-memory `Ticker` or `Stream.periodic` without any HTTP I/O.

## Alternatives Considered
- **Socket.IO / Bidirectional WebSockets for application data** — Rejected: Requires maintaining a secondary bidirectional WebSocket stack, heartbeat logic, reconnection ping-pong, and custom authentication adapters alongside LiveKit and REST.
- **Client Polling (`Timer.periodic` fetching data)** — Rejected: Wastes server CPU, cellular bandwidth, and battery life, and violates project engineering rules.
- **Relying solely on LiveKit Data Messages for chat** — Rejected: LiveKit data packets are ephemeral and not persisted in PostgreSQL. A student reconnecting or joining late would miss all previous messages. Canonical chat must be backed by PostgreSQL.

## Consequences
- **Positive**: Clean adherence to Clean Architecture; standard HTTP auth headers and proxies work out-of-the-box; zero polling; chat messages are reliably persisted, deduplicated, and retrievable upon reconnect; countdowns operate smoothly without network traffic.
- **Negative**: SSE is strictly unidirectional; client actions must continue to be sent via REST API calls. Single-process in-memory hub requires Redis pub/sub if horizontal scaling is deployed later.

## Trade-offs
Separating real-time media (LiveKit) from real-time events (SSE) and persistent storage (REST + PostgreSQL) delivers optimal reliability, persistence, and architectural simplicity.

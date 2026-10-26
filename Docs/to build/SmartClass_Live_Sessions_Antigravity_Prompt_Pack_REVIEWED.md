# SmartClass Live Sessions (WebRTC) – Antigravity Prompt Pack

*Reviewed against the supplied SmartClass-main ZIP and official LiveKit docs · updated 25 Oct 2026 (persistent in-call chat + screen sharing)*

## 0. Independent repo review — read before running any phase

I checked the supplied `SmartClass-main(1).zip` against the prompt pack. The following are source-grounded findings, not assumptions:

- Backend: Express 5, strict TypeScript, Prisma 7, PostgreSQL 17, Zod, Vitest/Supertest, Clean Architecture modules, and contract-first OpenAPI files under `contracts/`.
- The current videoconference module implements `GET /videoconference/timetable`; it does not yet implement live rooms.
- `Frontend/lib/features/videoconference/presentation/pages/videoconference_page.dart` contains hardcoded sessions, while the dashboard already has `studentTodayLiveProvider`, `TodayLiveSession` and `StudentImminentLiveCard` seams.
- The existing app already uses SSE for AI generation. Keep the real-time channel simple and reuse the existing shared networking patterns where appropriate.
- The uploaded ZIP has no `.git` directory, so an agent cannot prove whether a credential was ever committed to history from this ZIP alone.
- `Backend/.env.example` contains non-placeholder-looking SMTP credential material. Before doing feature work, determine whether it is real. If real, rotate it immediately and replace example values with safe placeholders. Never print credential values in reports or prompts.
- `Frontend/.env` is declared as a Flutter asset. It appears to hold an API base URL in this ZIP, but any value bundled into Flutter must be considered public; no server-side API key or secret may be included there.
- The requested `live_room_web/` and `live_room_mobile/` design folders are not present in the supplied ZIP. Use the existing `Frontend/DESIGN.md` and design assets as the baseline unless new designs are added first.

### Mandatory corrections to the plan

These corrections override any conflicting older wording below:

1. **No Socket.IO is required for the MVP.** Use REST for commands and persisted in-call chat, authenticated SSE for application/session events and live chat delivery, and LiveKit data messages for transient features such as hand-raising. Load chat history from the backend; do not treat client-originated LiveKit data packets as authoritative chat messages. SSE is one-way; do not use it for client-to-server commands.
2. **Do not grant `roomAdmin` to the teacher's LiveKit participant token by default.** The proposed moderation controls go through authenticated backend endpoints using the server-side LiveKit SDK. Give the client only room-join, publish/subscribe and data-publish grants it needs. Grant extra privileges only if a documented SDK operation demonstrably requires them.
3. **Make room creation and session-state transitions failure-safe.** Do not commit `IN_PROGRESS` if LiveKit room provisioning failed. Provision idempotently, perform a guarded transition, and clean up or reconcile the room if a concurrent start loses the race.
4. **Deduplicate LiveKit webhooks by the provider's event ID.** LiveKit retries webhooks and delivery is not guaranteed indefinitely. Verify the current official webhook receiver API, preserve the body as required for signature verification, and persist event receipts so duplicate deliveries cannot create duplicate attendance intervals.
5. **Treat removal/rejoin semantics carefully on self-hosted LiveKit.** Verify current token revocation behavior. Deny future join-token requests after removal, use a short token TTL, and test/document the residual ability of an already-issued token to reconnect if the self-hosted server does not revoke it immediately. Do not promise stronger revocation than the server guarantees.
6. **Do not pretend SSE is a push-notification system.** A disconnected or closed mobile app will not receive SSE events. This MVP's widget updates in-app; email or mobile push reminders are a separate follow-up feature.
7. **Do not blindly choose a tiny UDP port range.** Select either a documented ICE UDP range or the documented UDP-mux setup, then test Chrome and an Android device/emulator through the actual Docker Desktop/WSL2 network path. Write down limitations; local success does not prove production NAT/firewall connectivity.
8. **Separate the LiveKit room resource lifecycle from the business session lifecycle.** The logical SmartClass session should stay `IN_PROGRESS` when the empty LiveKit room times out; it must be recreatable when the host rejoins. A `room_finished` webhook caused by an empty-room timeout is not equivalent to the teacher pressing “End for everyone”. Only an explicit host/admin end (or a separately approved idle-end policy) completes the session.
9. **Make webhook/room lifecycle work idempotent and observable.** Do not let a transient LiveKit failure mark a session live or permanently strand a room. Define compensating cleanup/reconciliation and test both database and LiveKit failure cases.
10. **Preserve existing project architecture.** Before every phase, inspect the latest code and contracts and adapt names to the actual repository. The ZIP, not this prompt pack, is the source of truth.

## 0.1 Selected feature scope — persistent in-call chat + screen sharing (overrides older conflicting wording below)

These are approved requirements for the MVP. Read this section in every phase. Where an older phase below says chat is ephemeral/not stored, this section takes precedence.

### In-call group chat — included in the MVP

- Chat belongs to the logical SmartClass session and is available to authorized participants while the session is live. Persist canonical messages in PostgreSQL so late joiners and reconnecting participants can load history.
- Contract-first API in `contracts/videoconference.openapi.yaml`:
  - `GET /videoconference/sessions/{id}/messages`: authorized session audience only; offset pagination, newest-first (`createdAt DESC`) so the first page contains the latest messages; render each page oldest-first in the UI and load older messages through subsequent offsets.
  - `POST /videoconference/sessions/{id}/messages`: authenticated participant of that live session; accepts only `content` and an idempotency key `clientMessageId`; sender ID, display name and role are derived on the server.
  - `PATCH /videoconference/sessions/{id}/chat-settings`: host/ADMIN can enable or disable new messages during a session. When disabled, existing history remains readable to authorized participants.
- Add `SessionChatMessage` with `id`, `sessionId`, `senderId`, `clientMessageId`, `content`, `createdAt`, suitable FKs/indexes, and a unique constraint for `(sessionId, senderId, clientMessageId)`. Add `chatEnabled` (default true) to the session or an equivalent explicit session setting. Use migrations; never edit an applied migration.
- Validate trimmed plain text (1–2000 characters), authorize every read/write, rate-limit writes, make retry behavior idempotent, and audit host chat-setting changes. Do not accept client-supplied sender identity or role.
- On send: validate + persist first, return the canonical saved message, then emit `session.chat-message-created` through the existing authenticated SSE fan-out to authorized session/class audience members after commit. The SSE payload contains only the saved message fields required to render it. On SSE reconnect/resync, refetch recent messages/history from REST. If event delivery fails, saved history remains the source of truth.
- Use LiveKit data messages for transient hand-raising or similar ephemeral signals, not as the authoritative source for chat content. Never render arbitrary participant-originated data packets as canonical chat messages. No Socket.IO is needed.
- Define chat retention, account-deletion/anonymization, and user-export behavior in Phase 0A / the project context. Chat is not automatically attached to a recording or replay; that requires a separate explicit decision.

### Screen sharing — host-only in the MVP

- Add a screen-share action for the teacher/host only. Students cannot publish a screen-share track in the MVP. This must be enforced by the strongest permission mechanism supported by the actual installed LiveKit SDK and server configuration; hiding the student button is not sufficient.
- Before implementation, verify current official LiveKit server and Flutter SDK documentation for source-level publish permissions, screen-share APIs, and every target platform. If token source grants are unavailable or insufficient, document and implement the strongest supported server/room-side policy. Do not grant `roomAdmin` to ordinary participant tokens just to enable this feature.
- Support and test Web, Android and iOS only to the extent the installed SDK genuinely supports each platform. Add required platform configuration and permission UX. In particular, verify Android MediaProjection/foreground-service behavior and whether iOS requires a Broadcast Extension for the intended capture flow; do not promise feature parity without testing it.
- While sharing, show a clear sharing indicator, make shared content the primary stage, keep participant tiles and call controls accessible, and provide a clear Stop sharing action to the host. Handle user cancellation, permission denial, app/window switching, disconnects, and unsupported platforms gracefully.

### Required integration points by phase

- **Phase 1:** add the chat routes/schemas, `chatEnabled`, `SessionChatMessage` model/migration, validation rules, and error contracts.
- **Phase 3:** implement the authorized chat use cases/endpoints, persistence/idempotency/rate limits/audit, SSE publisher call after commit, privacy/export handling, and verify/enforce host-only screen-share publish permissions.
- **Phase 4:** add `session.chat-message-created` to SSE event contracts and the authorized fan-out/reconnect recovery tests.
- **Phase 5A:** design both desktop and mobile chat history/composer/loading/empty/error/disabled states, plus active sharing and sharing-permission/error states.
- **Phase 6:** implement persistent REST + SSE chat, host-only screen sharing, responsive layouts, platform setup, and end-to-end tests. Remove any UI copy that says chat is ephemeral or not stored.
- **Phase 8:** test message authorization, idempotency, retention/export/deletion policy, SSE fan-out and resync, chat disabling, and screen-share permission bypass attempts on every platform claimed as supported.

### End-to-end acceptance for these additions

1. A teacher and student join the same live session. A chat message appears without refresh, is saved, and remains available after reconnect or for a late joiner. Repeated submission with the same `clientMessageId` does not create a duplicate.
2. A host disables chat: participants cannot send new messages, but authorized participants can still read the history. Outsiders cannot read messages or receive chat SSE events.
3. The teacher can start and stop sharing on each platform declared supported. Shared content is visually prominent. A student cannot publish a screen-share track, including through a path that bypasses the UI where the platform makes that test possible.

### Phase 0A — Preflight and secrets hygiene (run this first)

```text
PHASE 0A — PREFLIGHT, BASELINE, AND SECRETS HYGIENE

Work in Planning mode first. Inspect the actual repository before editing anything.

1. Read Backend/BACKEND_CONTEXT.md, Frontend/PROJECT_CONTEXT.md, contracts/README.md,
   the relevant OpenAPI contracts, root README, and the existing videoconference/module code.
2. Run `git status` and inspect `git log` only if `.git` is actually present. Do not claim history was checked when it is absent.
3. Inspect `Backend/.env.example`, `Backend/src/config/env.ts`, the real local `.env` files if present,
   and all Flutter asset declarations. Never print values of secrets or credential-like fields.
   Report only variable names and whether values look like placeholders.
4. If any SMTP credential or other secret in an example file is real, STOP feature changes until I rotate it.
   Replace example values with safe placeholders. Never rewrite git history automatically; report the exact
   recommended history-remediation steps if a secret was committed.
5. Check whether the Flutter-bundled `.env` contains only public configuration such as the API base URL.
   Do not move server-only secrets into Flutter.
6. Capture the baseline commands and results (backend lint/typecheck/tests, contract lint if installed,
   Flutter analyze/tests). If a baseline already fails, record it before making feature changes.
7. Inspect existing auth, role, class-membership, teacher-assignment and SSE patterns. Do not invent new
   business rules where the cadrage or current contracts are silent; record questions in BACKEND_CONTEXT.md §18.
8. Record blocking product-policy questions in Backend/BACKEND_CONTEXT.md §18. In particular, confirm whether
   “Remove participant” also blocks rejoining this session; the safer proposed default is to block rejoin,
   but do not silently impose it. Also confirm whether a live session should auto-end after a long idle period;
   this plan defaults to keeping the logical session IN_PROGRESS until host/admin ends it, even if the empty
   LiveKit room resource expires.
9. Produce a short report: repository facts, any security blockers, baseline failures, decisions needed,
   and a proposed commit. Do not start Phase 0 until the security blocker is resolved.
```

## 1. What your repo already tells us

- **Stack:** Express 5 + TypeScript (strict) + Prisma 7 / PostgreSQL 17, modular Clean Architecture, contract-first OpenAPI in `contracts/`. Flutter client with Riverpod, GoRouter and Dio, fr/en localization.
- **Backend today:** the `videoconference` module only serves the weekly timetable (`GET /videoconference/timetable`). Its contract says live rooms are for “Sprint 3”.
- **The cadrage already defines the target:** UC3 (teacher plans or starts a live, students join, recording, AI summary), UC4 (replay + summary), RG8 (only the host controls recording), RG11 (summary validated by the teacher), RG14 (recordings encrypted, with retention). The entities `SessionVisio / ParticipantSession / Enregistrement / CompteRendu` map to `VideoSession / SessionParticipant / Recording / SessionSummary` in your glossary.
- **Frontend today:** `videoconference_page.dart` is fully mocked (hardcoded sessions and French strings). That breaks your own “no mock in presentation” rule, so phase 5 replaces it.
- **A seam already waits for this feature:** `studentTodayLiveProvider` returns `null` (`TODO(videoconference-contract)`), and `TodayLiveSession` + `StudentImminentLiveCard` (“LIVE IMMINENT”, “in X min”, Join) exist but receive no data. The teacher dashboard already has a next-slot pill and a button to `/videoconference`.
- **Rules the agent must respect:** no polling (no `Timer.periodic` fetching), no mocks, contract-first, strict Zod + stable error codes, pagination on lists, fr/en through `context.tr`, widgets under 200 lines, new packages only with approval.
- **Gaps to fill:** no camera/microphone permissions in the Android manifest, no `socket.io`, and `docker-compose.yml` currently has `db`, `searxng` and `api` only.
- **Security blocker:** credential-like SMTP values and email addresses are present in the uploaded `Backend/.env.example`; `env.ts` also has non-empty defaults for some sensitive settings. Verify privately whether they are real, rotate any real credentials, replace examples with placeholders, and check repository history if `.git` is available. Never echo the values into an Antigravity prompt or report.

## 2. Decisions (my answers to your questions)

### D1 – Create flow: class first, in one form

Your three ideas (create the room then choose the class, enter the class details first, or schedule for a date) collapse into one flow, because every session belongs to a class:

> Teacher → **New session** → pick class (+ subject) → title → **Start now** or **Schedule** (date, time, duration) → Create

Why class first: the class decides who may join (membership check), which enrolled users receive in-app session events, who sees the dashboard widget, and who appears in attendance. SSE is not push delivery to a closed app; push/email reminders are a separate later feature. It also matches the cadrage (`SessionVisio.id_groupe`). A room created first and attached later leaves orphan rooms and weak access control. **Start now** is just a session with `startsAt = now`; **Schedule** is a future `startsAt`. The teacher can leave and rejoin the same logical session; the underlying LiveKit room is recreated if it expired while empty, and the session remains live until **End for everyone**.

### D2 – Student widget (your spec)

| Phase | When | Widget shows | Button |
| --- | --- | --- | --- |
| UPCOMING | before the join window | title, teacher, class, start time, coarse “in 5 h” | none |
| JOIN\_OPEN | last 5 min before start (per session: 5, 10 or 15) | live mm:ss countdown | Enter the in-app lobby; connect to LiveKit only after the session becomes IN_PROGRESS |
| LIVE | teacher started | pulsing LIVE badge, participant count | Join now |
| hidden | nothing in the next 24 h, canceled, or ended | – | – |

### D3 – Media: LiveKit (self-hosted WebRTC SFU), not raw peer-to-peer

Raw WebRTC peer-to-peer makes every browser upload its video to every other one, which collapses around 4–6 people. A class has 20–40. LiveKit is still WebRTC, but through a media server (SFU). It is open source and self-hostable (fits your privacy rule RG27), has an official Flutter SDK for web, Android, iOS and desktop, uses token auth that maps onto your JWT/RBAC, and supports recording later. Your cadrage already lists it.

### D4 – Realtime: LiveKit media, REST + SSE for persisted chat and app events

No `socket.io` is needed for the MVP. LiveKit handles in-room media, signaling, participant events and transient data messages such as hand-raising. REST handles user commands and canonical chat writes/history. One authenticated SSE stream per logged-in user pushes `session.*` application events, including new chat messages for authorized class/session audiences. Persist a chat message first, then publish its canonical representation via SSE after commit. SSE is server-to-client only; client actions still use REST. Reuse the existing AI SSE networking/parser patterns where appropriate, but do not reuse its one-shot generation-stream lifecycle as if it were a permanent event hub. The in-memory event hub only supports one API instance; Redis pub/sub is the scale-out path.

### D5 – Who can do what

| Action | Assigned teacher / referent | Admin | Student of the class | Outsider |
| --- | --- | --- | --- | --- |
| Create, edit, cancel | yes | yes | no | no |
| Start, end, moderate | yes | yes | no | no |
| Join | yes (host) | yes | only while live | no |
| See sessions | own classes | all | own classes | no |

## 3. Architecture at a glance

```text
Flutter app (web / Android / iOS) --REST + SSE--> Express API --token, least-privilege room token--> LiveKit SFU
        |                                            ^                                  |
        +---------- WebRTC media (wss / udp) --------+----------------------------------+
                                                     +------- webhooks (joined, left, finished)
```

## 4. How to use this pack

1. Open the monorepo root (the folder containing `Backend`, `Frontend`, `contracts`, `Docs`) in Antigravity, in **Planning mode**.
2. One conversation per phase: paste the **Master preamble** (section 5), then the phase prompt.
3. Review the plan before approving. Do not start the next phase until the acceptance criteria pass, and commit per phase.
4. Run Phase 5A before phase 6 to `Frontend/assets/design/live_room_web/` and `live_room_mobile/` (`screen.png`, `code.html`, `DESIGN.md`, like your other design folders). These folders are absent in the supplied ZIP. If Antigravity creates them, review that as a separate design task; otherwise, follow the existing `Frontend/DESIGN.md`.

Order: Phase 0A preflight first; then backend phases 0–4, Flutter phase 5, design phase 5A, Flutter phases 6–7, hardening 8, optional recording and summary 9. Do not proceed past 0A with live credentials in example files.

## 5. Master preamble (paste at the start of every phase)

```text
ROLE
You are a senior full-stack engineer (Node.js/TypeScript backend + Flutter client). You are adding
LIVE VIDEO SESSIONS (WebRTC classes) to SmartClass, inside the existing monorepo:
Backend/  Frontend/  contracts/  Docs/   (real folder names; the context files say backend/ front/).

READ FIRST - every phase, before planning
1. Backend/BACKEND_CONTEXT.md and Frontend/PROJECT_CONTEXT.md. Follow them strictly.
2. contracts/README.md, contracts/common.yaml, contracts/videoconference.openapi.yaml.
3. Docs/adr/ADR-0001..0006 and the videoconference parts of Docs/SmartClass_Cadrage.html
   (UC3, UC4, RG8, RG11, RG14; entities SessionVisio, ParticipantSession, Enregistrement, CompteRendu).
4. `git log` of this repo, if `.git` is present, to see what previous phases delivered. If not, report that limitation and inspect the actual files without failing.
If the cadrage is silent or ambiguous, do NOT invent a business rule: record it as an open question
in Backend/BACKEND_CONTEXT.md section 18 and in your final report. Read section 0.1 of this pack in every phase;
its persistent-chat and host-only-screen-sharing requirements override older conflicting statements below.
- Never print, copy into generated documentation, or commit secret values. Do not give a client LiveKit API secret.
- Commands and canonical chat writes/history go through authenticated REST endpoints; application updates and live chat delivery use authenticated SSE; room media and transient room data (for example, hand-raising) use LiveKit.
- Do not grant LiveKit `roomAdmin` to participant tokens while moderation is performed server-side unless official SDK documentation proves it is necessary.
- Every external webhook must be signature-verified and idempotent. Persist provider event IDs where the provider documents them.
- Preserve existing routes and behavior. Inspect the current working tree and use actual names found in code rather than assuming this prompt is perfectly current.

HOW TO WORK
- Plan first (phases, files, risks), then execute step by step. Verify each step with real commands.
- Never rely on memory for versions or APIs: use npm view, flutter pub and the official docs
  (LiveKit docs for server config, token grants, webhooks and the Flutter SDK).
- No TODO, no fake data, no commented-out code, no stub that pretends to work.
- Host machine is Windows + Docker Desktop (WSL2): cross-platform commands only, no .sh files.
- Do NOT create agent/rules files (AGENTS.md, GEMINI.md...). Knowledge lives in the context files.
- Small Conventional Commits at the end of each step. Ask me only for blocking decisions.

PROJECT RULES (recap - the context files win on any conflict)
- Backend: Clean Architecture per module (domain / application / infrastructure / presentation,
  public facade index.ts, manual DI in <name>.module.ts), Prisma only in infrastructure, strict Zod,
  stable error codes + standard error envelope, pagination on every list, process.env only in
  config/env.ts, no console.log, audit through shared/audit.
- Contract-first: update contracts/*.yaml (x-status planned -> implemented) in the same task as the
  code, the Zod schemas and the tests. Validate with: npx --yes @redocly/cli@latest lint contracts/*.yaml
- Flutter: Clean Architecture per feature, Riverpod, GoRouter, Dio through ApiClient, all UI text through
  context.tr() with keys in BOTH app_fr.arb and app_en.arb, no hardcoded fontSize, files < 200 lines,
  NO mock data in presentation, NO polling (no Timer.periodic that fetches data).
- Never commit real secrets. Only placeholders in .env.example; no real-looking defaults in env.ts.

PACKAGES PRE-APPROVED FOR THIS FEATURE (anything else: stop and ask)
- Backend: livekit-server-sdk
- Flutter: livekit_client, wakelock_plus, permission_handler (only if the livekit/webrtc plugins do
  not already handle runtime permission prompts - justify it in one line)
- Docker image: the official LiveKit server image (verify the tag exists before using it)
Record every added package in BACKEND_CONTEXT.md section 1.2 / PROJECT_CONTEXT.md.

FINAL REPORT (every phase)
1. Delivered (short). 2. Verification evidence: commands + output. 3. Decisions and deviations.
4. Open questions. 5. Suggested next step.
```

## Phase 0 – Foundations (decisions, LiveKit in Docker, configuration)

```text
PHASE 0 - FOUNDATIONS

GOAL
A self-hosted LiveKit server runs next to api/db, its configuration is validated in env.ts, health
shows it as an optional dependency, and the architecture decisions are recorded. No product
endpoints yet.

TASKS
1. Write three ADRs in Docs/adr/ using the existing format (Status, Context, Decision, Alternatives,
   Consequences, Trade-offs):
   - ADR-0007 Media architecture: self-hosted LiveKit SFU (RG27) vs mesh P2P vs Jitsi/Agora.
     Reasons: classes of 20-40 students, simulcast, Flutter SDK on web/Android/iOS, token auth,
     egress for recording later.
   - ADR-0008 Session model: always attached to a class; 'start now' = startsAt now; status machine
     SCHEDULED -> IN_PROGRESS -> COMPLETED and SCHEDULED -> CANCELED; the host may leave and rejoin;
     the logical session remains live until the host/admin ends it; the underlying LiveKit room resource may expire when empty and must be safely recreated if a participant rejoins.
   - ADR-0009 Realtime: one authenticated SSE stream per user for session events; no polling; no
     socket.io; a display-only countdown tick is allowed (no I/O); server clock offset for countdowns.
2. docker-compose.yml: add a livekit service (pinned tag, config in Backend/livekit/livekit.yaml).
   - Map the signaling port, TCP fallback and either a documented ICE UDP media range or the documented UDP-mux port.
   - Read current LiveKit self-hosting docs for Docker Desktop/WSL2 networking (node IP / external IP /
     port mapping / ICE candidates / TCP fallback). Document the selected setup and limitations in Backend/README.md;
     test it from Chrome and an Android device/emulator, not only inside the Docker network.
   - Webhook target: the api service (the route is created in phase 3).
   - api must NOT depend on livekit being healthy: the API must boot and serve everything else
     when LiveKit is down.
3. env.ts + .env.example: LIVEKIT_URL (api to livekit, e.g. http://livekit:7880), LIVEKIT_PUBLIC_URL
   (what the app connects to, e.g. ws://<LAN-IP>:7880 - same idea as COMFYUI_PUBLIC_URL),
   LIVEKIT_API_KEY, LIVEKIT_API_SECRET (min 32 chars), LIVEKIT_TOKEN_TTL_SECONDS (short TTL; default 600 only after verifying
   current self-hosted token behavior and the reconnect UX),
   SESSION_JOIN_OPENS_MINUTES (default 5), SESSION_EMPTY_ROOM_TIMEOUT_MINUTES (default 10).
   When the LIVEKIT_* values are absent, live features answer SERVICE_UNAVAILABLE while the rest of
   the API keeps working (same pattern as the ComfyUI adapter). Placeholders only in .env.example.
4. Health: add livekit as a NON-critical dependency in the readiness detail (the API stays ready when
   LiveKit is down). Change the readiness shape additively; update contracts/health.openapi.yaml
   and the tests.
5. Install livekit-server-sdk (no code uses it yet) and record it in BACKEND_CONTEXT.md.

ACCEPTANCE
- docker compose up -d --build: api, db and livekit are up; livekit answers on its HTTP port.
- Stop livekit: /health/live is 200 and /health/ready is still 200 with livekit reported as down.
- npm run lint, typecheck and test pass; the health contract validates with redocly.
- No secret committed; env.ts has no real-looking default for LIVEKIT_*.

OUT OF SCOPE: endpoints, Prisma changes, Flutter.
```

## Phase 1 – Contract, data model and pure domain

```text
PHASE 1 - CONTRACT + DATA MODEL + PURE DOMAIN

GOAL
The whole session API is specified contract-first (x-status: planned), the database tables exist,
and the business rules live in pure, unit-tested domain code. No HTTP endpoints yet.

TASKS
1. Extend contracts/videoconference.openapi.yaml (keep the timetable operation untouched). Add:
   POST /videoconference/sessions                       createVideoSession
   GET  /videoconference/sessions                       listVideoSessions (offset pagination)
   GET  /videoconference/sessions/{id}                  getVideoSession
   PATCH /videoconference/sessions/{id}                 updateVideoSession (SCHEDULED only)
   POST /videoconference/sessions/{id}/cancel           cancelVideoSession
   POST /videoconference/sessions/{id}/start            startVideoSession (host)
   POST /videoconference/sessions/{id}/join-token       issueJoinToken
   POST /videoconference/sessions/{id}/end              endVideoSession (host)
   GET  /videoconference/sessions/{id}/participants     listSessionParticipants (host)
   POST /videoconference/sessions/{id}/participants/{userId}/mute     muteParticipant
   POST /videoconference/sessions/{id}/participants/{userId}/remove   removeParticipant
   POST /videoconference/sessions/{id}/mute-all         muteAll
   GET  /videoconference/sessions/{id}/messages           listSessionChatMessages (offset pagination; authorized audience only)
   POST /videoconference/sessions/{id}/messages           createSessionChatMessage (persisted; authenticated participant)
   PATCH /videoconference/sessions/{id}/chat-settings     setSessionChatEnabled (host/ADMIN)
   GET  /videoconference/me/next-session                getMyNextSession (dashboard widget)
   GET  /videoconference/events                         streamSessionEvents (text/event-stream)
   POST /videoconference/webhooks/livekit               receiveLiveKitWebhook (signature-verified)
   Schemas: VideoSession (never exposes roomName to students; includes chatEnabled), CreateVideoSessionRequest
   (classGroupId, title, description?, subject?, mode NOW|SCHEDULED, startsAt?, durationMinutes 5-480,
   joinOpensMinutesBefore 0-30, timetableSlotId?, courseId?), JoinTokenResponse (token, url,
   expiresAt, role, permissions), SessionChatMessage (id, sessionId, senderId, senderDisplayName, senderRole,
   content, createdAt), CreateSessionChatMessageRequest (content, clientMessageId), ChatSettingsRequest (enabled),
   NextSessionResponse (liveSession|null, upcomingSession|null, serverNow), SessionEvent.
   Chat content is trimmed plain text of 1-2000 characters. The server resolves sender identity and role; never accept them from the request. `clientMessageId` is unique per session/sender for safe retries. Paginate message history with the shared offset convention; return newest-first for the initial page so reconnects can recover recent messages, then reverse the page for chronological display and load older pages through offsets.
   Add stable error codes to the catalogue (common.yaml, error-codes.ts and the Flutter errors keys):
   SESSION_NOT_JOINABLE (409, details.reason NOT_STARTED|ENDED|CANCELED + joinOpensAt),
   SESSION_START_TOO_EARLY (409), LIVE_SERVICE_UNAVAILABLE (503). Reuse existing codes elsewhere.
   Update the index table in contracts/README.md.
2. Prisma (names follow the cadrage glossary; snake_case tables, uuid, Timestamptz, FK indexes):
   - enum VideoSessionStatus { SCHEDULED IN_PROGRESS COMPLETED CANCELED }
   - VideoSession (video_sessions): classGroupId (required), hostId (nullable, SetNull so history
     survives account deletion), subject?, title (200), description?, startsAt, endsAt, startedAt?,
     endedAt?, status, roomName (unique, opaque random), joinOpensMinutesBefore (default 5),
     timetableSlotId? (SetNull), courseId? (SetNull), cancelReason?, createdAt, updatedAt.
     Indexes: (classGroupId, startsAt), (hostId), (status, startsAt).
   - SessionParticipant (session_participants): id, sessionId, userId, joinedAt, leftAt?.
     It has its own id instead of the cadrage composite PK because a user can leave and rejoin
     (several intervals). Record this deviation in BACKEND_CONTEXT.md section 18.
   - SessionChatMessage (session_chat_messages): id, sessionId, senderId, clientMessageId, content, createdAt;
     add appropriate FKs/indexes and unique (sessionId, senderId, clientMessageId). Sender display name/role are resolved
     server-side. Add `chatEnabled Boolean @default(true)` to VideoSession or an equivalent explicit session setting.
     Disabled chat rejects new sends but keeps existing history readable to authorized participants. Define retention and
     account deletion/export treatment in Phase 0A; do not automatically attach chat to recordings/replays.
   - If Phase 0A confirms that “Remove participant” blocks rejoining, add SessionParticipantRemoval
     (session_participant_removals): sessionId, userId, removedAt, removedById, optional reason;
     unique(sessionId, userId). It is a persistent per-session restriction, separate from attendance
     intervals, and future join-token requests must be denied. If product policy means a one-time kick only,
     omit this model and document that behavior instead. Use a new migration; never rewrite an applied one.
     Keep LiveKit's already-issued-token revocation limitation explicit.
   - New migration only; never edit an applied one.
3. Domain (modules/videoconference/domain, pure TypeScript, no Prisma/Express/Zod):
   - Entity + status machine: SCHEDULED->IN_PROGRESS->COMPLETED, SCHEDULED->CANCELED; every other
     transition is rejected with a domain error.
   - sessionPhase(session, now): UPCOMING | JOIN_OPEN | LIVE | ENDED | CANCELED. This exact function
     is re-implemented in Dart in phase 5, so keep it tiny and fully specified by tests.
   - Validation: endsAt > startsAt, duration 5-480 min, startsAt not older than 1 minute, horizon
     max 365 days, joinOpensMinutesBefore 0-30.
   - Policies: canHost(user, class) = approved TEACHER assigned to the class or its referent, or
     ADMIN; canJoin(user, session, now); the host may start from 60 minutes before startsAt.
   - Conflicts: the same class cannot have two overlapping non-canceled sessions; a host cannot have
     two IN_PROGRESS sessions (both 409 CONFLICT, details name the conflicting session). Record both
     as decisions the team can relax.
   - Ports: VideoSessionRepositoryPort (atomic status transition with an expected-status guard),
     ClassAccessPort (membership / assignment / referent / audience lookup - expose what you need
     through the groups module facade, do not import groups internals), RoomServicePort, ClockPort.
4. Unit tests (in-memory fakes, Vitest): status machine, sessionPhase table, validations, policies,
   conflict rules.

ACCEPTANCE
- The migration applies from scratch (docker compose down -v, then up) and re-applies cleanly;
  prisma validate is OK.
- redocly lint passes on all contracts; every operation has examples and all error responses.
- lint, typecheck and test are green. No route is mounted yet.

OUT OF SCOPE: HTTP, LiveKit calls, Flutter.
```

## Phase 2 – Backend: create, schedule, list, edit, cancel

```text
PHASE 2 - BACKEND: CREATE, SCHEDULE, LIST, EDIT, CANCEL

GOAL
A teacher can create (now or scheduled), list, edit and cancel sessions for their classes; students
and teachers see only what they are allowed to see. No LiveKit yet.

READ the phase 1 contract and domain first; implement exactly what the contract says.

TASKS
1. Use cases (one class each, thin controllers, Zod .strict() in
   presentation/videoconference.validation.ts): CreateVideoSession, ListVideoSessions,
   GetVideoSession, UpdateVideoSession, CancelVideoSession.
2. Authorization (enforced in the use cases, not only in middleware):
   - create/update/cancel: approved TEACHER assigned to the class or referent, or ADMIN
     (route guard with requireApprovedTeacherMiddleware + canHost inside the use case).
   - list/get: ADMIN sees all; a host sees their own; students and teachers only see sessions of
     classes they belong to.
   - Never return roomName to non-hosts; map to DTOs, never raw Prisma rows.
3. Create: mode NOW stores startsAt = now and returns the session in SCHEDULED state (the client
   then calls /start in phase 3). mode SCHEDULED requires startsAt. Enforce the conflict rules.
4. List: filters status (comma list), classGroupId, from, to, scope=mine; sort whitelist
   startsAt:asc|desc; offset pagination through shared/http/pagination (max 100).
   Tab semantics for the app: live = IN_PROGRESS, scheduled = SCHEDULED with endsAt in the future,
   past = COMPLETED or CANCELED.
5. Update only while SCHEDULED (409 otherwise); re-run validation and conflicts.
   Cancel only while SCHEDULED (an IN_PROGRESS session must be ended, not canceled).
6. Rate limits through createRateLimiter on create/update/cancel (for example 20/min).
7. Audit log entries: session.created, session.updated, session.canceled.
8. Mount the router in videoconference.module.ts (inject ClassAccessPort and ClockPort) and keep the
   timetable route working. Mark the implemented operations x-status: implemented.

TESTS
- Unit: every use case with in-memory fakes.
- Integration (Supertest): student gets 403 on create; pending/rejected teacher 403; teacher of
  another class 403; ADMIN ok; overlap 409; bad dates 422; list scoping per role; pagination meta;
  a student never sees roomName; unknown id 404; outsider on get follows the existing convention.

ACCEPTANCE
lint, typecheck and test are green; redocly lint is green; a manual curl with two seeded users
(teacher + student of the same class) shows create/list/edit/cancel behaving as in the matrix.
Update BACKEND_CONTEXT sections 16 and 18.

OUT OF SCOPE: start/end/join, LiveKit, SSE, Flutter.
```

## Phase 3 – Backend: live lifecycle with LiveKit

```text
PHASE 3 - BACKEND: LIVE LIFECYCLE WITH LIVEKIT

GOAL
The host starts and ends a session, members get a short-lived LiveKit token only when allowed,
attendance is tracked from webhooks, and the host can moderate.

TASKS
1. RoomServicePort + LiveKitRoomAdapter (infrastructure, livekit-server-sdk): ensureRoom
   (LiveKit resource emptyTimeout from env, sensible maxParticipants), issueToken, muteParticipant,
   removeParticipant, deleteRoom. If LIVEKIT_* is missing or LiveKit is unreachable, answer
   LIVE_SERVICE_UNAVAILABLE (503). Check the current SDK API in the docs before coding.
2. POST /sessions/{id}/start (host/ADMIN): make room provisioning and DB state changes failure-safe.
   Ensure the room idempotently first; if that fails, leave the DB session SCHEDULED and return
   LIVE_SERVICE_UNAVAILABLE. Then perform the guarded atomic SCHEDULED -> IN_PROGRESS transition and set
   startedAt. Reject when the host already has an IN_PROGRESS session, or when it is more than 60 minutes
   before startsAt (SESSION_START_TOO_EARLY). If the guarded transition loses a race, reconcile/delete any
   room that is not needed; do not leave a live DB state without a usable LiveKit room or an orphan room
   without a cleanup path.
3. POST /sessions/{id}/join-token:
   - host/ADMIN: only when IN_PROGRESS (the client calls start first). If the logical session is IN_PROGRESS
     but the underlying room disappeared after its empty timeout, safely recreate the room idempotently before
     issuing the token. Never recreate a room for a COMPLETED or CANCELED session.
   - member student/teacher: only when IN_PROGRESS, otherwise 409 SESSION_NOT_JOINABLE with
     details.reason (NOT_STARTED | ENDED | CANCELED) and joinOpensAt. Outsiders 403. SUSPENDED users blocked.
   - Token: identity = user id, name = display name, metadata {role: HOST|STUDENT}, short TTL from env,
     and only required grants (`roomJoin`, `canSubscribe`, `canPublish`, `canPublishData`). Do not grant
     `roomAdmin` to the host by default: moderation is performed by authenticated backend endpoints using
     the server-side SDK. The response carries LIVEKIT_PUBLIC_URL as url. Never log tokens (check pino
     redaction). Verify current self-hosted token revocation behavior; block future join-token issuance for
     removed users and document any residual reconnect window for an already-issued token.
   - If the approved policy blocks rejoining, check SessionParticipantRemoval before issuing a token. Persist
     the restriction before trying to evict the active participant; future join-token requests must be denied.
     If LiveKit eviction fails, report the failure and leave enough state for safe retry/reconciliation. If the
     approved policy is one-time kick only, implement and test that policy explicitly instead.
   - Stricter rate limit on this endpoint.
4. POST /sessions/{id}/end (host/ADMIN): perform an atomic IN_PROGRESS -> COMPLETED transition and close
   open attendance intervals/set endedAt in the database first; then delete the LiveKit room idempotently.
   If room deletion fails or the API crashes after the DB transition, the reconciliation job must retry cleanup.
   Double-clicks/retries return the existing completed result safely. A later `room_finished` webhook must not
   change the completed session or duplicate attendance closure.
5. POST /webhooks/livekit: verify the signature with the current official SDK receiver. Confirm whether
   that SDK version requires raw bytes or parsed JSON; preserve exactly what signature verification needs,
   accounting for the global express.json middleware order. Add a new migration for a webhook-event receipt
   table keyed by LiveKit event ID (or another official stable deduplication key); process each event and
   its receipt atomically so retries cannot create duplicate intervals. Handle participant_joined /
   participant_left (open/close SessionParticipant intervals idempotently). A `room_finished` caused by an
   empty-room timeout must NOT complete the SmartClass session: the logical session remains IN_PROGRESS and
   the room must be recreatable when someone rejoins. The explicit end use case marks COMPLETED before
   deleting the room. Account for duplicate and delayed events. Unknown rooms are ignored; answer fast and
   use a dedicated limiter that does not accidentally block legitimate provider retries.
6. Moderation (host/ADMIN, RG8): mute participant, mute all (except the host), remove participant.
   Audit each action. GET participants returns attendance intervals + total duration, offset pagination.
7. Lifecycle sweeper: one in-process background job started in main.ts and stopped in graceful
   shutdown: (a) SCHEDULED sessions whose endsAt + grace has passed -> CANCELED (cancelReason
   NOT_STARTED); (b) reconcile orphan rooms and completed sessions whose LiveKit room was not deleted.
   Do NOT auto-complete an IN_PROGRESS session merely because its LiveKit room became empty; the room may
   be recreated on rejoin, as specified in ADR-0008. If an automatic idle-end policy is later desired, it
   must use a separate explicit setting and be approved/documented as a business rule. Idempotent. Define
   a safe fallback if LiveKit is temporarily unavailable; do not infer “empty” from a failed query. Write
   the single-instance assumption in BACKEND_CONTEXT §18 (a PostgreSQL advisory lock is the multi-instance path).
8. GDPR: extend the delete-account and export-user-data use cases so sessions hosted or attended by
   the user are handled (anonymize the host, include attendance in the export). Handle chat messages from deleted users
   according to the retention decision from Phase 0A; document whether they are anonymized, retained, and included in export.
9. Persistent chat: implement `GET /sessions/{id}/messages` (authorized audience, offset pagination) and
   `POST /sessions/{id}/messages` (authorized participant, IN_PROGRESS only, strict content validation, rate limit,
   idempotent `clientMessageId`, server-derived sender identity). Persist before delivery and return the canonical message.
   `PATCH /sessions/{id}/chat-settings` is host/ADMIN only, audited, and controls whether new messages may be sent.
   After the database commit, call a `LiveEventsPublisherPort` seam to emit `session.chat-message-created` to authorized audience
   members only; Phase 4 implements the concrete SSE hub/fan-out. Existing chat history remains readable when new messages are disabled.
10. Screen-share authorization: inspect current LiveKit SDK/server support for source-level publishing permissions.
    Permit host screen-share publication only, deny it for students wherever the SDK supports source-level grants, and
    implement/test the strongest supported server/room enforcement if token grants alone are insufficient. Do not give
    `roomAdmin` to participant tokens just for screen sharing.
11. Mark the operations implemented in the contract; update the context files.

TESTS
- Token grant matrix: host, member student, member teacher, outsider, suspended user, pending teacher,
  and (if the approved removal policy blocks rejoin) removed participant, each against
  SCHEDULED / IN_PROGRESS / COMPLETED / CANCELED. Test host-vs-student screen-share publishing permissions using the
  actual SDK/server mechanism, including a bypass attempt where practical.
- Chat: outsider cannot read or post; live session authorization is enforced; blank/oversized content is rejected;
  duplicate clientMessageId retries do not duplicate messages; disabled chat blocks sends but allows authorized reads;
  only the server-derived canonical message is emitted by SSE; chat settings and send rate limits are enforced.
- Start race (two parallel starts, one wins), end idempotency, webhook idempotency + bad signature 401,
  sweeper cases with a fake ClockPort, adapter unit tests with a mocked SDK.
- Manual check against the real container: start, mint a token, connect with a LiveKit sample app or
  the CLI, see participant_joined arrive and the attendance row appear. Document the steps.

ACCEPTANCE
lint, typecheck and test are green; redocly is green; the manual end-to-end check works; stopping
livekit makes start and join-token answer 503 LIVE_SERVICE_UNAVAILABLE while the rest of the API stays
healthy.

OUT OF SCOPE: SSE push, next-session endpoint, Flutter, recording.
```

## Phase 4 – Backend: realtime push (SSE) and the dashboard feed

```text
PHASE 4 - BACKEND: REALTIME PUSH (SSE) + DASHBOARD FEED

GOAL
Clients learn about session changes instantly through one SSE stream per user (no polling), and the
dashboard widget has a single endpoint that says what to show.

TASKS
1. GET /videoconference/events (text/event-stream), Bearer auth, heartbeat comment every 10 s
   (reuse the pattern of the existing AI SSE endpoints - find and reuse the shared helper if there
   is one). Headers: Cache-Control no-store, X-Accel-Buffering no. Make sure nothing in the middleware
   chain buffers or compresses the stream.
2. LiveEventsPublisherPort (application) + InMemoryLiveEventsHub (infrastructure): map userId ->
   open connections, max 3 per user, cleanup on close/error, write-backpressure safe. The audience of
   an event = class members + host + assigned teachers + referent (ClassAccessPort.listAudience).
3. Events: session.created, session.updated, session.canceled, session.started, session.ended,
   session.participant-count-changed (from verified attendance/room events where useful), and
   session.chat-message-created (canonical saved message, only to authorized audience members).
   Small payload {type, sessionId, classGroupId, status, startsAt, at}; the client refetches details.
   Publish from the existing create/update/cancel/start/end use cases AFTER the commit; a failed
   publish never fails the request.
4. GET /videoconference/me/next-session?horizonHours=24 (1-72): for the caller's classes (student
   membership; teacher: hosted/assigned classes) return a clear dashboard payload with the highest-priority
   live session (if any), the nearest scheduled session in the horizon (if any), and serverNow. This prevents
   an already-live session from hiding the next upcoming session when a user belongs to multiple classes.
   Include id, title, subject, class name, host name, startsAt, endsAt, joinOpensAt, status and participantCount.
   Document deterministic ordering and return nulls/empty collections honestly when there is no match.
5. Document the SSE stream in the contract (event names + JSON schema in the description, x-status
   implemented) and note the single-instance fan-out in BACKEND_CONTEXT section 18 (Redis pub/sub is the
   scale-out path).

TESTS
- Hub unit tests: subscribe, fan-out to the right audience only, per-user limit, cleanup, no leak.
- Integration: open the stream, create/start/end a session, assert the events arrive in order; a user
  outside the class receives nothing; unauthenticated gets 401.
- next-session selection matrix with a fake clock: nothing, upcoming in 3 h, in 4 min (JOIN_OPEN), live,
  canceled, two classes, teacher vs student.

ACCEPTANCE
lint, typecheck and test are green; redocly is green; curl -N against the stream shows heartbeats and
events.

OUT OF SCOPE: Flutter.
```

## Phase 5 – Flutter: foundation, sessions screen, scheduling

```text
PHASE 5 - FLUTTER: FOUNDATION, SESSIONS SCREEN, SCHEDULING

GOAL
The videoconference screen shows REAL sessions (no mocks) that update live through SSE, and a teacher
can schedule, edit and cancel sessions. Joining a room comes in phase 6.

TASKS
1. Dependencies and platform setup: add livekit_client and wakelock_plus (permission_handler only if
   needed). Check the version constraints against the Dart/Flutter SDK in pubspec.yaml.
   Android: CAMERA, RECORD_AUDIO, MODIFY_AUDIO_SETTINGS, INTERNET, ACCESS_NETWORK_STATE (+ the
   Bluetooth permission for audio routing if the docs require it) and the minSdk the plugins need.
   iOS Info.plist: camera and microphone usage descriptions.
   Web: note in PROJECT_CONTEXT that getUserMedia needs HTTPS (or localhost) and that ws:// signaling
   is blocked from an https page.
2. Feature layers under lib/features/videoconference/ (Clean Architecture, pure Dart domain):
   - domain: VideoSession, SessionStatus, SessionPhase + phaseOf(session, now, serverOffset) mirroring
     the backend sessionPhase exactly, VideoconferenceRepository interface.
   - infrastructure: remote datasource over ApiClient (every contract operation used in this phase),
     models/mappers, repository implementation. ApiException.code maps to errors.<CODE> l10n keys.
   - application: providers - videoSessionsProvider per tab (live / scheduled / past, load-more with
     offset pagination), a session-actions notifier, liveEventsProvider.
3. SSE client in core/network (shared SSE line parser; reuse the one used by the AI course streaming
   if it exists): Dio stream, Bearer header, auto-reconnect with exponential backoff + jitter (cap
   30 s), pause when the app goes to background and resume on foreground, close on logout, re-open
   after a token refresh. On every (re)connect emit a resync event so listeners refetch. One long-lived
   connection is NOT polling; document this in PROJECT_CONTEXT.
4. Replace the mock videoconference_page.dart: three tabs (Live / Scheduled / Past) with loading /
   empty / error / data states through AsyncValue, user-triggered pull-to-refresh, and lists
   invalidated by SSE events. Delete every hardcoded session and every hardcoded French string. Cards
   show class, subject, host, time and a phase badge. Student cards have no join button yet.
5. Teacher scheduling flow (responsive: dialog or side panel from 1024 px, bottom sheet on mobile):
   class picker (classes the user teaches or refers; ADMIN: all), subject, title (suggest
   '<subject> - <class>'), date + time pickers, duration chips (45 / 60 / 90 / 120 + custom),
   'students can join from' chips (5 / 10 / 15 min before), description. Edit and cancel (with a
   confirm dialog) on SCHEDULED sessions. Only the SCHEDULED mode here; 'Start now' arrives in phase 6.
6. All text through context.tr, keys in app_fr.arb and app_en.arb (follow the existing flat snake_case
   key style), regenerate the localizations.

TESTS
- Unit: phaseOf table (same cases as the backend test), SSE parser, reconnect/backoff with fake async.
- Widget: list states, schedule form validation, role-based visibility (teacher vs student).
- flutter analyze lib/ is clean, flutter test is green.

ACCEPTANCE
Two logged-in users (teacher on Chrome, student in a second browser or the Android emulator): the
teacher schedules a session and it appears on the student's Scheduled tab without any refresh;
canceling removes it.

OUT OF SCOPE: room, lobby, dashboard widgets.
```

## Phase 5A – Design the live room for web and mobile (before implementation)

```text
PHASE 5A - LIVE ROOM DESIGN SPECIFICATION (NO LIVE ROOM CODE YET)

GOAL
Create two distinct, high-quality visual design references for SmartClass live lessons: a wide web/desktop
experience and a mobile experience. This phase produces design artifacts only; do not implement LiveKit or
change application logic yet.

READ FIRST
- Frontend/DESIGN.md and Frontend/PROJECT_CONTEXT.md.
- Existing design folders under Frontend/assets/design/; follow SmartClass's current Academic Precision
  style, typography, spacing, surfaces, colors, border radii and existing components.
- The Phase 6 requirements in this prompt pack.

TASKS
1. Create `Frontend/assets/design/live_room_web/` and `Frontend/assets/design/live_room_mobile/`.
2. In each folder create:
   - `DESIGN.md`: layout rationale, component inventory, responsive rules, states, accessibility and tokens used.
   - `code.html`: self-contained preview using realistic but clearly labeled design-only sample data.
   - `screen.png`: capture the rendered preview if the available environment supports browser/screenshot capture.
     Never create a fake screenshot file; if screenshot capture is unavailable, explain that and leave the real
     HTML preview ready for manual capture.
3. Web/desktop design (wide screen): top session bar with course/class/title, live status and elapsed time;
   central active-speaker/video stage; compact participant strip/grid; right rail with Participants and Chat tabs;
   bottom controls for mic, camera, screen share, raise hand, leave and host-only End for everyone; visible network
   state and accessible labels. Avoid crowding the active speaker.
4. Mobile design: portrait-first full-screen speaker/video area; readable compact session header; thumb-reachable
   floating/bottom controls; Participants and Chat in bottom sheets; clear leave/end distinction; safe-area padding;
   landscape adaptation; tablet layout notes. Do not merely shrink the desktop layout.
5. Include state variants for camera/mic permission denied, connecting, reconnecting, poor network, host not yet
   started, participant removed, session ended, empty participant list and chat empty state.
6. Use the existing design system. Do not add new fonts, icons packages or UI dependencies. Keep sample copy in
   English in the design preview, but document that implemented app text must use the existing fr/en localization.
7. After creating the artifacts, summarize the differences between web and mobile and list any UX decisions that
   need approval. Do not continue into Phase 6 in this run.

ACCEPTANCE
- Both folders exist and their HTML previews are independently viewable.
- The mobile design prioritizes thumb reach and does not look like a compressed desktop design.
- Host-only actions are visually distinct; Leave and End for everyone cannot be confused.
- Design notes match the existing SmartClass design system and Phase 6 feature scope.
```

## Phase 6 – Flutter: lobby and live room (web design + mobile design)

```text
PHASE 6 - FLUTTER: LOBBY + LIVE ROOM (WEB DESIGN + MOBILE DESIGN)

GOAL
The teacher starts or joins a room and students join it, with a dedicated desktop/web layout and a
dedicated mobile layout.

DESIGN SOURCES
Look for Frontend/assets/design/live_room_web/ and live_room_mobile/ (screen.png, code.html,
DESIGN.md, like the other design folders). If present, they are the visual source of truth. If
missing, build from Frontend/DESIGN.md (Academic Precision tokens) and say so in the report.

TASKS
1. Routes outside the ShellRoute (full screen, like the secure exam): /videoconference/:sessionId/lobby
   and /videoconference/:sessionId/room, with redirect guards (not authenticated -> login; wrong class
   -> error screen; session ended or canceled -> ended screen).
2. Port + adapter: RoomPort (abstract, plain Dart types) in domain; LiveKitRoomAdapter in
   infrastructure wrapping livekit_client; LiveRoomController (Riverpod notifier) exposing the
   connection state (connecting, connected, reconnecting, disconnected(reason), endedByHost, removed,
   permissionDenied, error(code)), participants, local mic/camera state, active speaker, hand raises
   and chat. Join flow: ask the API for the join token, connect, publish according to the role.
3. Lobby: camera/microphone preview and toggles, device selection on web/desktop, permission states
   (granted / denied / permanently denied with a way to open the settings), connection hint.
   Student lobby before the start: countdown + 'waiting for your teacher'; it enters automatically when
   the session.started SSE event arrives. Host lobby: a Start session button (calls /start, then
   /join-token). Add the 'Start now' mode to the teacher create flow here (create, start, open room).
4. Room features (MVP): mic/camera toggle, switch camera (mobile), audio output choice, and host-only screen share where
   supported (feature-detect; hide or explain unavailable controls otherwise). Verify current SDK configuration for Flutter Web,
   Android and iOS, including Android MediaProjection/foreground-service behavior and iOS Broadcast Extension only where
   required. Do not claim support that is not tested. Enforce host-only screen-share publishing by the strongest supported
   token/server/room policy, not by hiding the student button. Show a clear active-share state, make shared content prominent,
   and let the host stop sharing. Add participant list with speaking indicators and raise hand (LiveKit data message).
   Persistent chat: load paginated history via GET messages on room entry/reconnect; send via POST messages; receive canonical
   saved messages through authenticated SSE; deduplicate by message id/clientMessageId; support unread count, failure/retry,
   loading/empty/error and chat-disabled states. Never trust client-provided sender identity/role or arbitrary data packets as
   canonical chat. Add connection-quality, adaptive stream + simulcast and reconnecting overlay. Students join muted with
   camera off. Host can mute one/mute all/remove and enable/disable chat. Distinguish Leave from End for everyone; host can
   leave and rejoin the same logical live session.
5. Web/desktop view (from 1024 px, views/web_live_room_view.dart): main stage switches between active speaker and shared
   screen; participant strip; right panel with Participants / Chat tabs; top bar (title, timer, network and share state); bottom
   control bar. Chat panel supports persisted history, composer, send/error and disabled states.
   Mobile view (below 1024 px, views/mobile_live_room_view.dart): full-screen speaker/shared-content stage, compact floating
   controls, bottom sheets for participants and chat, keyboard-aware composer, portrait + landscape, safe areas, 2-column grid
   on tablets.
   Both views use the same controller; no business logic in widgets; every file < 200 lines (split widgets).
6. Keep the screen awake while in the room and release it on leave. Handle the app lifecycle (phone call,
   background) as the LiveKit docs describe; keep audio in background only if the docs make it simple, and
   tell me what you chose.
7. All text through context.tr (fr + en). Error codes map to errors.* keys.

TESTS
- LiveRoomController with a fake RoomPort: join, reconnect, endedByHost, removed, permission denied, hand raise and
  screen-share state transitions.
- Chat repository/provider tests: load history, send, canonical SSE delivery, duplicate event, reconnect/resync, retry,
  disabled chat and unauthorized responses.
- Widget tests: role-based host/student controls, host-only screen-share visibility, responsive web/mobile layout, lobby
  permissions, chat empty/loading/error/disabled states and keyboard behavior.
- Manual matrix (document it in PROJECT_CONTEXT): Chrome host + Android student on the same LAN, Wi-Fi
  drop and recover, host leaves and rejoins, host ends, host removes a student, mute all.

ACCEPTANCE
The teacher on Chrome starts a session, a student on Android joins from the lobby, they see and hear each
other, hand raise works, persistent chat history/live delivery/reconnect work, host-only screen sharing works on the tested supported platform, student screen-share publishing is denied, host moderation works, and End for everyone sends both to the ended
screen.

OUT OF SCOPE: dashboard widgets, recording.
```

## Phase 7 – Flutter: dashboard widgets (student + teacher)

```text
PHASE 7 - FLUTTER: DASHBOARD WIDGETS (STUDENT + TEACHER)

GOAL
Students see a smart session widget on their dashboard; teachers get a next-session / go-live card.

TASKS
1. Student data: replace the TODO seam studentTodayLiveProvider with GET /videoconference/me/next-session
   (extend TodayLiveSession and map the server response, including status, phase, startsAt, joinOpensAt,
   participantCount and serverNow). Keep null = widget hidden when there is no live or upcoming session.
   If the response contains both a live and an upcoming session, prioritize the live session in the primary
   card and make the upcoming session discoverable rather than silently discarding it. Remove TODO comments.
   Invalidate on SSE events, on every SSE reconnect/resync and on app resume. No periodic fetching. SSE
   is only an in-app update channel; it does not wake a closed mobile app or replace push/email reminders.
2. Clock: offset = serverNow - deviceNow at fetch time; all phase maths use the corrected time.
3. Adapt StudentImminentLiveCard (keep the existing look) to three states:
   - UPCOMING: title, teacher, class, start time ('Today 14:00' / 'Tomorrow 09:00') and a coarse
     relative label ('in 5 h') recomputed at minute boundaries; no join button.
   - JOIN_OPEN (the last N minutes, N = session.joinOpensMinutesBefore, default 5): live mm:ss countdown
     and an 'Enter waiting room' button that opens the lobby.
   - LIVE: pulsing LIVE badge, participant count, 'Join now'.
   Hidden when nothing is inside the horizon or the session is canceled/ended (react to the push event).
4. Timers: one one-shot timer to the next phase boundary + a display-only 1 s ticker during the
   countdown, disposed with the widget, doing zero I/O. Add a comment pointing to ADR-0009 and a widget
   test with fake async proving that no network call happens on a tick.
5. Teacher dashboard: a card for the next or live session (Enter room / Start now / countdown for the
   host) and quick actions 'Go live now' (opens the create flow in NOW mode) and 'Schedule'. Wire the
   existing next-slot pill and the button that pushes /videoconference.
6. In-app live banner: when a session of the student's class becomes LIVE while the user is elsewhere in
   the app, show the existing smart toast with a Join action (from the SSE event).
7. No fake notification badge (ADR-0003 still applies). All text through context.tr (fr + en).

TESTS
Widget tests per phase state with a fake clock (UPCOMING, 5:00 -> 0:00 countdown, LIVE, hidden, canceled);
provider test: event -> invalidate -> refetch; teacher card states. flutter analyze + flutter test green.

ACCEPTANCE
The teacher schedules a session 6 minutes ahead: the student widget shows it with its start time, switches
to the mm:ss countdown at 5:00, and the button opens the lobby; when the teacher starts, the student is
admitted. A session started now shows LIVE immediately; canceling hides the widget instantly.
```

## Phase 8 – Hardening, QA and documentation

```text
PHASE 8 - HARDENING, QA AND DOCUMENTATION

TASKS
1. Security review (list findings and fix them): token TTL and least-privilege grants, roomName never
   leaked, IDOR on every endpoint, rate limits on token / webhook / SSE, webhook signature + event-ID
   deduplication, CORS for Flutter web, secrets only from env, pino redaction covers LiveKit tokens and
   secrets, audit coverage, SUSPENDED users cut from the SSE stream and blocked from tokens, removed users
   blocked from new join tokens, safe reconnect/revocation behavior verified for self-hosted LiveKit, and
   no credentials in `.env.example`, docs, Flutter assets, logs or generated artifacts. Verify authorization on chat history/writes and SSE fan-out, sender identity derived server-side, length limits/rate limits/idempotency, retention/export/deletion policy, and host-only screen-share permissions cannot be bypassed by hiding controls alone.
2. Resilience: SSE reconnect storms, LiveKit restart mid-session (UI shows reconnecting, then ended), API
   restart mid-session, duplicate tabs, double start/end clicks, clock skew.
3. Load: run a LiveKit load test with about 30 simulated participants using the LiveKit CLI (check the
   command in the docs), watch CPU and bandwidth, and report the numbers plus the limits you recommend
   (max participants per room, simulcast settings).
4. Deployment notes in Backend/README.md: HTTPS + WSS are mandatory for web, domain + certificates, ports
   including the TCP/TLS fallback, enabling the built-in TURN for mobile carrier NAT, firewall list,
   LIVEKIT_* for production, Windows/Docker Desktop caveats (UDP).
5. Docs: update BACKEND_CONTEXT (1.2 packages, 10 RG table: RG8 hosting/moderation implemented, RG11 and
   RG14 pending, 16 status, 18 journal + open questions), PROJECT_CONTEXT (a new section like section 19:
   structure, rules, endpoints used, SSE behavior), the contracts README index, the root README roadmap
   (Sprint 5 live planner) and .env.example completeness. Every operation marked implemented.
6. Final regression: backend lint / typecheck / test, redocly lint, flutter analyze, flutter test, then
   docker compose down -v && up from scratch.

ACCEPTANCE
Everything above is green, the manual matrix from phase 6 is re-run, and the report ends with a short
list of known limits.
```

## Phase 9 (optional) – Recording, replay, AI summary

```text
PHASE 9 (OPTIONAL) - RECORDING, REPLAY, AI SUMMARY  (UC3/UC4, RG8, RG11, RG14)

START IN PLANNING MODE ONLY: write an ADR and an implementation plan, then STOP and wait for my approval.
Decisions needed first (do not pick silently): object storage engine (MinIO is archived; see
BACKEND_CONTEXT section 1.1), LiveKit Egress + Redis footprint, encryption at rest and retention period
(RG14), the replay player package for Flutter, and a self-hosted speech-to-text engine (RG27).

After approval, build in this order:
A. Recording: host-only start/stop (RG8), Recording model (storageKey, durationSec, sizeBytes, status,
   expiresAt), a REC badge + consent notice visible to participants, a purge job for expired files, an
   authenticated replay endpoint for class members (UC4), a Flutter replay screen in the Past tab.
B. Transcript + summary: local STT on the recording audio, summary through the existing AiGatewayPort,
   SessionSummary DRAFT -> VALIDATED, edited by the teacher before students see it (RG11), shown next to
   the replay.
Same rules: contract-first, tests, no mocks, update the context files.
```

## 6. Suggestions to make it better and more advanced

Sorted by value for effort. Effort: S = about a day, M = a few days, L = a week or more.

| # | Idea | Why it matters | Effort |
| --- | --- | --- | --- |
| 1 | Start a session from a timetable slot | Your `timetable_slots` already exist (`timetableSlotId` is in the model); one tap instead of re-entering class, title and time | S |
| 2 | Data-saver / audio-only mode + auto quality drop | Students on mobile data in weak areas keep following the class | S |
| 3 | Pre-flight device test (mic level, camera, bandwidth) | Fewer “can’t hear me” problems at the start of class | S |
| 4 | Add to calendar (.ics) for students | Works with the 5-minute widget without a notifications module | S |
| 5 | Attendance sheet export (PDF/CSV) from the webhook intervals | Teachers get the roll call for free; reuses your PDF export code | S–M |
| 6 | Reminders (T-15 / T-5 min) by email, later push | Your nodemailer is already wired; push waits for the notifications module | M |
| 7 | Recurring sessions (weekly) | One setup for the whole semester | M |
| 8 | Link a session to a course chapter and show it in the room | Ties live classes to your AI course studio; feeds the RG11 summary later | M |
| 9 | Live quick-quiz in the room using your AI quiz generator | Strong demo feature that uses what you already built | M–L |
| 10 | Waiting room with admit/deny + lock room | Control for exams-adjacent or sensitive sessions | M |
| 11 | Co-host / teaching assistant role | Two teachers or a TA can moderate | M |
| 12 | Admin live monitor (active rooms, join counts, force end) | Fits the Sprint 6 analytics and admin oversight | M |
| 13 | Live captions (FR/EN, later Arabic) from local STT | Accessibility; reuses the Phase 9 STT engine | L |
| 14 | Breakout rooms for group work | Collaboration between students (UC5) | L |
| 15 | Arabic (RTL) locale for the whole app | The app only ships fr/en today | M |

My pick for the first release after the MVP: 1, 2, 3, 4, then 5.

## 7. Open questions to confirm with your team

These are the defaults the prompts assume. Change them in the prompt before running the phase if you disagree.

1. Can a class referent who does not teach host sessions? (Prompts say yes.)
2. Students join muted with the camera off and may unmute; is there a hard participant cap per room?
3. Should two overlapping sessions for the same class be blocked? (Prompts block it with 409.)
4. Early-start window of 60 minutes and a per-session join window of 5, 10 or 15 minutes.
5. How long is attendance data kept? RG14 only defines retention for recordings.
6. Persistent chat is included in the MVP for late joiners and reconnects. Confirm the retention/deletion period and how messages from deleted users are anonymized/exported. Chat is not automatically attached to recordings or replays; that requires a separate explicit decision.


## 8. Official documentation the agent must re-check at implementation time

Do not pin APIs from this list without checking the installed package version and the current official docs:

- LiveKit deployment, ports, NAT/TURN and SSL: <https://docs.livekit.io/transport/self-hosting/deployment/> and <https://docs.livekit.io/transport/self-hosting/ports-firewall/>
- LiveKit Flutter SDK and supported platforms, including screen share: <https://docs.livekit.io/reference/client-sdk-flutter/>
- LiveKit data packets for transient room signals (not canonical persisted chat): <https://docs.livekit.io/transport/data/packets/>
- LiveKit tokens and grants, especially `roomAdmin` and self-hosted token revocation: <https://docs.livekit.io/home/server/generating-tokens>
- LiveKit webhooks, event IDs and delivery behavior: <https://docs.livekit.io/intro/basics/rooms-participants-tracks/webhooks-events/>
- SSE browser behavior: <https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events>
- Socket.IO behavior, if ever reconsidered: <https://socket.io/docs/v4/>

The official docs currently describe LiveKit self-hosting as requiring careful UDP/TCP/network configuration and a trusted TLS setup for production; HTTPS web apps require a secure WSS signaling URL. Do not use `ws://` for a production HTTPS deployment. A local Docker Desktop test is not enough to certify production connectivity.

## 9. Final recommendation

For the MVP, deliver the end-to-end path in this order: (1) safe repository preflight, (2) LiveKit local service and contracts/data model, (3) schedule/list/edit/cancel with authorization, (4) start/join/end/attendance/moderation with webhook deduplication, (5) SSE dashboard data, (6) real Flutter session list and scheduling, (7) tested lobby/room with persistent chat, host-only screen sharing and separate responsive web/mobile views, (8) dashboard countdowns and hardening. Leave recording, replay, AI summaries, recurring sessions, email/push reminders and breakout rooms outside the MVP until this core flow has passed real browser + Android end-to-end tests.

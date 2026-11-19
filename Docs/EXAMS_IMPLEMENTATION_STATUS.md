# Exams module — implementation status

This document records what the exam feature actually does today, which
platform mechanisms are real, and which parts are deliberate limitations.
It is not a roadmap: anything listed as unsupported has no fake fallback.

## Architecture

- Backend: `Backend/src/modules/exams` (Clean Architecture: domain,
  application use-cases, infrastructure adapters, presentation controllers).
  The backend is the only source of truth for the server clock, duration,
  answers, correction, score, exam state, sanctions, submission and access
  control.
- Contract: `contracts/exams.openapi.yaml` (OpenAPI 3.1, all 25 operations
  marked `x-status: implemented`).
- Frontend: `Frontend/lib/features/exams` split into domain, infrastructure,
  application (Riverpod providers/controller) and presentation (role-split
  pages and widgets). No mock repository or mock exam data source exists in
  the feature.
- Student payloads never contain `correctOptionIds` or `explanation`; the
  student result contains per-question correctness and points only. The
  projection lives in `Backend/src/modules/exams/application/exam-projection.ts`
  and `get-student-result.use-case.ts`.

## Verified locally

- `Backend`: `npx prisma generate` succeeds; exam unit tests pass
  (32 tests across `exam-policy`, `exam-import.parser`, `exams-ai`,
  `exams.use-cases`). `npm run typecheck` only reports the pre-existing
  `livekit-server-sdk` module errors outside the exams module.
- `Frontend`: `flutter analyze --no-pub` reports no issues.
- `Frontend`: `flutter test` — the exam list widget test was rewritten for
  the real page and passes. The suite still has unrelated, pre-existing
  failures in course/dashboard tests (`course_section_builder_page_test`,
  `widget_test` StudentDashboard cases, `web_views_test` CourseReader and
  AiCourseCreator cases). They are not caused by the exams feature.

## Roles

- Teacher: create manually, import a file (preview only, persisted only by
  `POST /exams`), generate an AI preview, edit drafts, publish, close, read
  results and monitoring events/replays. Opening the authoring or management
  page never creates an attempt, a timer or an answer.
- Student: list available exams, start or resume (idempotent `POST /start`),
  answer/skip, autosave, submit, and read the result only after the exam is
  closed and `showResultsAfterClose` is enabled (admin override exists).
- Cross-student access is rejected on the server (attempt ownership checks),
  and a second submission returns an error instead of overwriting.

## Timer

- `expiresAt = min(startedAt + duration, exam.endsAt)`.
- Every server response carries `remainingMs`; the attempt page re-anchors
  on it. The 1-second ticker is local only and never polls the network.
- Autosave is debounced (700 ms) with retries; manual submit flushes dirty
  answers first.

## Anti-fraud policy

Implemented in `Backend/src/modules/exams/domain/exam-policy.ts` and driven
by server time, not client claims.

- Confirmed exits (`TAB_HIDDEN`, `PAGE_LEAVE`, `APP_BACKGROUND`,
  `FULLSCREEN_EXIT`): terminate on the first occurrence when the measured
  duration is `null` or `>= 1500 ms`; shorter blips only warn.
- Copy/paste/cut and screenshot attempts accumulate; the attempt terminates
  at `maxViolationCount` (default 3).
- Network loss/restore, camera denial and technical interruptions are
  recorded only: they never sanction a student.
- `FOCUS_LOST`, `CONTEXT_MENU` and `GAZE_OFF_SCREEN` warn only.
- Every event is timestamped and bound to the attempt; the teacher sees
  severity, automatic decision, event state and optional replay.

## Platform mechanisms (what is real)

| Area | Web | Android | iOS |
| --- | --- | --- | --- |
| Tab/visibility/blur/leave/refresh detection | Real (`dart:html` listeners, `sendBeacon` on page leave) | Lifecycle observer | Lifecycle observer |
| Copy/paste/cut/context menu/shortcuts | Blocked as far as the browser allows | Not applicable (no DOM) | Not applicable (no DOM) |
| Screenshot blocking | **Not possible and never claimed** | `FLAG_SECURE` via MethodChannel | **Cannot block**; real `UIScreen.capturedDidChangeNotification` detection only |
| Camera preview/recording | `getUserMedia` + `HtmlElementView` + `MediaRecorder` rolling buffer | **Unsupported** (no camera plugin compiled) | **Unsupported** (no camera plugin compiled) |
| Video replay | Authenticated bytes + Blob URL | **Unsupported** (no video player dependency) | **Unsupported** |
| Fullscreen | Browser fullscreen API (may be refused) | Not applicable | Not applicable |

The web camera/guard are loaded through conditional exports
(`dart.library.html`), so native builds never import `dart:html`.

## Face/gaze analysis

- `Frontend/assets/mobilefacenet.tflite` was inspected: input
  `[1,112,112,3]` float32 RGB, output `[1,192]` named `embeddings`.
  It is a face-recognition embedding model, **not** a gaze estimator or a
  face detector.
- It is therefore **not used** for gaze or presence detection. No gaze
  signal is fabricated. The `GAZE_OFF_SCREEN` event exists in the contract
  and policy for a future, genuinely compatible model (for example a
  TFLite gaze/landmark model with documented inputs), but nothing emits it
  today.
- No sustained-off-screen logic (>3 s), blink filtering or "transient"
  gaze sanction is active because no model can support it honestly.

### Proposed TFLite-compatible complement (not implemented)

A real gaze feature would need two locally-executed models that this asset
cannot provide:

1. A face/person detector (for example a TFLite BlazeFace or MediaPipe Face
   Detection model) to produce normalised eye/landmark coordinates inside the
   existing 640×480 camera frame.
2. A gaze/eye-state model (for example a TFLite MobileNet-style gaze
   regressor or an eye-open/closed classifier) trained on those crops,
   returning a yaw/pitch estimate plus an eye-closure score.

Both must be shipped as `.tflite` assets with documented input/output
tensors and quantisation, run on-device only, and feed a "sustained
off-screen" timer (>3 s) before the existing `GAZE_OFF_SCREEN` warning is
reported. Blinks would be filtered by the eye-closure score. Until such
models are inspected and validated, the app reports nothing for gaze.

## AI generation

- The teacher selects one or more courses from the class through
  `GET /exams/classes/:classGroupId/courses`, which returns only PUBLISHED
  courses: those linked to the class, plus the caller's own published courses
  that have no class link yet (the courses UI does not assign a class, so a
  published unrestricted course would otherwise be invisible). Publication
  requires every generated section to be VALIDATED, so every listed course is
  generated + validated.
- `POST /exams/ai/generate` receives `courseIds` and rejects any id that is
  unknown, unpublished, or not linked to the selected class. No other course
  content is sent to the model. (When `courseIds` is omitted the backend keeps
  the legacy behaviour of using all published courses of the class; the app
  always sends an explicit selection and disables generation until at least
  one course is chosen.)
- Requires the local model installed with Ollama
  (`hf.co/unsloth/Qwen3.5-4B-GGUF:Q4_1`); the exams module constructs its
  gateway with `model` and `fallbackModel` both pinned to `AI_MODEL` and
  verifies `/api/tags` before generating. It never downloads a model.
- Output must be valid JSON; malformed content is rejected with
  `AI_INVALID_OUTPUT`, and nothing is persisted until the teacher confirms
  through `POST /exams`.
- Local generation is slow when the model does not fit fully in VRAM (this
  machine runs it ~63% on CPU). A 10-question generation takes about
  4–6 minutes, so `AI_TIMEOUT_MS` is set to 15 minutes and a run that exceeds
  it returns `AI_TIMEOUT` (504, "took too long") — distinct from an
  unreachable model (`AI_MODEL_UNAVAILABLE`/503). The app waits 16 minutes and
  tells the teacher generation can take several minutes. A model crash is
  still surfaced as a gateway error; retrying is the fix.

## Retention, privacy and honest gaps

- Recordings are optional, authenticated, streamed by the backend and can
  be deleted from the teacher UI. There is no automatic retention scheduler:
  deletion is explicit.
- Monitoring never assumes a video exists; the UI only loads a replay when
  the backend reports one.
- Camera consent is a separate explicit checkbox; a recording starts only
  after consent, and the preview carries an active indicator.
- The Android debug APK compiles with the `FLAG_SECURE` channel. iOS cannot
  be compiled on this Windows host; only the Flutter SDK header usage was
  checked, not a device build.
- Not exercised in this environment: real browser end-to-end runs, real
  camera capture, a live Ollama generation, and on-device behaviour of the
  native lifecycle/capture channels. The Dart analyzer, unit tests and the
  Android compile do not prove runtime hardware behaviour.

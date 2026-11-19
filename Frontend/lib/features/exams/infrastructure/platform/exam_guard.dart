/// Anti-fraud client guard entry point.
///
/// The guard only *observes* the client and reports signals to the backend.
/// It never decides a sanction: `TAB_HIDDEN`, `PAGE_LEAVE`, `APP_BACKGROUND`,
/// `FULLSCREEN_EXIT`, copy/paste and the other signals are scored by
/// `Backend/src/modules/exams/domain/exam-policy.ts`.
library;

export 'exam_guard_native.dart'
    if (dart.library.js_interop) 'exam_guard_web.dart'
    if (dart.library.html) 'exam_guard_web.dart';
export 'exam_guard_types.dart';

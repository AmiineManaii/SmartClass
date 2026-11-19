import 'exam_attempt.dart';
import 'exam_definition.dart';

/// Server-recognized anti-fraud signal types.
enum ExamEventType {
  tabHidden('TAB_HIDDEN', 'exam_event_tab_hidden'),
  focusLost('FOCUS_LOST', 'exam_event_focus_lost'),
  pageLeave('PAGE_LEAVE', 'exam_event_page_leave'),
  pageRefresh('PAGE_REFRESH', 'exam_event_page_refresh'),
  fullscreenExit('FULLSCREEN_EXIT', 'exam_event_fullscreen_exit'),
  appBackground('APP_BACKGROUND', 'exam_event_app_background'),
  copyAttempt('COPY_ATTEMPT', 'exam_event_copy_attempt'),
  pasteAttempt('PASTE_ATTEMPT', 'exam_event_paste_attempt'),
  cutAttempt('CUT_ATTEMPT', 'exam_event_cut_attempt'),
  contextMenu('CONTEXT_MENU', 'exam_event_context_menu'),
  screenshotAttempt('SCREENSHOT_ATTEMPT', 'exam_event_screenshot_attempt'),
  networkLost('NETWORK_LOST', 'exam_event_network_lost'),
  networkRestored('NETWORK_RESTORED', 'exam_event_network_restored'),
  cameraDenied('CAMERA_DENIED', 'exam_event_camera_denied'),
  gazeOffScreen('GAZE_OFF_SCREEN', 'exam_event_gaze_off_screen'),
  technicalInterruption('TECHNICAL_INTERRUPTION', 'exam_event_technical');

  const ExamEventType(this.wire, this.labelKey);

  final String wire;
  final String labelKey;

  static ExamEventType fromWire(String? value) {
    return ExamEventType.values.firstWhere(
      (type) => type.wire == value,
      orElse: () => ExamEventType.technicalInterruption,
    );
  }
}

enum ExamSeverity {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  const ExamSeverity(this.wire);

  final String wire;

  static ExamSeverity fromWire(String? value) {
    return ExamSeverity.values.firstWhere(
      (severity) => severity.wire == value,
      orElse: () => ExamSeverity.low,
    );
  }
}

enum ExamEventState {
  newEvent('NEW'),
  reviewed('REVIEWED'),
  confirmed('CONFIRMED');

  const ExamEventState(this.wire);

  final String wire;

  static ExamEventState fromWire(String? value) {
    return ExamEventState.values.firstWhere(
      (state) => state.wire == value,
      orElse: () => ExamEventState.newEvent,
    );
  }
}

enum ExamDecision {
  none('NONE'),
  warning('WARNING'),
  terminated('TERMINATED');

  const ExamDecision(this.wire);

  final String wire;

  static ExamDecision fromWire(String? value) {
    return ExamDecision.values.firstWhere(
      (decision) => decision.wire == value,
      orElse: () => ExamDecision.none,
    );
  }
}

/// One persisted signal (`ExamEvent`). `decision` is computed by the backend.
class ExamEvent {
  const ExamEvent({
    required this.id,
    required this.attemptId,
    required this.examId,
    required this.studentId,
    required this.type,
    required this.severity,
    required this.state,
    required this.occurredAt,
    required this.source,
    required this.metadata,
    required this.decision,
    required this.createdAt,
    this.durationMs,
  });

  final String id;
  final String attemptId;
  final String examId;
  final String studentId;
  final ExamEventType type;
  final ExamSeverity severity;
  final ExamEventState state;
  final DateTime occurredAt;
  final int? durationMs;
  final String source;
  final Map<String, dynamic> metadata;
  final ExamDecision decision;
  final DateTime createdAt;
}

/// `RecordEventResponse`.
class RecordEventResult {
  const RecordEventResult({
    required this.event,
    required this.attempt,
    required this.decision,
    required this.severity,
    required this.remainingMs,
    required this.serverNow,
  });

  final ExamEvent event;
  final StudentAttempt attempt;
  final ExamDecision decision;
  final ExamSeverity severity;
  final int remainingMs;
  final DateTime serverNow;
}

/// Stored recording metadata (`ExamRecordingView`); never a storage key.
class ExamRecording {
  const ExamRecording({
    required this.id,
    required this.attemptId,
    required this.examId,
    required this.kind,
    required this.mimeType,
    required this.createdAt,
    this.eventId,
    this.sizeBytes,
    this.durationMs,
  });

  final String id;
  final String attemptId;
  final String examId;
  final String? eventId;
  final String kind;
  final String mimeType;
  final int? sizeBytes;
  final int? durationMs;
  final DateTime createdAt;
}

/// Monitored attempt summary inside `AttemptMonitoring`.
class MonitoredAttempt {
  const MonitoredAttempt({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.startedAt,
    required this.expiresAt,
    required this.maxScore,
    required this.violationCount,
    required this.answers,
    this.submittedAt,
    this.score,
    this.terminatedReason,
  });

  final String id;
  final String studentId;
  final String studentName;
  final AttemptStatus status;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime? submittedAt;
  final num? score;
  final num maxScore;
  final int violationCount;
  final String? terminatedReason;
  final List<StudentAnswer> answers;
}

/// `AttemptMonitoring` teacher payload (answers + events + recordings).
class AttemptMonitoring {
  const AttemptMonitoring({
    required this.examId,
    required this.examTitle,
    required this.questionCount,
    required this.attempt,
    required this.events,
    required this.recordings,
    required this.questions,
  });

  final String examId;
  final String examTitle;
  final int questionCount;
  final MonitoredAttempt attempt;
  final List<ExamEvent> events;
  final List<ExamRecording> recordings;

  /// Teacher-only questions with their correction.
  final List<TeacherQuestion> questions;
}

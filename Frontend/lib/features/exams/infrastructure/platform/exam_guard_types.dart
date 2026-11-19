import '../../domain/entities/exam_monitoring.dart';

/// One observation produced locally. `durationMs` is only set when the guard
/// could measure the interruption (tab hidden, app backgrounded, focus lost).
class ExamGuardSignal {
  const ExamGuardSignal({
    required this.type,
    this.durationMs,
    this.metadata = const <String, dynamic>{},
  });

  final ExamEventType type;
  final int? durationMs;
  final Map<String, dynamic> metadata;
}

/// Local observation surface shared by the web and mobile implementations.
abstract class ExamGuard {
  /// Starts observing. `examId` is only used by the web unload beacon.
  Future<void> start({
    required String examId,
    required void Function(ExamGuardSignal signal) onSignal,
  });

  Future<void> stop();

  /// Requests real fullscreen where the platform supports it. Returns
  /// `false` when the platform cannot enter fullscreen (never faked).
  Future<bool> enterFullscreen();
}

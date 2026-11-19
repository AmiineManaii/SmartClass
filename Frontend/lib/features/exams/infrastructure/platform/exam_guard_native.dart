import 'package:flutter/widgets.dart';

import '../../domain/entities/exam_monitoring.dart';
import 'exam_guard_types.dart';

/// Mobile guard: reports real application lifecycle transitions.
///
/// Only `WidgetsBinding` lifecycle callbacks are used. There is no network
/// monitoring here (no connectivity dependency), so network events are not
/// reported on mobile instead of being invented.
class NativeExamGuard with WidgetsBindingObserver implements ExamGuard {
  void Function(ExamGuardSignal signal)? _onSignal;
  DateTime? _backgroundedAt;
  bool _inBackground = false;
  bool _observing = false;

  @override
  Future<void> start({
    required String examId,
    required void Function(ExamGuardSignal signal) onSignal,
  }) async {
    _onSignal = onSignal;
    _backgroundedAt = null;
    _inBackground = false;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
  }

  @override
  Future<void> stop() async {
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    _onSignal = null;
    _backgroundedAt = null;
    _inBackground = false;
  }

  @override
  Future<bool> enterFullscreen() async => false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final callback = _onSignal;
    if (callback == null) return;

    final leftApp =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive;

    if (leftApp && !_inBackground) {
      _inBackground = true;
      _backgroundedAt = DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed && _inBackground) {
      _inBackground = false;
      final startedAt = _backgroundedAt;
      _backgroundedAt = null;
      final durationMs = startedAt == null
          ? null
          : DateTime.now().difference(startedAt).inMilliseconds;
      callback(
        ExamGuardSignal(
          type: ExamEventType.appBackground,
          durationMs: durationMs,
          metadata: const <String, dynamic>{'platform': 'mobile'},
        ),
      );
    }
  }
}

ExamGuard createExamGuard() => NativeExamGuard();

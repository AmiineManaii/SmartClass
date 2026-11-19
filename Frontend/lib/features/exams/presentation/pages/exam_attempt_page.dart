import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/controllers/exam_attempt_controller.dart';
import '../../application/providers/exam_providers.dart';
import '../../domain/entities/exam_attempt.dart';
import '../../domain/entities/exam_monitoring.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../infrastructure/platform/exam_camera.dart';
import '../../infrastructure/platform/exam_guard.dart';
import '../../infrastructure/platform/secure_window.dart';
import '../widgets/exam_attempt_active_view.dart';
import '../widgets/exam_attempt_intro.dart';
import '../widgets/exam_attempt_outcome.dart';
import '../widgets/exam_state_views.dart';
import '../widgets/exam_ui.dart';

/// Student attempt. Every authority is server-side: this page only displays
/// the server clock, autosaves answers, reports observations and asks for
/// submission. It never grades, never decides a sanction and never reveals a
/// correct answer.
class ExamAttemptPage extends ConsumerStatefulWidget {
  const ExamAttemptPage({required this.examId, super.key});

  final String examId;

  @override
  ConsumerState<ExamAttemptPage> createState() => _ExamAttemptPageState();
}

class _ExamAttemptPageState extends ConsumerState<ExamAttemptPage> {
  final ExamGuard _guard = createExamGuard();
  final ExamCameraSession _camera = createExamCameraSession();
  final SecureWindowAdapter _secureWindow = createSecureWindowAdapter();

  bool _introAccepted = false;
  bool _consent = false;
  bool _cameraConsent = false;
  bool _starting = false;
  bool _cameraStarting = false;
  bool _guardsTornDown = false;
  bool _fullscreenUnavailable = false;
  bool _screenCaptured = false;
  ExamCameraStatus? _cameraStatus;
  SecureWindowStatus? _secureStatus;
  int _faceCount = 1;
  bool _gazeOffScreen = false;

  String get _examId => widget.examId;

  String get _source => kIsWeb ? 'web' : 'mobile';

  @override
  void dispose() {
    unawaited(_teardown());
    super.dispose();
  }

  Future<void> _teardown() async {
    if (_guardsTornDown) return;
    _guardsTornDown = true;
    try {
      await _camera.stop();
    } catch (_) {}
    try {
      await _guard.stop();
    } catch (_) {}
    try {
      await _secureWindow.disable();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final attempt = ref.watch(examAttemptControllerProvider(_examId));
    ref.listen(examAttemptControllerProvider(_examId), (previous, next) {
      if (next.isCompleted && previous?.isCompleted != true) {
        unawaited(_teardown());
      }
    });

    if (!_introAccepted) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr('exam_attempt_intro_title')),
        ),
        body: ExamAttemptIntro(
          exam: _availableExam(),
          consent: _consent,
          cameraConsent: _cameraConsent,
          busy: _starting,
          onConsentChanged: (value) => setState(() => _consent = value),
          onCameraConsentChanged: (value) =>
              setState(() => _cameraConsent = value),
          onStart: _start,
        ),
      );
    }

    if (attempt.phase == ExamAttemptPhase.loading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('exam_attempt_title'))),
        body: const Center(child: SmartLoader()),
      );
    }

    if (attempt.phase == ExamAttemptPhase.error) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('exam_attempt_title'))),
        body: ExamErrorView(
          errorKey: attempt.errorKey ?? 'exam_error_start',
          detail: attempt.errorDetail,
          onRetry: () =>
              ref.read(examAttemptControllerProvider(_examId).notifier).load(),
        ),
      );
    }

    if (attempt.isCompleted) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr('exam_attempt_title')),
          automaticallyImplyLeading: false,
        ),
        body: ExamAttemptOutcome(
          terminated: attempt.isTerminated,
          autoSubmitted: attempt.autoSubmitted,
          terminatedReasonKey: terminatedReasonKey(attempt.terminatedReason),
          onViewResult: () =>
              context.pushReplacement('/exams/$_examId/result'),
          onBackToExams: () => context.go('/exams'),
        ),
      );
    }

    if (attempt.session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('exam_attempt_title'))),
        body: ExamErrorView(
          errorKey: 'exam_error_start',
          onRetry: () =>
              ref.read(examAttemptControllerProvider(_examId).notifier).load(),
        ),
      );
    }

    return ExamAttemptActiveView(
      attempt: attempt,
      camera: _camera,
      cameraStatus: _cameraStatus,
      secureStatus: _secureStatus,
      fullscreenUnavailable: _fullscreenUnavailable,
      screenCaptured: _screenCaptured,
      cameraStarting: _cameraStarting,
      faceCount: _faceCount,
      gazeOffScreen: _gazeOffScreen,
      onSelect: (questionId, optionId) => ref
          .read(examAttemptControllerProvider(_examId).notifier)
          .selectOption(questionId, optionId),
      onSubmit: () => _confirmSubmit(context),
      onLeave: () => _confirmLeave(context),
      onRetryCamera: _startCamera,
    );
  }

  AvailableExam? _availableExam() {
    final exams = ref.watch(availableExamsProvider).valueOrNull;
    if (exams == null) return null;
    for (final exam in exams) {
      if (exam.id == _examId) return exam;
    }
    return null;
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      await _guard.start(examId: _examId, onSignal: _handleSignal);
      final fullscreen = await _guard.enterFullscreen();
      _secureStatus = await _secureWindow.enable(
        onCaptureChanged: _handleCaptureChanged,
      );
      if (!mounted) return;
      if (!fullscreen) {
        setState(() => _fullscreenUnavailable = true);
      }
      setState(() => _introAccepted = true);
      final controller = ref.read(
        examAttemptControllerProvider(_examId).notifier,
      );
      await controller.load();
      if (!mounted) return;
      final session = ref.read(examAttemptControllerProvider(_examId)).session;
      final requireCamera = session?.exam.settings.requireCamera ?? false;
      if (requireCamera && _cameraConsent) {
        await _startCamera();
        _camera.setFaceAnalysisListener(_handleFaceAnalysis);
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _startCamera() async {
    if (_cameraStarting) return;
    setState(() => _cameraStarting = true);
    final status = await _camera.start();
    if (!mounted) return;
    setState(() {
      _cameraStatus = status;
      _cameraStarting = false;
    });
    if (status.errorKey == 'exam_camera_permission_denied') {
      await _reportSignal(
        ExamSignalInput(
          type: ExamEventType.cameraDenied,
          source: _source,
          clientOccurredAt: DateTime.now(),
          metadata: const <String, dynamic>{'reason': 'permission_denied'},
        ),
      );
    }
  }

  Future<void> _handleSignal(ExamGuardSignal signal) async {
    if (!mounted) return;
    ExamCameraClip? clip;
    if (_capturesEvidence(signal.type) &&
        (_cameraStatus?.recording ?? false)) {
      clip = await _camera.captureClip();
    }
    if (!mounted) return;
    final result = await _reportSignal(
      ExamSignalInput(
        type: signal.type,
        durationMs: signal.durationMs,
        source: _source,
        clientOccurredAt: DateTime.now(),
        metadata: signal.metadata,
      ),
    );
    if (!mounted || result == null || clip == null) return;
    final extension = clip.mimeType.toLowerCase().contains('mp4')
        ? 'mp4'
        : 'webm';
    try {
      await ref.read(examRepositoryProvider).uploadRecording(
        examId: _examId,
        bytes: clip.bytes,
        filename: 'event-${result.event.id}.$extension',
        mimeType: clip.mimeType,
        eventId: result.event.id,
        durationMs: clip.durationMs,
      );
    } catch (_) {
      // Best effort: the event itself is already persisted by the backend.
    }
  }

  Future<RecordEventResult?> _reportSignal(ExamSignalInput input) {
    return ref
        .read(examAttemptControllerProvider(_examId).notifier)
        .reportSignal(input);
  }

  void _handleCaptureChanged(bool captured) {
    if (!mounted) return;
    setState(() => _screenCaptured = captured);
    if (!captured) return;
    unawaited(
      _reportSignal(
        ExamSignalInput(
          type: ExamEventType.screenshotAttempt,
          source: _source,
          clientOccurredAt: DateTime.now(),
          metadata: const <String, dynamic>{'mechanism': 'screen_capture'},
        ),
      ),
    );
  }

  DateTime? _lastGazeAlert;
  DateTime? _noFaceSince;

  void _handleFaceAnalysis(int faceCount, bool gazeOffScreen) {
    if (!mounted) return;
    setState(() {
      _faceCount = faceCount;
      _gazeOffScreen = gazeOffScreen;
    });
    final now = DateTime.now();

    // 1. Plusieurs visages détectés
    if (faceCount > 1) {
      if (_lastGazeAlert == null || now.difference(_lastGazeAlert!).inSeconds >= 5) {
        _lastGazeAlert = now;
        _handleSignal(
          ExamGuardSignal(
            type: ExamEventType.technicalInterruption,
            metadata: {'reason': 'multiple_faces', 'count': faceCount},
          ),
        );
      }
      return;
    }

    // 2. Aucun visage détecté
    if (faceCount == 0) {
      _noFaceSince ??= now;
      if (now.difference(_noFaceSince!).inSeconds >= 3) {
        if (_lastGazeAlert == null || now.difference(_lastGazeAlert!).inSeconds >= 6) {
          _lastGazeAlert = now;
          _handleSignal(
            ExamGuardSignal(
              type: ExamEventType.cameraDenied,
              metadata: {'reason': 'no_face_detected'},
            ),
          );
        }
      }
      return;
    }
    _noFaceSince = null;

    // 3. Regard détourné
    if (gazeOffScreen) {
      if (_lastGazeAlert == null || now.difference(_lastGazeAlert!).inSeconds >= 6) {
        _lastGazeAlert = now;
        _handleSignal(
          const ExamGuardSignal(
            type: ExamEventType.gazeOffScreen,
            metadata: {'reason': 'gaze_away'},
          ),
        );
      }
    }
  }

  bool _capturesEvidence(ExamEventType type) {
    return type == ExamEventType.tabHidden ||
        type == ExamEventType.appBackground ||
        type == ExamEventType.fullscreenExit ||
        type == ExamEventType.gazeOffScreen;
  }

  Future<void> _confirmSubmit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('exam_attempt_submit_confirm_title')),
        content: Text(context.tr('exam_attempt_submit_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('submit_exam')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(examAttemptControllerProvider(_examId).notifier).submit();
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('exam_attempt_leave_confirm_title')),
        content: Text(
          "Attention : Si vous quittez maintenant, votre tentative sera définitivement clôturée et vos réponses actuelles seront enregistrées comme note finale. Vous ne pourrez plus reprendre cet examen.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Quitter et soumettre"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Fermeture de la caméra et des gardes
    await _teardown();

    // Soumission automatique de la tentative avec les réponses actuelles (ou 0 si rien répondu)
    try {
      await ref.read(examAttemptControllerProvider(_examId).notifier).submit();
    } catch (_) {}

    if (!context.mounted) return;
    context.go('/exams');
  }
}

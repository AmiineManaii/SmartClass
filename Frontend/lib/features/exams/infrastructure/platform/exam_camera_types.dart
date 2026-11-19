import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// What the current build can really do with the camera. `supported` is
/// `false` when no native camera implementation is compiled in; the attempt
/// page then shows an explicit limitation instead of pretending to record.
class ExamCameraStatus {
  const ExamCameraStatus({
    required this.supported,
    required this.active,
    required this.recording,
    this.errorKey,
    this.errorDetail,
  });

  const ExamCameraStatus.unsupported()
    : supported = false,
      active = false,
      recording = false,
      errorKey = 'exam_camera_native_unsupported',
      errorDetail = null;

  final bool supported;
  final bool active;
  final bool recording;
  final String? errorKey;
  final String? errorDetail;
}

/// A short evidence segment captured from the rolling buffer.
class ExamCameraClip {
  const ExamCameraClip({
    required this.bytes,
    required this.mimeType,
    required this.durationMs,
  });

  final Uint8List bytes;
  final String mimeType;
  final int durationMs;
}

/// Camera + rolling recording session used while an attempt is active.
abstract class ExamCameraSession {
  Future<ExamCameraStatus> start();

  /// Live preview built by the platform implementation (empty when the
  /// platform cannot preview).
  Widget buildPreview(BuildContext context);

  /// Captures the last seconds of the rolling buffer. Returns `null` when no
  /// video is available; the UI must not invent a recording.
  Future<ExamCameraClip?> captureClip();

  /// Starts or binds real-time face and gaze fraud analysis.
  void setFaceAnalysisListener(void Function(int faceCount, bool gazeOffScreen)? onAnalysis) {}

  Future<void> stop();
}

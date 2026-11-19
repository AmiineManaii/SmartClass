import 'package:flutter/widgets.dart';

import 'exam_camera_types.dart';

/// No native camera/recording implementation is shipped in this build.
/// `requireCamera` exams still start, but the page displays the limitation
/// and no video is uploaded. This is deliberate: an empty recording must
/// never be presented as proof.
class NativeExamCameraSession implements ExamCameraSession {
  @override
  Future<ExamCameraStatus> start() async =>
      const ExamCameraStatus.unsupported();

  @override
  Widget buildPreview(BuildContext context) => const SizedBox.shrink();

  @override
  Future<ExamCameraClip?> captureClip() async => null;

  @override
  void setFaceAnalysisListener(void Function(int faceCount, bool gazeOffScreen)? onAnalysis) {}

  @override
  Future<void> stop() async {}
}

ExamCameraSession createExamCameraSession() => NativeExamCameraSession();

import 'live_speech_recorder_models.dart';

class LiveSpeechRecorder {
  LiveSpeechRecorder._();
  static final LiveSpeechRecorder instance = LiveSpeechRecorder._();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  String _preferredLanguage = 'auto';
  String get preferredLanguage => _preferredLanguage;

  void setPreferredLanguage(String lang) {
    _preferredLanguage = lang;
  }

  void updateCameraTrack(dynamic track) {}

  void updateScreenShareTrack(dynamic track, [bool isSharing = true]) {}

  Future<void> start({
    String speakerName = 'Enseignant',
    String language = 'auto',
    String? sessionId,
    String? authToken,
    String? backendUrl,
    dynamic initialCameraTrack,
    dynamic initialScreenTrack,
  }) async {
    _isRecording = true;
    _preferredLanguage = language;
  }

  Future<LiveRecordingCaptureResult> stop() async {
    _isRecording = false;
    return LiveRecordingCaptureResult(detectedLanguage: _preferredLanguage);
  }
}

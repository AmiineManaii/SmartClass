class CapturedSpeechSegment {
  final double startSeconds;
  final double endSeconds;
  final String text;
  final String speaker;
  final String language;

  const CapturedSpeechSegment({
    required this.startSeconds,
    required this.endSeconds,
    required this.text,
    this.speaker = 'Enseignant',
    this.language = 'auto',
  });

  Map<String, dynamic> toJson() => {
        'startSeconds': startSeconds,
        'endSeconds': endSeconds,
        'text': text,
        'speaker': speaker,
        'language': language,
      };
}

class LiveRecordingCaptureResult {
  final String spokenTranscript;
  final String detectedLanguage;
  final List<CapturedSpeechSegment> capturedSegments;
  final String? mediaBase64;
  final String? mimeType;

  const LiveRecordingCaptureResult({
    this.spokenTranscript = '',
    this.detectedLanguage = 'auto',
    this.capturedSegments = const [],
    this.mediaBase64,
    this.mimeType,
  });

  Map<String, dynamic> toJson() => {
        if (spokenTranscript.trim().isNotEmpty)
          'spokenTranscript': spokenTranscript.trim(),
        'detectedLanguage': detectedLanguage,
        if (capturedSegments.isNotEmpty)
          'capturedSegments': capturedSegments.map((s) => s.toJson()).toList(),
        if (mediaBase64 != null && mediaBase64!.isNotEmpty)
          'mediaBase64': mediaBase64,
        if (mimeType != null && mimeType!.isNotEmpty) 'mimeType': mimeType,
      };
}


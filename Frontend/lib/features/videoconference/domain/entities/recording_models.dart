import 'package:equatable/equatable.dart';

String formatDurationTimestamp(num seconds) {
  final safe = seconds < 0 ? 0 : seconds.round();
  final hrs = safe ~/ 3600;
  final mins = (safe % 3600) ~/ 60;
  final secs = safe % 60;
  if (hrs > 0) {
    return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

enum RecordingStatus {
  notStarted,
  starting,
  recording,
  finalizing,
  recorded,
  processing,
  readyForReview,
  approved,
  published,
  failed,
  deleted;

  static RecordingStatus fromString(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'STARTING':
        return RecordingStatus.starting;
      case 'RECORDING':
        return RecordingStatus.recording;
      case 'FINALIZING':
        return RecordingStatus.finalizing;
      case 'RECORDED':
      case 'READY':
        return RecordingStatus.recorded;
      case 'PROCESSING':
        return RecordingStatus.processing;
      case 'READY_FOR_REVIEW':
        return RecordingStatus.readyForReview;
      case 'APPROVED':
        return RecordingStatus.approved;
      case 'PUBLISHED':
        return RecordingStatus.published;
      case 'FAILED':
        return RecordingStatus.failed;
      case 'DELETED':
        return RecordingStatus.deleted;
      case 'NOT_STARTED':
      default:
        return RecordingStatus.notStarted;
    }
  }

  bool get isActiveRecording =>
      this == RecordingStatus.starting || this == RecordingStatus.recording;
}

class StageLogItem extends Equatable {
  final String stage;
  final int progress;
  final String message;
  final String at;
  final String? modelUsed;

  const StageLogItem({
    required this.stage,
    required this.progress,
    required this.message,
    required this.at,
    this.modelUsed,
  });

  factory StageLogItem.fromJson(Map<String, dynamic> json) {
    return StageLogItem(
      stage: json['stage'] as String? ?? 'VALIDATION',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
      at: json['at'] as String? ?? '',
      modelUsed: json['modelUsed'] as String?,
    );
  }

  @override
  List<Object?> get props => [stage, progress, message, at, modelUsed];
}

class SessionRecordingEntity extends Equatable {
  final String id;
  final String sessionId;
  final String classGroupId;
  final String? hostId;
  final String status;
  final RecordingStatus recordingStatus;
  final String mimeType;
  final int? sizeBytes;
  final int? durationSeconds;
  final bool hasSourceDocument;
  final String? sourceDocTitle;
  final String? errorMessage;
  final DateTime? startedAt;
  final DateTime? stoppedAt;
  final DateTime? publishedAt;
  final String streamUrl;
  final String posterUrl;
  final String subtitlesVttUrl;
  final String subtitlesSrtUrl;
  final List<StageLogItem> stageLogs;

  const SessionRecordingEntity({
    required this.id,
    required this.sessionId,
    this.classGroupId = '',
    this.hostId,
    required this.status,
    required this.recordingStatus,
    this.mimeType = 'video/mp4',
    this.sizeBytes,
    this.durationSeconds,
    this.hasSourceDocument = false,
    this.sourceDocTitle,
    this.errorMessage,
    this.startedAt,
    this.stoppedAt,
    this.publishedAt,
    this.streamUrl = '',
    this.posterUrl = '',
    this.subtitlesVttUrl = '',
    this.subtitlesSrtUrl = '',
    this.stageLogs = const [],
  });

  bool get isReady =>
      status == 'READY' ||
      status == 'RECORDED' ||
      status == 'READY_FOR_REVIEW' ||
      status == 'APPROVED' ||
      status == 'PUBLISHED';

  factory SessionRecordingEntity.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'NOT_STARTED';
    final job = json['latestJob'] as Map<String, dynamic>?;
    final rawLogs = job?['stageLogs'] as List<dynamic>? ?? const [];
    return SessionRecordingEntity(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      classGroupId: json['classGroupId'] as String? ?? '',
      hostId: json['hostId'] as String?,
      status: rawStatus,
      recordingStatus: RecordingStatus.fromString(rawStatus),
      mimeType: json['mimeType'] as String? ?? 'video/mp4',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      hasSourceDocument: json['hasSourceDocument'] as bool? ?? false,
      sourceDocTitle: json['sourceDocTitle'] as String?,
      errorMessage: json['errorMessage'] as String?,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
      stoppedAt: json['stoppedAt'] != null
          ? DateTime.tryParse(json['stoppedAt'].toString())
          : null,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      streamUrl: json['streamUrl'] as String? ?? '',
      posterUrl: json['posterUrl'] as String? ?? '',
      subtitlesVttUrl: json['subtitlesVttUrl'] as String? ?? '',
      subtitlesSrtUrl: json['subtitlesSrtUrl'] as String? ?? '',
      stageLogs: rawLogs
          .whereType<Map<String, dynamic>>()
          .map(StageLogItem.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, sessionId, status, durationSeconds, streamUrl];
}

typedef RecordingOverview = SessionRecordingEntity;

class TranscriptSegmentEntity extends Equatable {
  final String id;
  final int index;
  final double startSec;
  final double endSec;
  final String text;
  final String? speaker;

  const TranscriptSegmentEntity({
    this.id = '',
    required this.index,
    required this.startSec,
    required this.endSec,
    required this.text,
    this.speaker,
  });

  String get formattedTime => formatDurationTimestamp(startSec);

  factory TranscriptSegmentEntity.fromJson(Map<String, dynamic> json) {
    return TranscriptSegmentEntity(
      id: json['id'] as String? ?? '',
      index: (json['index'] ?? json['orderIndex'] as num?)?.toInt() ?? 0,
      startSec:
          (json['startSec'] ?? json['startSeconds'] as num?)?.toDouble() ?? 0.0,
      endSec: (json['endSec'] ?? json['endSeconds'] as num?)?.toDouble() ?? 0.0,
      text: json['text'] as String? ?? '',
      speaker: json['speaker'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'index': index,
        'orderIndex': index,
        'startSec': startSec,
        'startSeconds': startSec,
        'endSec': endSec,
        'endSeconds': endSec,
        'text': text,
        if (speaker != null) 'speaker': speaker,
      };

  TranscriptSegmentEntity copyWith({
    String? text,
    double? startSec,
    double? endSec,
    String? speaker,
  }) {
    return TranscriptSegmentEntity(
      id: id,
      index: index,
      startSec: startSec ?? this.startSec,
      endSec: endSec ?? this.endSec,
      text: text ?? this.text,
      speaker: speaker ?? this.speaker,
    );
  }

  @override
  List<Object?> get props => [id, index, startSec, endSec, text, speaker];
}

typedef TranscriptSegmentItem = TranscriptSegmentEntity;

class RecordingTranscriptEntity extends Equatable {
  final String id;
  final String language;
  final String fullText;
  final List<TranscriptSegmentEntity> segments;
  final String? vttSubtitles;
  final int wordCount;

  const RecordingTranscriptEntity({
    required this.id,
    required this.language,
    required this.fullText,
    required this.segments,
    this.vttSubtitles,
    this.wordCount = 0,
  });

  factory RecordingTranscriptEntity.fromJson(Map<String, dynamic> json) {
    final segs = (json['segments'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TranscriptSegmentEntity.fromJson)
        .toList();
    final full = json['fullText'] as String? ?? '';
    return RecordingTranscriptEntity(
      id: json['id'] as String? ?? '',
      language: json['language'] as String? ?? 'fr',
      fullText: full,
      segments: segs,
      vttSubtitles:
          (json['vttSubtitles'] ?? json['vttContent']) as String?,
      wordCount: (json['wordCount'] as num?)?.toInt() ??
          (full.isEmpty ? 0 : full.split(RegExp(r'\s+')).length),
    );
  }

  @override
  List<Object?> get props => [id, language, fullText, segments, wordCount];
}

typedef RecordingTranscriptData = RecordingTranscriptEntity;

class SlideSegmentEntity extends Equatable {
  final String id;
  final int slideIndex;
  final double timestampSec;
  final double endTimestampSec;
  final String extractedText;
  final String visualExplanation;
  final int? sourcePage;

  const SlideSegmentEntity({
    this.id = '',
    required this.slideIndex,
    required this.timestampSec,
    required this.endTimestampSec,
    required this.extractedText,
    required this.visualExplanation,
    this.sourcePage,
  });

  factory SlideSegmentEntity.fromJson(Map<String, dynamic> json) {
    final ts =
        (json['timestampSec'] ?? json['timestampSeconds'] as num?)?.toDouble() ??
            0.0;
    final endTs =
        (json['endTimestampSec'] as num?)?.toDouble() ?? (ts + 60.0);
    return SlideSegmentEntity(
      id: json['id'] as String? ?? '',
      slideIndex: (json['slideIndex'] as num?)?.toInt() ?? 0,
      timestampSec: ts,
      endTimestampSec: endTs,
      extractedText:
          (json['extractedText'] ?? json['ocrText']) as String? ?? '',
      visualExplanation:
          (json['visualExplanation'] ?? json['visualSummary']) as String? ?? '',
      sourcePage: (json['sourcePage'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        slideIndex,
        timestampSec,
        endTimestampSec,
        extractedText,
        visualExplanation,
      ];
}

typedef SlideFrameItem = SlideSegmentEntity;

class LessonChapterEntity extends Equatable {
  final String id;
  final int chapterIndex;
  final String title;
  final String summary;
  final double startSec;
  final double endSec;
  final List<String> keyConcepts;
  final int? sourcePage;

  const LessonChapterEntity({
    required this.id,
    required this.chapterIndex,
    required this.title,
    required this.summary,
    required this.startSec,
    required this.endSec,
    this.keyConcepts = const [],
    this.sourcePage,
  });

  String get formattedRange =>
      '${formatDurationTimestamp(startSec)} - ${formatDurationTimestamp(endSec)}';

  factory LessonChapterEntity.fromJson(Map<String, dynamic> json) {
    return LessonChapterEntity(
      id: json['id'] as String? ?? '',
      chapterIndex:
          (json['chapterIndex'] ?? json['orderIndex'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      startSec:
          (json['startSec'] ?? json['startSeconds'] as num?)?.toDouble() ?? 0.0,
      endSec:
          (json['endSec'] ?? json['endSeconds'] as num?)?.toDouble() ?? 0.0,
      keyConcepts: (json['keyConcepts'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      sourcePage: (json['sourcePage'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterIndex': chapterIndex,
        'orderIndex': chapterIndex,
        'title': title,
        'summary': summary,
        'startSec': startSec,
        'startSeconds': startSec.round(),
        'endSec': endSec,
        'endSeconds': endSec.round(),
        'keyConcepts': keyConcepts,
        if (sourcePage != null) 'sourcePage': sourcePage,
      };

  @override
  List<Object?> get props =>
      [id, chapterIndex, title, summary, startSec, endSec, keyConcepts];
}

typedef RecordingChapterItem = LessonChapterEntity;

class LessonGlossaryItemEntity extends Equatable {
  final String term;
  final String definition;
  final String? chapterTitle;

  const LessonGlossaryItemEntity({
    required this.term,
    required this.definition,
    this.chapterTitle,
  });

  factory LessonGlossaryItemEntity.fromJson(Map<String, dynamic> json) {
    return LessonGlossaryItemEntity(
      term: (json['term'] ?? json['name']) as String? ?? '',
      definition: (json['definition'] ?? json['explanation']) as String? ?? '',
      chapterTitle: json['chapterTitle'] as String?,
    );
  }

  @override
  List<Object?> get props => [term, definition, chapterTitle];
}

class LessonQuizQuestionEntity extends Equatable {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? chapterTitle;

  const LessonQuizQuestionEntity({
    this.id = '',
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.chapterTitle,
  });

  factory LessonQuizQuestionEntity.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    int resolvedIdx = (json['correctIndex'] as num?)?.toInt() ?? 0;
    if (json['correctIndex'] == null && json['correctAnswer'] is String) {
      final ans = json['correctAnswer'] as String;
      final found = opts.indexOf(ans);
      if (found >= 0) resolvedIdx = found;
    }
    return LessonQuizQuestionEntity(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: opts,
      correctIndex: resolvedIdx,
      explanation: json['explanation'] as String? ?? '',
      chapterTitle: json['chapterTitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        if (chapterTitle != null) 'chapterTitle': chapterTitle,
      };

  @override
  List<Object?> get props =>
      [id, question, options, correctIndex, explanation, chapterTitle];
}

typedef LessonQuizQuestionItem = LessonQuizQuestionEntity;

class LessonFlashcardEntity extends Equatable {
  final String id;
  final String front;
  final String back;
  final String? chapterTitle;
  final String difficulty;

  const LessonFlashcardEntity({
    this.id = '',
    required this.front,
    required this.back,
    this.chapterTitle,
    this.difficulty = 'medium',
  });

  factory LessonFlashcardEntity.fromJson(Map<String, dynamic> json) {
    return LessonFlashcardEntity(
      id: json['id'] as String? ?? '',
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      chapterTitle: json['chapterTitle'] as String?,
      difficulty: json['difficulty'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'front': front,
        'back': back,
        if (chapterTitle != null) 'chapterTitle': chapterTitle,
        'difficulty': difficulty,
      };

  @override
  List<Object?> get props => [id, front, back, chapterTitle, difficulty];
}

typedef LessonFlashcardItem = LessonFlashcardEntity;

class LessonPackageEntity extends Equatable {
  final String id;
  final String sessionId;
  final String status;
  final String title;
  final String shortSummary;
  final String detailedSummary;
  final List<String> keyTakeaways;
  final String structuredMarkdown;
  final String? mindMapMermaid;
  final List<LessonGlossaryItemEntity> glossary;
  final List<LessonChapterEntity> chapters;
  final List<LessonQuizQuestionEntity> quizQuestions;
  final List<LessonFlashcardEntity> flashcards;
  final double? qualityScore;
  final int currentVersion;

  const LessonPackageEntity({
    required this.id,
    this.sessionId = '',
    this.status = 'READY_FOR_REVIEW',
    required this.title,
    required this.shortSummary,
    required this.detailedSummary,
    this.keyTakeaways = const [],
    required this.structuredMarkdown,
    this.mindMapMermaid,
    this.glossary = const [],
    this.chapters = const [],
    this.quizQuestions = const [],
    this.flashcards = const [],
    this.qualityScore,
    this.currentVersion = 1,
  });

  bool get isReadyForReview => status == 'READY_FOR_REVIEW';
  bool get isApproved => status == 'APPROVED';
  bool get isPublished => status == 'PUBLISHED';

  factory LessonPackageEntity.fromJson(
    Map<String, dynamic> json, {
    List<LessonChapterEntity>? fallbackChapters,
    String? fallbackTitle,
    String? fallbackStatus,
  }) {
    final rawGlossary = (json['glossary'] ??
            json['definitions'] ??
            json['keyConcepts'] ??
            const []) as List<dynamic>;
    final rawChapters = (json['chapters'] as List<dynamic>?);
    final rawQuizzes =
        (json['quizQuestions'] ?? json['quizzes'] ?? const []) as List<dynamic>;
    final rawCards = (json['flashcards'] as List<dynamic>? ?? const []);
    final rawTakeaways = (json['keyTakeaways'] ??
        json['learningObjectives'] ??
        const []) as List<dynamic>;

    double? parsedQuality;
    if (json['qualityScore'] is num) {
      final v = (json['qualityScore'] as num).toDouble();
      parsedQuality = v > 1.0 ? v / 100.0 : v;
    } else if (json['qualityReport'] is Map<String, dynamic>) {
      final sc = (json['qualityReport'] as Map<String, dynamic>)['score'];
      if (sc is num) {
        parsedQuality = sc.toDouble() > 1.0 ? sc.toDouble() / 100.0 : sc.toDouble();
      }
    }

    return LessonPackageEntity(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      status: json['status'] as String? ?? fallbackStatus ?? 'READY_FOR_REVIEW',
      title: json['title'] as String? ?? fallbackTitle ?? 'Cours IA',
      shortSummary:
          (json['shortSummary'] ?? json['generalSummary']) as String? ?? '',
      detailedSummary:
          (json['detailedSummary'] ?? json['generalSummary']) as String? ?? '',
      keyTakeaways: rawTakeaways.map((e) => e.toString()).toList(),
      structuredMarkdown:
          (json['structuredMarkdown'] ?? json['structuredNotes']) as String? ??
              '',
      mindMapMermaid: json['mindMapMermaid'] as String?,
      glossary: rawGlossary
          .whereType<Map<String, dynamic>>()
          .map(LessonGlossaryItemEntity.fromJson)
          .toList(),
      chapters: rawChapters != null
          ? rawChapters
              .whereType<Map<String, dynamic>>()
              .map(LessonChapterEntity.fromJson)
              .toList()
          : (fallbackChapters ?? const []),
      quizQuestions: rawQuizzes
          .whereType<Map<String, dynamic>>()
          .map(LessonQuizQuestionEntity.fromJson)
          .toList(),
      flashcards: rawCards
          .whereType<Map<String, dynamic>>()
          .map(LessonFlashcardEntity.fromJson)
          .toList(),
      qualityScore: parsedQuality,
      currentVersion:
          (json['currentVersion'] ?? json['version'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        title,
        shortSummary,
        structuredMarkdown,
        currentVersion,
        chapters,
        quizQuestions,
        flashcards,
      ];
}

typedef LessonPackageData = LessonPackageEntity;

class LessonPackageVersionEntity extends Equatable {
  final String id;
  final int versionNumber;
  final String? changeSummary;
  final String createdAt;

  const LessonPackageVersionEntity({
    required this.id,
    required this.versionNumber,
    this.changeSummary,
    required this.createdAt,
  });

  factory LessonPackageVersionEntity.fromJson(Map<String, dynamic> json) {
    return LessonPackageVersionEntity(
      id: json['id'] as String? ?? '',
      versionNumber:
          (json['versionNumber'] ?? json['version'] as num?)?.toInt() ?? 1,
      changeSummary: json['changeSummary'] as String?,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, versionNumber, changeSummary, createdAt];
}

class MediaProcessingJobEntity extends Equatable {
  final String id;
  final String jobType;
  final String stage;
  final String status;
  final int progressPercent;

  const MediaProcessingJobEntity({
    required this.id,
    required this.jobType,
    required this.stage,
    required this.status,
    required this.progressPercent,
  });

  factory MediaProcessingJobEntity.fromJson(Map<String, dynamic> json) {
    return MediaProcessingJobEntity(
      id: json['id'] as String? ?? '',
      jobType: json['jobType'] as String? ?? 'PIPELINE',
      stage: json['stage'] as String? ?? 'VALIDATION',
      status: json['status'] as String? ?? 'COMPLETED',
      progressPercent:
          (json['progressPercent'] ?? json['progress'] as num?)?.toInt() ?? 100,
    );
  }

  @override
  List<Object?> get props => [id, jobType, stage, status, progressPercent];
}

class TeacherReviewWorkspaceEntity extends Equatable {
  final String sessionId;
  final String sessionTitle;
  final String? sessionSubject;
  final SessionRecordingEntity? recording;
  final RecordingTranscriptEntity? transcript;
  final LessonPackageEntity? lessonPackage;
  final List<SlideSegmentEntity> slides;
  final List<MediaProcessingJobEntity> jobs;
  final List<LessonPackageVersionEntity> versions;

  const TeacherReviewWorkspaceEntity({
    required this.sessionId,
    required this.sessionTitle,
    this.sessionSubject,
    this.recording,
    this.transcript,
    this.lessonPackage,
    this.slides = const [],
    this.jobs = const [],
    this.versions = const [],
  });

  factory TeacherReviewWorkspaceEntity.fromJson(Map<String, dynamic> json) {
    final recJson = json['recording'] as Map<String, dynamic>?;
    final rec =
        recJson != null ? SessionRecordingEntity.fromJson(recJson) : null;
    final topChapters = (json['chapters'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LessonChapterEntity.fromJson)
        .toList();
    final rawSlides =
        (json['slides'] ?? json['slideFrames'] ?? const []) as List<dynamic>;
    final rawJobs = (json['jobs'] as List<dynamic>? ?? const []);
    final pkgJson = json['lessonPackage'] as Map<String, dynamic>?;

    return TeacherReviewWorkspaceEntity(
      sessionId: json['sessionId'] as String? ?? rec?.sessionId ?? '',
      sessionTitle: json['sessionTitle'] as String? ?? 'Séance enregistrée',
      sessionSubject: json['sessionSubject'] as String?,
      recording: rec,
      transcript: json['transcript'] is Map<String, dynamic>
          ? RecordingTranscriptEntity.fromJson(
              json['transcript'] as Map<String, dynamic>,
            )
          : null,
      lessonPackage: pkgJson != null
          ? LessonPackageEntity.fromJson(
              pkgJson,
              fallbackChapters: topChapters,
              fallbackTitle: json['sessionTitle'] as String?,
              fallbackStatus: rec?.status,
            )
          : null,
      slides: rawSlides
          .whereType<Map<String, dynamic>>()
          .map(SlideSegmentEntity.fromJson)
          .toList(),
      jobs: rawJobs
          .whereType<Map<String, dynamic>>()
          .map(MediaProcessingJobEntity.fromJson)
          .toList(),
      versions: (json['versions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LessonPackageVersionEntity.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props =>
      [sessionId, sessionTitle, recording, transcript, lessonPackage, versions];
}

typedef TeacherReviewWorkspace = TeacherReviewWorkspaceEntity;

class StudentBookmarkEntity extends Equatable {
  final String id;
  final double timestampSec;
  final String label;
  final String? chapterTitle;

  const StudentBookmarkEntity({
    required this.id,
    required this.timestampSec,
    required this.label,
    this.chapterTitle,
  });

  String get formattedTime => formatDurationTimestamp(timestampSec);

  factory StudentBookmarkEntity.fromJson(Map<String, dynamic> json) {
    return StudentBookmarkEntity(
      id: json['id'] as String? ?? '',
      timestampSec: (json['timestampSec'] ?? json['timestampSeconds'] as num?)
              ?.toDouble() ??
          0.0,
      label: json['label'] as String? ?? '',
      chapterTitle: json['chapterTitle'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, timestampSec, label, chapterTitle];
}

typedef StudentBookmarkItem = StudentBookmarkEntity;

class StudentNoteEntity extends Equatable {
  final String id;
  final double? timestampSec;
  final String content;
  final String? highlightText;
  final String? chapterTitle;

  const StudentNoteEntity({
    required this.id,
    this.timestampSec,
    required this.content,
    this.highlightText,
    this.chapterTitle,
  });

  factory StudentNoteEntity.fromJson(Map<String, dynamic> json) {
    return StudentNoteEntity(
      id: json['id'] as String? ?? '',
      timestampSec: (json['timestampSec'] ?? json['timestampSeconds'] as num?)
          ?.toDouble(),
      content: json['content'] as String? ?? '',
      highlightText: json['highlightText'] as String?,
      chapterTitle: json['chapterTitle'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, timestampSec, content, highlightText];
}

typedef StudentNoteItem = StudentNoteEntity;

class StudentStudyArtifactEntity extends Equatable {
  final String id;
  final String artifactType;
  final String title;
  final Map<String, dynamic> contentJson;
  final String? modelUsed;

  const StudentStudyArtifactEntity({
    required this.id,
    required this.artifactType,
    required this.title,
    required this.contentJson,
    this.modelUsed,
  });

  factory StudentStudyArtifactEntity.fromJson(Map<String, dynamic> json) {
    return StudentStudyArtifactEntity(
      id: json['id'] as String? ?? '',
      artifactType:
          (json['artifactType'] ?? json['kind']) as String? ?? 'SUMMARY',
      title: json['title'] as String? ?? 'Ressource IA',
      contentJson: (json['contentJson'] ?? json['content'])
              as Map<String, dynamic>? ??
          const {},
      modelUsed: json['modelUsed'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, artifactType, title, contentJson];
}

typedef StudentStudyArtifactItem = StudentStudyArtifactEntity;

class StudentQuizAttemptEntity extends Equatable {
  final String id;
  final double score;
  final int correctCount;
  final int totalQuestions;
  final List<String> weakTopics;

  const StudentQuizAttemptEntity({
    required this.id,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    this.weakTopics = const [],
  });

  factory StudentQuizAttemptEntity.fromJson(Map<String, dynamic> json) {
    final total = (json['totalQuestions'] as num?)?.toInt() ?? 1;
    final rawScore = (json['score'] as num?)?.toDouble() ?? 0.0;
    final correct = (json['correctCount'] as num?)?.toInt() ??
        ((rawScore <= total) ? rawScore.round() : ((rawScore / 100.0) * total).round());
    final pctScore =
        rawScore <= total && total > 0 ? (rawScore / total) * 100.0 : rawScore;
    return StudentQuizAttemptEntity(
      id: json['id'] as String? ?? '',
      score: pctScore,
      correctCount: correct,
      totalQuestions: total,
      weakTopics: (json['weakTopics'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  @override
  List<Object?> get props =>
      [id, score, correctCount, totalQuestions, weakTopics];
}

typedef StudentQuizAttemptItem = StudentQuizAttemptEntity;

class LessonTutorCitationEntity extends Equatable {
  final String type;
  final String label;
  final String excerpt;
  final double? timestampSec;
  final String? chapterTitle;
  final int? slideNumber;

  const LessonTutorCitationEntity({
    required this.type,
    required this.label,
    this.excerpt = '',
    this.timestampSec,
    this.chapterTitle,
    this.slideNumber,
  });

  String get formattedTime => timestampSec != null
      ? '[${formatDurationTimestamp(timestampSec!)}]'
      : '[Cours]';

  factory LessonTutorCitationEntity.fromJson(Map<String, dynamic> json) {
    return LessonTutorCitationEntity(
      type: json['type'] as String? ?? 'transcript',
      label: json['label'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      timestampSec: (json['timestampSec'] ?? json['timestampSeconds'] as num?)
          ?.toDouble(),
      chapterTitle: json['chapterTitle'] as String?,
      slideNumber: (json['slideNumber'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [type, label, timestampSec, chapterTitle];
}

typedef TutorCitationItem = LessonTutorCitationEntity;

class LessonTutorMessageEntity extends Equatable {
  final String id;
  final String role;
  final String content;
  final List<LessonTutorCitationEntity> citations;
  final String createdAt;

  const LessonTutorMessageEntity({
    required this.id,
    required this.role,
    required this.content,
    this.citations = const [],
    this.createdAt = '',
  });

  factory LessonTutorMessageEntity.fromJson(Map<String, dynamic> json) {
    return LessonTutorMessageEntity(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
      citations: (json['citations'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LessonTutorCitationEntity.fromJson)
          .toList(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, role, content, citations, createdAt];
}

typedef TutorMessageItem = LessonTutorMessageEntity;

class LessonSearchHitEntity extends Equatable {
  final String id;
  final String sourceType;
  final String title;
  final String snippet;
  final double? timestampSec;
  final String formattedTimestamp;

  const LessonSearchHitEntity({
    required this.id,
    required this.sourceType,
    required this.title,
    required this.snippet,
    this.timestampSec,
    this.formattedTimestamp = '00:00',
  });

  factory LessonSearchHitEntity.fromJson(Map<String, dynamic> json) {
    final ts =
        (json['timestampSec'] ?? json['timestampSeconds'] as num?)?.toDouble();
    return LessonSearchHitEntity(
      id: json['id'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? 'TRANSCRIPT',
      title: json['title'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
      timestampSec: ts,
      formattedTimestamp: json['formattedTimestamp'] as String? ??
          (ts != null ? formatDurationTimestamp(ts) : '00:00'),
    );
  }

  @override
  List<Object?> get props => [id, sourceType, title, timestampSec];
}

typedef LessonSearchHitItem = LessonSearchHitEntity;

class StudentLessonWorkspaceEntity extends Equatable {
  final String sessionId;
  final String sessionTitle;
  final String? sessionSubject;
  final SessionRecordingEntity? recording;
  final RecordingTranscriptEntity? transcript;
  final LessonPackageEntity lessonPackage;
  final List<SlideSegmentEntity> slides;
  final List<StudentBookmarkEntity> bookmarks;
  final List<StudentNoteEntity> notes;
  final List<StudentStudyArtifactEntity> studyArtifacts;
  final List<StudentQuizAttemptEntity> quizAttempts;
  final List<LessonTutorMessageEntity> tutorHistory;

  const StudentLessonWorkspaceEntity({
    required this.sessionId,
    required this.sessionTitle,
    this.sessionSubject,
    this.recording,
    this.transcript,
    required this.lessonPackage,
    this.slides = const [],
    this.bookmarks = const [],
    this.notes = const [],
    this.studyArtifacts = const [],
    this.quizAttempts = const [],
    this.tutorHistory = const [],
  });

  factory StudentLessonWorkspaceEntity.fromJson(Map<String, dynamic> json) {
    final recJson = json['recording'] as Map<String, dynamic>?;
    final rec =
        recJson != null ? SessionRecordingEntity.fromJson(recJson) : null;
    final topChapters = (json['chapters'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LessonChapterEntity.fromJson)
        .toList();
    final pkgJson = json['lessonPackage'] as Map<String, dynamic>? ?? const {};
    final rawSlides =
        (json['slides'] ?? json['slideFrames'] ?? const []) as List<dynamic>;

    final convs = (json['tutorConversations'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final rawMsgs = json['tutorHistory'] as List<dynamic>? ??
        (convs.isNotEmpty
            ? (convs.first['messages'] as List<dynamic>? ?? const [])
            : const []);

    return StudentLessonWorkspaceEntity(
      sessionId: json['sessionId'] as String? ?? rec?.sessionId ?? '',
      sessionTitle: json['sessionTitle'] as String? ?? 'Cours enregistré',
      sessionSubject: json['sessionSubject'] as String?,
      recording: rec,
      transcript: json['transcript'] is Map<String, dynamic>
          ? RecordingTranscriptEntity.fromJson(
              json['transcript'] as Map<String, dynamic>,
            )
          : null,
      lessonPackage: LessonPackageEntity.fromJson(
        pkgJson,
        fallbackChapters: topChapters,
        fallbackTitle: json['sessionTitle'] as String?,
        fallbackStatus: rec?.status,
      ),
      slides: rawSlides
          .whereType<Map<String, dynamic>>()
          .map(SlideSegmentEntity.fromJson)
          .toList(),
      bookmarks: (json['bookmarks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StudentBookmarkEntity.fromJson)
          .toList(),
      notes: (json['notes'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StudentNoteEntity.fromJson)
          .toList(),
      studyArtifacts: (json['studyArtifacts'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StudentStudyArtifactEntity.fromJson)
          .toList(),
      quizAttempts: (json['quizAttempts'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StudentQuizAttemptEntity.fromJson)
          .toList(),
      tutorHistory: rawMsgs
          .whereType<Map<String, dynamic>>()
          .map(LessonTutorMessageEntity.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        sessionTitle,
        recording,
        lessonPackage,
        bookmarks,
        notes,
        studyArtifacts,
        quizAttempts,
        tutorHistory,
      ];
}

typedef StudentLessonWorkspace = StudentLessonWorkspaceEntity;

/// Student study material generated from one published course
/// (`contracts/courses.openapi.yaml`: `/courses/{id}/study`).
///
/// Everything here is derived from the teacher's validated course: the
/// backend refuses off-course tutor questions, so `inScope: false` marks a
/// deterministic refusal rather than a model answer.
library;

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList();
}

String? _asNullableString(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value : null;

DateTime? _asDate(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

/// One citable chapter of the course (`p-1`, `p-2`, …).
class CourseStudyChapter {
  const CourseStudyChapter({required this.id, required this.title});

  final String id;
  final String title;

  factory CourseStudyChapter.fromJson(Map<String, dynamic> json) {
    return CourseStudyChapter(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
    );
  }
}

class CourseSummaryExcerpt {
  const CourseSummaryExcerpt({required this.title, required this.excerpt});

  final String title;
  final String excerpt;

  factory CourseSummaryExcerpt.fromJson(Map<String, dynamic> json) {
    return CourseSummaryExcerpt(
      title: (json['title'] as String?) ?? '',
      excerpt: (json['excerpt'] as String?) ?? '',
    );
  }
}

/// Payload of a `SUMMARY` artifact.
class CourseSummaryContent {
  const CourseSummaryContent({
    required this.mode,
    required this.markdown,
    this.keyTakeaways = const [],
    this.sections = const [],
  });

  final String mode;
  final String markdown;
  final List<String> keyTakeaways;
  final List<CourseSummaryExcerpt> sections;

  factory CourseSummaryContent.fromJson(Map<String, dynamic> json) {
    return CourseSummaryContent(
      mode: (json['mode'] as String?) ?? 'medium',
      markdown: (json['markdown'] as String?) ?? '',
      keyTakeaways: (json['keyTakeaways'] is List)
          ? (json['keyTakeaways'] as List).whereType<String>().toList()
          : const [],
      sections: _asMapList(
        json['sections'],
      ).map(CourseSummaryExcerpt.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'markdown': markdown,
    'keyTakeaways': keyTakeaways,
    'sections': sections
        .map((s) => {'title': s.title, 'excerpt': s.excerpt})
        .toList(),
  };
}

class CourseFlashcard {
  const CourseFlashcard({
    required this.id,
    required this.front,
    required this.back,
    this.sectionTitle,
  });

  final String id;
  final String front;
  final String back;
  final String? sectionTitle;

  factory CourseFlashcard.fromJson(Map<String, dynamic> json) {
    return CourseFlashcard(
      id: (json['id'] as String?) ?? '',
      front: (json['front'] as String?) ?? '',
      back: (json['back'] as String?) ?? '',
      sectionTitle: _asNullableString(json['sectionTitle']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'front': front,
    'back': back,
    if (sectionTitle != null) 'sectionTitle': sectionTitle,
  };
}

/// Payload of a `FLASHCARDS` artifact.
class CourseFlashcardsContent {
  const CourseFlashcardsContent({required this.focus, required this.cards});

  final String focus;
  final List<CourseFlashcard> cards;

  factory CourseFlashcardsContent.fromJson(Map<String, dynamic> json) {
    final raw = json['cards'] ?? json['flashcards'];
    return CourseFlashcardsContent(
      focus: (json['focus'] as String?) ?? 'all',
      cards: _asMapList(raw).map(CourseFlashcard.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'focus': focus,
    'cards': cards.map((c) => c.toJson()).toList(),
  };
}

/// One persisted summary or flashcard deck, private to its author.
class CourseStudyArtifact {
  const CourseStudyArtifact({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.kind,
    required this.title,
    required this.language,
    required this.rawContent,
    this.modelUsed,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String courseId;
  final String userId;

  /// `SUMMARY` | `FLASHCARDS`.
  final String kind;
  final String title;
  final String language;
  final Map<String, dynamic> rawContent;
  final String? modelUsed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isSummary => kind == 'SUMMARY';
  bool get isFlashcards => kind == 'FLASHCARDS';
  bool get usedFallback => modelUsed == 'extractive-fallback';

  CourseSummaryContent get summary => CourseSummaryContent.fromJson(rawContent);
  CourseFlashcardsContent get flashcards =>
      CourseFlashcardsContent.fromJson(rawContent);

  factory CourseStudyArtifact.fromJson(Map<String, dynamic> json) {
    return CourseStudyArtifact(
      id: (json['id'] as String?) ?? '',
      courseId: (json['courseId'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? 'SUMMARY',
      title: (json['title'] as String?) ?? '',
      language: (json['language'] as String?) ?? 'fr',
      rawContent: _asMap(json['content']),
      modelUsed: _asNullableString(json['modelUsed']),
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
    );
  }
}

/// Source excerpt backing one tutor answer (never invented by the model).
class CourseTutorCitation {
  const CourseTutorCitation({
    required this.passageId,
    required this.sectionTitle,
    required this.excerpt,
    required this.score,
  });

  final String passageId;
  final String sectionTitle;
  final String excerpt;
  final double score;

  factory CourseTutorCitation.fromJson(Map<String, dynamic> json) {
    return CourseTutorCitation(
      passageId: (json['passageId'] as String?) ?? '',
      sectionTitle: (json['sectionTitle'] as String?) ?? '',
      excerpt: (json['excerpt'] as String?) ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CourseTutorMessage {
  const CourseTutorMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.citations = const [],
    this.inScope = true,
    this.modelUsed,
    this.createdAt,
  });

  final String id;
  final String conversationId;

  /// `user` | `assistant`.
  final String role;
  final String content;
  final List<CourseTutorCitation> citations;

  /// False when the question was outside the course and refused.
  final bool inScope;
  final String? modelUsed;
  final DateTime? createdAt;

  bool get isUser => role == 'user';

  factory CourseTutorMessage.fromJson(Map<String, dynamic> json) {
    return CourseTutorMessage(
      id: (json['id'] as String?) ?? '',
      conversationId: (json['conversationId'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'assistant',
      content: (json['content'] as String?) ?? '',
      citations: _asMapList(
        json['citations'],
      ).map(CourseTutorCitation.fromJson).toList(),
      inScope: json['inScope'] is bool ? json['inScope'] as bool : true,
      modelUsed: _asNullableString(json['modelUsed']),
      createdAt: _asDate(json['createdAt']),
    );
  }
}

class CourseTutorConversation {
  const CourseTutorConversation({
    required this.id,
    required this.title,
    this.messages = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final List<CourseTutorMessage> messages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CourseTutorConversation.fromJson(Map<String, dynamic> json) {
    return CourseTutorConversation(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      messages: _asMapList(
        json['messages'],
      ).map(CourseTutorMessage.fromJson).toList(),
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
    );
  }
}

/// The single exchange persisted by `POST /courses/{id}/tutor/ask`.
class CourseTutorExchange {
  const CourseTutorExchange({
    required this.conversationId,
    required this.userMessage,
    required this.assistantMessage,
  });

  final String conversationId;
  final CourseTutorMessage userMessage;
  final CourseTutorMessage assistantMessage;

  factory CourseTutorExchange.fromJson(Map<String, dynamic> json) {
    return CourseTutorExchange(
      conversationId: (json['conversationId'] as String?) ?? '',
      userMessage: CourseTutorMessage.fromJson(_asMap(json['userMessage'])),
      assistantMessage: CourseTutorMessage.fromJson(
        _asMap(json['assistantMessage']),
      ),
    );
  }
}

/// Everything the student study screen needs in one round-trip.
class CourseStudyWorkspace {
  const CourseStudyWorkspace({
    required this.courseId,
    required this.courseTitle,
    this.chapters = const [],
    this.artifacts = const [],
    this.conversations = const [],
  });

  final String courseId;
  final String courseTitle;
  final List<CourseStudyChapter> chapters;
  final List<CourseStudyArtifact> artifacts;
  final List<CourseTutorConversation> conversations;

  /// Newest summary (backend returns artifacts newest-first).
  CourseStudyArtifact? get latestSummary => _latestWhere((a) => a.isSummary);

  /// Newest flashcard deck.
  CourseStudyArtifact? get latestFlashcards =>
      _latestWhere((a) => a.isFlashcards);

  CourseStudyArtifact? _latestWhere(bool Function(CourseStudyArtifact) test) {
    for (final artifact in artifacts) {
      if (test(artifact)) return artifact;
    }
    return null;
  }

  /// Most recently updated thread, if any.
  CourseTutorConversation? get latestConversation =>
      conversations.isEmpty ? null : conversations.first;

  factory CourseStudyWorkspace.fromJson(Map<String, dynamic> json) {
    return CourseStudyWorkspace(
      courseId: (json['courseId'] as String?) ?? '',
      courseTitle: (json['courseTitle'] as String?) ?? '',
      chapters: _asMapList(
        json['chapters'],
      ).map(CourseStudyChapter.fromJson).toList(),
      artifacts: _asMapList(
        json['artifacts'],
      ).map(CourseStudyArtifact.fromJson).toList(),
      conversations: _asMapList(
        json['conversations'],
      ).map(CourseTutorConversation.fromJson).toList(),
    );
  }
}

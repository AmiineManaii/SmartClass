/// One course the teacher may use as an AI exam source.
///
/// Source: `GET /api/v1/exams/classes/:classGroupId/courses`. Only courses
/// already PUBLISHED are returned; publication requires every generated
/// section to be VALIDATED, so the list is exactly "generated and validated".
class ExamCourseOption {
  const ExamCourseOption({
    required this.id,
    required this.title,
    this.subject,
    this.chapters = const <String>[],
  });

  final String id;
  final String title;
  final String? subject;
  final List<String> chapters;
}

/// Teacher-owned document indexed in the Unified Knowledge Engine
/// (`GET /api/v1/knowledge/documents`), e.g. a verified recorded lecture.
class ExamKnowledgeDocumentOption {
  const ExamKnowledgeDocumentOption({
    required this.id,
    required this.sourceType,
    required this.title,
    this.subject,
    this.trustTier = 'VERIFIED',
    this.chunkCount = 0,
    this.indexStatus = 'INDEXED',
  });

  final String id;
  final String sourceType;
  final String title;
  final String? subject;
  final String trustTier;
  final int chunkCount;
  final String indexStatus;

  bool get isDraft => trustTier == 'DRAFT_AI';
}

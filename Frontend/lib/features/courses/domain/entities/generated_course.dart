/// Teacher-generated course (`GET /api/v1/courses/...`,
/// `contracts/courses.openapi.yaml`).
///
/// A generation is saved as DRAFT (author + admins only) until validated
/// (PUBLISHED), after which every authenticated user can read it.
class GeneratedCourse {
  const GeneratedCourse({
    required this.id,
    required this.title,
    required this.level,
    required this.difficulty,
    required this.format,
    required this.status,
    required this.authorId,
    required this.authorName,
    this.subject,
    this.content,
  });

  final String id;
  final String title;
  final String? subject;
  final String level;
  final String difficulty;
  final String format;

  /// Backend course status: `DRAFT` | `PUBLISHED`.
  final String status;
  final String authorId;
  final String authorName;

  /// Markdown body — present on detail reads, null on list summaries.
  final String? content;

  bool get isDraft => status == 'DRAFT';
  bool get isPublished => status == 'PUBLISHED';

  factory GeneratedCourse.fromJson(Map<String, dynamic> json) {
    return GeneratedCourse(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      subject: json['subject'] as String?,
      level: (json['level'] as String?) ?? 'equilibre',
      difficulty: (json['difficulty'] as String?) ?? 'moyen',
      format: (json['format'] as String?) ?? 'resume',
      status: (json['status'] as String?) ?? 'DRAFT',
      authorId: (json['authorId'] as String?) ?? '',
      authorName: (json['authorName'] as String?) ?? '',
      content: json['content'] as String?,
    );
  }
}

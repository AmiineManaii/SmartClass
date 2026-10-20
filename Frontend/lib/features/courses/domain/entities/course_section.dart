/// One chapter of the by-section build
/// (`GET /api/v1/ai/courses/:id/build`, `contracts/ai-assistant.openapi.yaml`).
///
/// Sections are materialized from the teacher-validated outline on first
/// open (PENDING), filled by the local model (GENERATED), then approved by
/// the teacher (VALIDATED). Publishing the draft stays blocked (409
/// `SECTIONS_NOT_VALIDATED`) while any section is not VALIDATED (RG27).
enum CourseSectionStatus { pending, generated, validated }

CourseSectionStatus courseSectionStatusFromJson(Object? raw) {
  switch (raw?.toString()) {
    case 'GENERATED':
      return CourseSectionStatus.generated;
    case 'VALIDATED':
      return CourseSectionStatus.validated;
    default:
      return CourseSectionStatus.pending;
  }
}

class CourseSectionEntry {
  const CourseSectionEntry({
    required this.id,
    required this.courseId,
    required this.sectionKey,
    required this.title,
    required this.description,
    required this.keyTopics,
    required this.content,
    required this.order,
    required this.estimatedMinutes,
    required this.status,
  });

  final String id;
  final String courseId;
  final String sectionKey;
  final String title;
  final String description;
  final List<String> keyTopics;

  /// Markdown body — null until generated, replaced on regenerate.
  final String? content;
  final int order;
  final int estimatedMinutes;
  final CourseSectionStatus status;

  bool get hasContent => content != null && content!.trim().isNotEmpty;

  CourseSectionEntry copyWith({
    String? id,
    String? courseId,
    String? sectionKey,
    String? title,
    String? description,
    List<String>? keyTopics,
    String? content,
    int? order,
    int? estimatedMinutes,
    CourseSectionStatus? status,
  }) {
    return CourseSectionEntry(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      sectionKey: sectionKey ?? this.sectionKey,
      title: title ?? this.title,
      description: description ?? this.description,
      keyTopics: keyTopics ?? this.keyTopics,
      content: content ?? this.content,
      order: order ?? this.order,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      status: status ?? this.status,
    );
  }

  factory CourseSectionEntry.fromJson(Map<String, dynamic> json) {
    return CourseSectionEntry(
      id: json['id']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      sectionKey: json['sectionKey']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      keyTopics: (json['keyTopics'] as List<dynamic>?)
              ?.map((topic) => topic.toString())
              .toList() ??
          const [],
      content: json['content'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 15,
      status: courseSectionStatusFromJson(json['status']),
    );
  }
}

/// Course metadata returned with the build (subset of the draft).
class CourseBuildCourse {
  const CourseBuildCourse({
    required this.id,
    required this.title,
    required this.subject,
    required this.level,
    required this.difficulty,
    required this.format,
  });

  final String id;
  final String title;
  final String? subject;
  final String level;
  final String difficulty;
  final String format;

  factory CourseBuildCourse.fromJson(Map<String, dynamic> json) {
    return CourseBuildCourse(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subject: json['subject'] as String?,
      level: json['level']?.toString() ?? 'equilibre',
      difficulty: json['difficulty']?.toString() ?? 'moyen',
      format: json['format']?.toString() ?? 'resume',
    );
  }
}

/// Payload of `GET /api/v1/ai/courses/:id/build`.
class CourseBuildData {
  const CourseBuildData({
    required this.course,
    required this.sections,
    required this.initializedFromOutline,
  });

  final CourseBuildCourse course;
  final List<CourseSectionEntry> sections;

  /// True when this first call materialized the sections from the outline.
  final bool initializedFromOutline;
}

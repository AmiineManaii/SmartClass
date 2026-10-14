class CourseOutlineSection {
  final String id;
  final String title;
  final String description;
  final List<String> subtopics;
  final int? estimatedMinutes;

  const CourseOutlineSection({
    required this.id,
    required this.title,
    this.description = '',
    this.subtopics = const [],
    this.estimatedMinutes,
  });

  CourseOutlineSection copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? subtopics,
    int? estimatedMinutes,
  }) {
    return CourseOutlineSection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subtopics: subtopics ?? this.subtopics,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }

  factory CourseOutlineSection.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['keyTopics'] ?? json['subtopics'];
    final topicsList = (rawTopics as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    return CourseOutlineSection(
      id: json['id']?.toString() ?? 'sec-${DateTime.now().microsecondsSinceEpoch}',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      subtopics: topicsList,
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'keyTopics': subtopics,
        'subtopics': subtopics,
        if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
      };
}

class CourseOutline {
  final String title;
  final String description;
  final String targetAudience;
  final List<String> prerequisites;
  final List<CourseOutlineSection> sections;

  const CourseOutline({
    required this.title,
    this.description = '',
    this.targetAudience = 'Étudiants universitaires',
    this.prerequisites = const [],
    this.sections = const [],
  });

  CourseOutline copyWith({
    String? title,
    String? description,
    String? targetAudience,
    List<String>? prerequisites,
    List<CourseOutlineSection>? sections,
  }) {
    return CourseOutline(
      title: title ?? this.title,
      description: description ?? this.description,
      targetAudience: targetAudience ?? this.targetAudience,
      prerequisites: prerequisites ?? this.prerequisites,
      sections: sections ?? this.sections,
    );
  }

  factory CourseOutline.fromJson(Map<String, dynamic> json) {
    return CourseOutline(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      targetAudience: json['targetAudience']?.toString() ?? 'Étudiants universitaires',
      prerequisites: (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sections: (json['sections'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(CourseOutlineSection.fromJson)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'targetAudience': targetAudience,
        'prerequisites': prerequisites,
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}

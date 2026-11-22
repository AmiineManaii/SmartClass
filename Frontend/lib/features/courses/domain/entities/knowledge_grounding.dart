import 'course_outline.dart';

/// Teacher-side configuration controlling Phase 2 RAG grounding during course
/// creation, outline generation, PDF improvement, section build & refinement.
class KnowledgeGroundingConfig {
  final bool enabled;

  /// Empty means search across all indexed source types of the teacher.
  final List<String> sourceTypes;

  /// Empty means automatic hybrid search across the teacher's knowledge base.
  final List<String> documentIds;

  /// Default `false`: never silently ground from unvalidated `DRAFT_AI` docs.
  final bool includeDrafts;

  final int maxChunks;

  const KnowledgeGroundingConfig({
    this.enabled = true,
    this.sourceTypes = const [],
    this.documentIds = const [],
    this.includeDrafts = false,
    this.maxChunks = 5,
  });

  KnowledgeGroundingConfig copyWith({
    bool? enabled,
    List<String>? sourceTypes,
    List<String>? documentIds,
    bool? includeDrafts,
    int? maxChunks,
  }) {
    return KnowledgeGroundingConfig(
      enabled: enabled ?? this.enabled,
      sourceTypes: sourceTypes ?? this.sourceTypes,
      documentIds: documentIds ?? this.documentIds,
      includeDrafts: includeDrafts ?? this.includeDrafts,
      maxChunks: maxChunks ?? this.maxChunks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      if (sourceTypes.isNotEmpty) 'sourceTypes': sourceTypes,
      if (documentIds.isNotEmpty) 'documentIds': documentIds,
      'includeDrafts': includeDrafts,
      'maxChunks': maxChunks,
    };
  }
}

/// Summary of an indexed document belonging to the authenticated teacher.
class KnowledgeDocumentSummary {
  final String id;
  final String sourceType;
  final String title;
  final String? subject;
  final String trustTier;
  final String indexStatus;
  final int chunkCount;

  const KnowledgeDocumentSummary({
    required this.id,
    required this.sourceType,
    required this.title,
    this.subject,
    required this.trustTier,
    required this.indexStatus,
    required this.chunkCount,
  });

  factory KnowledgeDocumentSummary.fromJson(Map<String, dynamic> json) {
    return KnowledgeDocumentSummary(
      id: json['id']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? 'COURSE',
      title: json['title']?.toString() ?? 'Document',
      subject: json['subject']?.toString(),
      trustTier: json['trustTier']?.toString() ?? 'VERIFIED',
      indexStatus: json['indexStatus']?.toString() ?? 'INDEXED',
      chunkCount: (json['chunkCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Attributed knowledge source injected into an AI course generation prompt.
class KnowledgeSourceAttribution {
  final String documentId;
  final String chunkId;
  final String sourceType;
  final String sourceId;
  final String title;
  final String? sectionTitle;
  final String trustTier;
  final double score;
  final double? vectorScore;
  final double? ftsScore;
  final int? startSeconds;
  final int? sourcePage;
  final int? slideNumber;
  final String snippet;

  const KnowledgeSourceAttribution({
    required this.documentId,
    required this.chunkId,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    this.sectionTitle,
    required this.trustTier,
    required this.score,
    this.vectorScore,
    this.ftsScore,
    this.startSeconds,
    this.sourcePage,
    this.slideNumber,
    required this.snippet,
  });

  factory KnowledgeSourceAttribution.fromJson(Map<String, dynamic> json) {
    return KnowledgeSourceAttribution(
      documentId: json['documentId']?.toString() ?? '',
      chunkId: json['chunkId']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? 'COURSE',
      sourceId: json['sourceId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      sectionTitle: json['sectionTitle']?.toString(),
      trustTier: json['trustTier']?.toString() ?? 'VERIFIED',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      vectorScore: (json['vectorScore'] as num?)?.toDouble(),
      ftsScore: (json['ftsScore'] as num?)?.toDouble(),
      startSeconds: (json['startSeconds'] as num?)?.toInt(),
      sourcePage: (json['sourcePage'] as num?)?.toInt(),
      slideNumber: (json['slideNumber'] as num?)?.toInt(),
      snippet: json['snippet']?.toString() ?? '',
    );
  }

  String? get formattedTimestamp {
    final s = startSeconds;
    if (s == null || s < 0) return null;
    final mins = (s ~/ 60).toString().padLeft(2, '0');
    final secs = (s % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  int get relevancePercent {
    final base = vectorScore ?? score;
    return (base.clamp(0.0, 1.0) * 100).round();
  }
}

List<KnowledgeSourceAttribution> parseKnowledgeSources(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(KnowledgeSourceAttribution.fromJson)
      .where((item) => item.title.isNotEmpty)
      .toList();
}

/// Result returned by `/ai/courses/generate-outline` with RAG attribution.
class OutlineGenerationResult {
  final CourseOutline outline;
  final String? model;
  final List<KnowledgeSourceAttribution> knowledgeSources;
  final String? knowledgeSearchMode;
  final String? knowledgeDegradedReason;

  const OutlineGenerationResult({
    required this.outline,
    this.model,
    this.knowledgeSources = const [],
    this.knowledgeSearchMode,
    this.knowledgeDegradedReason,
  });
}

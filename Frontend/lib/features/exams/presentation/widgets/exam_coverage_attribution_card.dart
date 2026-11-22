import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/exam_definition.dart';

/// Displays transparent multi-source / multi-chapter coverage distribution,
/// truncation / degradation notices, and collapsible RAG source attribution for
/// an AI-generated exam preview.
class ExamCoverageAttributionCard extends StatelessWidget {
  const ExamCoverageAttributionCard({
    required this.sources,
    this.coverage,
    this.searchMode,
    this.degradedReason,
    super.key,
  });

  final List<ExamKnowledgeSource> sources;
  final ExamCoverageReport? coverage;
  final String? searchMode;
  final String? degradedReason;

  static IconData _iconForSourceType(String sourceType) {
    switch (sourceType) {
      case 'COURSE':
        return Icons.menu_book_rounded;
      case 'COURSE_SECTION':
        return Icons.segment_rounded;
      case 'LECTURE_TRANSCRIPT':
        return Icons.videocam_rounded;
      case 'LECTURE_SLIDE':
        return Icons.slideshow_rounded;
      case 'LECTURE_PACKAGE':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.description_outlined;
    }
  }

  static String _labelForSourceType(String sourceType) {
    switch (sourceType) {
      case 'COURSE':
        return 'Cours';
      case 'COURSE_SECTION':
        return 'Chapitre';
      case 'LECTURE_TRANSCRIPT':
        return 'Vidéo';
      case 'LECTURE_SLIDE':
        return 'Slide';
      case 'LECTURE_PACKAGE':
        return 'Synthèse';
      case 'RECORDING_SOURCE_DOC':
        return 'Support';
      default:
        return 'Document';
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = coverage;
    final isDegraded = searchMode == 'FTS_ONLY';
    if (report == null && sources.isEmpty && !isDegraded) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 19, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('exam_ai_coverage_title'),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (searchMode != null && searchMode!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDegraded
                        ? scheme.tertiaryContainer
                        : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    searchMode!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDegraded
                          ? scheme.onTertiaryContainer
                          : scheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          if (isDegraded ||
              (degradedReason != null && degradedReason!.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 17,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      degradedReason?.isNotEmpty == true
                          ? '${context.tr('exam_ai_coverage_degraded')} : $degradedReason'
                          : context.tr('exam_ai_coverage_degraded'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (report != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _SummaryPill(
                  icon: Icons.layers_outlined,
                  label: context.tr(
                    'exam_ai_coverage_sources',
                    args: <String, String>{
                      'covered': '${report.coveredSources}',
                      'total': '${report.totalSources}',
                    },
                  ),
                ),
                if (report.totalChapters > 0)
                  _SummaryPill(
                    icon: Icons.topic_outlined,
                    label: context.tr(
                      'exam_ai_coverage_chapters',
                      args: <String, String>{
                        'covered': '${report.coveredChapters}',
                        'total': '${report.totalChapters}',
                      },
                    ),
                  ),
                if (report.truncated)
                  _SummaryPill(
                    icon: Icons.content_cut_rounded,
                    label: context.tr('exam_ai_coverage_truncated'),
                    warning: true,
                  ),
              ],
            ),
            if (report.warnings.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final warning in report.warnings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $warning',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (report.distribution.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final entry in report.distribution)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _iconForSourceType(entry.sourceType),
                              size: 15,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                entry.title,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                context.tr(
                                  'exam_ai_coverage_questions_target',
                                  args: <String, String>{
                                    'count': '${entry.targetQuestions}',
                                  },
                                ),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (entry.chapters.isNotEmpty || entry.trimmed) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _SummaryPill(
                                label: _labelForSourceType(entry.sourceType),
                              ),
                              for (final ch in entry.chapters)
                                _SummaryPill(label: ch),
                              if (entry.trimmed)
                                _SummaryPill(
                                  label:
                                      '${entry.charsIncluded}/${entry.charsOriginal} car.',
                                  warning: true,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ],
          if (sources.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 4),
              title: Text(
                context.tr(
                  'exam_ai_coverage_view_extracts',
                  args: <String, String>{'count': '${sources.length}'},
                ),
                style: theme.textTheme.labelMedium,
              ),
              children: [
                for (final src in sources)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _iconForSourceType(src.sourceType),
                              size: 14,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                src.sectionTitle != null &&
                                        src.sectionTitle!.isNotEmpty
                                    ? '${src.title} • ${src.sectionTitle}'
                                    : src.title,
                                style: theme.textTheme.labelMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _SummaryPill(
                              label: _labelForSourceType(src.sourceType),
                            ),
                            _SummaryPill(
                              label: context.tr(
                                src.trustTier == 'DRAFT_AI'
                                    ? 'exam_ai_trust_draft'
                                    : 'exam_ai_trust_verified',
                              ),
                              warning: src.trustTier == 'DRAFT_AI',
                            ),
                            if (src.formattedTimestamp != null)
                              _SummaryPill(label: src.formattedTimestamp!),
                            if (src.slideNumber != null)
                              _SummaryPill(label: 'Slide #${src.slideNumber}'),
                          ],
                        ),
                        if (src.snippet.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            src.snippet,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    this.icon,
    this.warning = false,
  });

  final String label;
  final IconData? icon;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = warning
        ? scheme.tertiaryContainer
        : scheme.surfaceContainerHighest;
    final fg = warning ? scheme.onTertiaryContainer : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

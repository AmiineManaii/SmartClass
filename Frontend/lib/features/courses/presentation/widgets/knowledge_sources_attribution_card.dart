import 'package:flutter/material.dart';

import '../../domain/entities/knowledge_grounding.dart';

/// Displays attributed knowledge base chunks used to ground an outline,
/// full course, section, or inline AI refinement, plus honest search mode state.
class KnowledgeSourcesAttributionCard extends StatelessWidget {
  final List<KnowledgeSourceAttribution> sources;
  final String? searchMode;
  final String? degradedReason;
  final bool compact;

  const KnowledgeSourcesAttributionCard({
    super.key,
    required this.sources,
    this.searchMode,
    this.degradedReason,
    this.compact = false,
  });

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
        return 'Section';
      case 'LECTURE_TRANSCRIPT':
        return 'Séance vidéo';
      case 'LECTURE_SLIDE':
        return 'Diapositive';
      case 'LECTURE_PACKAGE':
        return 'Synthèse vidéo';
      case 'RECORDING_SOURCE_DOC':
        return 'Support séance';
      default:
        return 'Document';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDegraded = searchMode == 'FTS_ONLY';
    if (sources.isEmpty && !isDegraded) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: isDegraded
            ? colorScheme.secondaryContainer.withValues(alpha: 0.25)
            : colorScheme.primaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDegraded
              ? colorScheme.secondary.withValues(alpha: 0.4)
              : colorScheme.primary.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.library_books_outlined,
                size: compact ? 15 : 17,
                color: isDegraded ? colorScheme.secondary : colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sources.isEmpty
                      ? 'Base de connaissances (recherche lexicale dégradée)'
                      : 'Sources de votre base utilisées (${sources.length})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (searchMode != null && searchMode != 'DISABLED')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDegraded
                        ? colorScheme.secondaryContainer
                        : colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    searchMode!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDegraded
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          if (isDegraded &&
              degradedReason != null &&
              degradedReason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Mode dégradé : $degradedReason',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: colorScheme.secondary,
              ),
            ),
          ],
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...sources.map((src) {
              final timestamp = src.formattedTimestamp;
              final isDraft = src.trustTier == 'DRAFT_AI';
              return Container(
                margin: const EdgeInsets.only(top: 6),
                padding: EdgeInsets.all(compact ? 8 : 10),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
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
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            src.sectionTitle != null &&
                                    src.sectionTitle!.trim().isNotEmpty
                                ? '${src.title} • ${src.sectionTitle}'
                                : src.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${src.relevancePercent}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MetaPill(label: _labelForSourceType(src.sourceType)),
                        _MetaPill(
                          label: isDraft ? 'Brouillon IA' : 'Vérifié',
                          highlight: !isDraft,
                        ),
                        if (timestamp != null) _MetaPill(label: timestamp),
                        if (src.slideNumber != null)
                          _MetaPill(label: 'Slide #${src.slideNumber}'),
                        if (src.sourcePage != null)
                          _MetaPill(label: 'p. ${src.sourcePage}'),
                      ],
                    ),
                    if (!compact && src.snippet.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        src.snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final bool highlight;

  const _MetaPill({required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: highlight
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.6)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: highlight
              ? colorScheme.onTertiaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

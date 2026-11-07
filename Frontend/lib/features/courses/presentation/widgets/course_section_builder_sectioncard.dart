part of '../pages/course_section_builder_page.dart';
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.index,
    required this.section,
    required this.state,
    required this.imageLoading,
    required this.onGenerate,
    required this.onRegenerate,
    required this.onValidate,
    required this.onImage,
    required this.onCancel,
  });

  final int index;
  final CourseSectionEntry section;
  final CourseSectionBuildState state;
  final bool imageLoading;
  final Future<void> Function() onGenerate;
  final Future<void> Function() onRegenerate;
  final Future<void> Function() onValidate;
  final Future<void> Function() onImage;
  final VoidCallback onCancel;

  Color _statusColor(ColorScheme colors, bool isStreaming) {
    if (isStreaming) {
      return colors.primary;
    }
    switch (section.status) {
      case CourseSectionStatus.validated:
        return Colors.green.shade50;
      case CourseSectionStatus.generated:
        return const Color(0xFFFEF3C7);
      case CourseSectionStatus.pending:
        return colors.surfaceContainerHighest;
    }
  }

  Color _statusTextColor(ColorScheme colors, bool isStreaming) {
    if (isStreaming) {
      return colors.onPrimary;
    }
    switch (section.status) {
      case CourseSectionStatus.validated:
        return Colors.green.shade800;
      case CourseSectionStatus.generated:
        return const Color(0xFF92400E);
      case CourseSectionStatus.pending:
        return colors.onSurfaceVariant;
    }
  }

  IconData _statusIcon(bool isStreaming) {
    if (isStreaming) {
      return Icons.bolt_rounded;
    }
    switch (section.status) {
      case CourseSectionStatus.validated:
        return Icons.check_circle_rounded;
      case CourseSectionStatus.generated:
        return Icons.rate_review_outlined;
      case CourseSectionStatus.pending:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _statusLabel(
    BuildContext context, {
    required bool isStreaming,
    required bool isNext,
  }) {
    if (isStreaming) {
      return 'EN COURS DE RÉDACTION...';
    }
    switch (section.status) {
      case CourseSectionStatus.validated:
        return 'Validée & Prête';
      case CourseSectionStatus.generated:
        return 'Rédigée (À valider)';
      case CourseSectionStatus.pending:
        return isNext ? 'Prochaine en attente' : 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isStreaming = state.streamingKey == section.sectionKey;
    final otherBusy = state.isStreaming && !isStreaming;
    final isValidated = section.status == CourseSectionStatus.validated;
    final isGenerated = section.status == CourseSectionStatus.generated;
    final isPending = section.status == CourseSectionStatus.pending;

    final pendingSections = state.sections
        .where((s) => s.status == CourseSectionStatus.pending)
        .toList();
    final isNext =
        isPending &&
        pendingSections.isNotEmpty &&
        pendingSections.first.sectionKey == section.sectionKey;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: (isPending && (otherBusy || state.isGeneratingAll)) ? 0.72 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: isStreaming
              ? colorScheme.primaryContainer.withValues(alpha: 0.12)
              : (isValidated
                    ? Colors.green.withValues(alpha: 0.02)
                    : colorScheme.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isStreaming
                ? colorScheme.primary
                : (isValidated
                      ? Colors.green.shade400.withValues(alpha: 0.5)
                      : (isGenerated
                            ? Colors.amber.shade400.withValues(alpha: 0.6)
                            : colorScheme.outlineVariant.withValues(
                                alpha: 0.45,
                              ))),
            width: isStreaming ? 2.0 : (isValidated ? 1.3 : 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: isStreaming
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isStreaming ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: badge + status chip + duration.
              Row(
                children: [
                  Flexible(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isStreaming
                                ? colorScheme.primary
                                : colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.tr(
                              'ai_build_section_num',
                              args: {
                                'n': (index + 1).toString().padLeft(2, '0'),
                              },
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.5,
                              color: isStreaming
                                  ? colorScheme.onPrimary
                                  : colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(colorScheme, isStreaming),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isStreaming) ...[
                                const SmartLoader.small(
                                  customSize: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                              ] else ...[
                                Icon(
                                  _statusIcon(isStreaming),
                                  size: 13,
                                  color: _statusTextColor(
                                    colorScheme,
                                    isStreaming,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                _statusLabel(
                                  context,
                                  isStreaming: isStreaming,
                                  isNext: isNext,
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _statusTextColor(
                                    colorScheme,
                                    isStreaming,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${section.estimatedMinutes} min',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title + description.
              Text(
                section.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              if (section.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  section.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],

              // Key topic pills.
              if (section.keyTopics.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final topic in section.keyTopics)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Text(
                          topic,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              // Live streaming panel (progress + preview + cancel).
              if (isStreaming) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.streamingPhase == 'web_search'
                                  ? '🔍 Recherche d\x27informations sur le web...'
                                  : (state.streamingPhase == 'memory'
                                        ? context.tr('ai_build_phase_memory')
                                        : '✍️ R\xE9daction du cours en cours...'),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: onCancel,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: Text(context.tr('cancel')),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(minHeight: 3),
                      if (state.streamingText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: SingleChildScrollView(
                            child: Text(
                              state.streamingText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                // Markdown preview of the generated content.
                if (section.hasContent) ...[
                  const SizedBox(height: 6),
                  // Inner Material: the tile's ListTile must paint its ink on
                  // a Material *inside* the card's decorated surface.
                  Material(
                    color: Colors.transparent,
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        dense: true,
                        title: Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('ai_build_preview'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        children: [MarkdownCourseView(data: section.content!)],
                      ),
                    ),
                  ),
                ],

                // Actions by status.
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (section.status == CourseSectionStatus.pending)
                      FilledButton.icon(
                        onPressed: otherBusy ? null : () => onGenerate(),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: Text(context.tr('ai_build_generate')),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    if (section.status == CourseSectionStatus.generated)
                      FilledButton.icon(
                        onPressed: otherBusy ? null : () => onValidate(),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(context.tr('ai_build_validate')),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    if (section.status != CourseSectionStatus.pending)
                      OutlinedButton.icon(
                        onPressed: otherBusy ? null : () => onRegenerate(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(context.tr('ai_build_regenerate')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: context.tr('ai_build_image'),
                      onPressed: otherBusy || imageLoading
                          ? null
                          : () => onImage(),
                      icon: imageLoading
                          ? const SmartLoader.small(customSize: 18)
                          : const Icon(Icons.image_outlined, size: 20),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Five web image candidates, tappable to insert into the section.

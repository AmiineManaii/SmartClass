part of '../pages/course_section_builder_page.dart';
extension on _CourseSectionBuilderPageState {
  Widget _buildProgressDashboard(
    BuildContext context,
    CourseSectionBuildState state,
    CourseSectionBuild notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = state.sections.length;
    final validated = state.validatedCount;
    final allValidated = total > 0 && state.remainingToValidate == 0;
    final generated = state.sections
        .where((s) => s.status == CourseSectionStatus.generated)
        .length;
    final pending = state.sections
        .where((s) => s.status == CourseSectionStatus.pending)
        .length;
    final progress = total == 0 ? 0.0 : (validated / total).clamp(0.0, 1.0);
    final activeStreamingKey = state.streamingKey;
    final isGenerating = state.isStreaming || state.isGeneratingAll;
    final activeSection = activeStreamingKey != null
        ? state.section(activeStreamingKey)
        : null;
    final activeIndex = activeSection != null
        ? state.sections.indexOf(activeSection)
        : -1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGenerating
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : (allValidated
                ? colorScheme.secondaryContainer.withValues(alpha: 0.35)
                : colorScheme.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGenerating
              ? colorScheme.primary.withValues(alpha: 0.55)
              : (allValidated
                  ? colorScheme.secondary.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant.withValues(alpha: 0.45)),
          width: isGenerating ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isGenerating
                ? colorScheme.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Status icon + Description & Action Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isGenerating
                      ? colorScheme.primary
                      : (allValidated
                          ? colorScheme.secondary
                          : colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: isGenerating
                      ? const SmartLoader.small(customSize: 18, color: Colors.white)
                      : Icon(
                          allValidated
                              ? Icons.verified_rounded
                              : Icons.auto_awesome_rounded,
                          size: 20,
                          color: allValidated
                              ? colorScheme.onSecondary
                              : colorScheme.primary,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGenerating
                          ? 'Génération en cours...'
                          : (allValidated
                              ? 'Cours complet prêt !'
                              : 'Construction du cours'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isGenerating
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGenerating && activeSection != null
                          ? 'Section ${activeIndex + 1}/$total : "${activeSection.title}"'
                          : (allValidated
                              ? 'Toutes les sections sont rédigées et validées'
                              : '$pending section(s) restante(s) à générer'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isGenerating)
                FilledButton.icon(
                  onPressed: () => notifier.cancel(),
                  icon: const Icon(Icons.stop_rounded, size: 16),
                  label: const Text('Arrêter'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                )
              else if (!allValidated)
                FilledButton.icon(
                  onPressed: () => notifier.generateAllRemaining(),
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('Tout générer'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () => context.push('/courses/${widget.courseId}'),
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: const Text('Lire'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                allValidated ? colorScheme.secondary : colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBadge(
                icon: Icons.check_circle_rounded,
                color: Colors.green.shade700,
                label: '$validated validée(s)',
              ),
              if (activeSection != null)
                _buildStatBadge(
                  icon: Icons.bolt_rounded,
                  color: colorScheme.primary,
                  label: '1 en cours',
                ),
              if (generated > 0)
                _buildStatBadge(
                  icon: Icons.edit_note_rounded,
                  color: Colors.amber.shade800,
                  label: '$generated à relire',
                ),
              _buildStatBadge(
                icon: Icons.hourglass_empty_rounded,
                color: colorScheme.onSurfaceVariant,
                label: '$pending en attente',
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Interactive Stepper Strip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < state.sections.length; i++) ...[
                    _buildSectionNavChip(
                      context: context,
                      index: i,
                      section: state.sections[i],
                      isCurrent:
                          state.streamingKey == state.sections[i].sectionKey,
                      onTap: () =>
                          _scrollToSection(state.sections[i].sectionKey),
                    ),
                    if (i < state.sections.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

}

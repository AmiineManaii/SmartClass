part of '../pages/ai_course_creator_page.dart';
class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final bool validated;
  final bool saving;
  final bool saved;
  final bool showDraftsLink;
  final VoidCallback onReset;
  final VoidCallback onEdit;
  final VoidCallback onRefineWithAi;
  final VoidCallback onSave;
  final VoidCallback onViewDrafts;

  const _ResultCard({
    required this.result,
    required this.validated,
    required this.saving,
    required this.saved,
    required this.showDraftsLink,
    required this.onReset,
    required this.onEdit,
    required this.onRefineWithAi,
    required this.onSave,
    required this.onViewDrafts,
  });

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: '${result['content'] ?? ''}'));
    if (!context.mounted) return;
    context.showSuccessToast(context.tr('ai_copied'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final usage = result['usage'] as Map<String, dynamic>?;
    final promptTokens = usage?['promptTokens'];
    final completionTokens = usage?['completionTokens'];
    final meta = [
      '${result['model'] ?? ''}',
      if (promptTokens != null && completionTokens != null)
        '$promptTokens+$completionTokens tk',
      if (result['truncatedSource'] == true) context.tr('ai_truncated_warn'),
      if (validated) context.tr('ai_validated'),
    ].where((s) => s.toString().isNotEmpty).join(' • ');

    final contentStr = '${result['content'] ?? ''}';
    final words = contentStr
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final readingMin = (words / 200).ceil().clamp(1, 180);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stitch Floating AI Assistant Bar matching Stitch screen bfcc2ec5274b4c5ab96fa9f7267ba62c
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                  colorScheme.secondary,
                ],
              ),
            ),
            padding: const EdgeInsets.all(1.5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Assistant Rédaction IA',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Actif',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Sélection contextuelle',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _AiActionChip(
                          icon: Icons.auto_fix_high,
                          label: 'Reformuler',
                          iconColor: colorScheme.primary,
                          onTap: onRefineWithAi,
                        ),
                        const SizedBox(width: 8),
                        _AiActionChip(
                          icon: Icons.add_circle_outline,
                          label: 'Ajouter des exemples',
                          iconColor: colorScheme.secondary,
                          onTap: onRefineWithAi,
                        ),
                        const SizedBox(width: 8),
                        _AiActionChip(
                          icon: Icons.psychology_outlined,
                          label: 'Simplifier',
                          iconColor: colorScheme.tertiary,
                          onTap: onRefineWithAi,
                        ),
                        const SizedBox(width: 8),
                        _AiActionChip(
                          icon: Icons.quiz_outlined,
                          label: 'Générer un QCM',
                          iconColor: colorScheme.primary,
                          filled: true,
                          onTap: onRefineWithAi,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('ai_result_title'),
                  style: theme.textTheme.labelLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.content_copy_rounded, size: 20),
                tooltip: context.tr('ai_copy'),
                onPressed: () => _copy(context),
              ),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              meta,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '~$readingMin min de lecture',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$words mots',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 480),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              // Markdown rendered as a clean document (titles, figures,
              // code, images) — no raw markup shown to the teacher.
              child: MarkdownCourseView(data: contentStr),
            ),
          ),
          const SizedBox(height: 12),
          // AI In-line refinement button
          FilledButton.icon(
            onPressed: onRefineWithAi,
            icon: const Icon(Icons.auto_fix_high, size: 18),
            label: Text(context.tr('ai_refine_btn')),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.tertiary,
              foregroundColor: colorScheme.onTertiary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(context.tr('ai_edit_course')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(context.tr('ai_new_generation')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Save status and actions.
          if (saved) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_done_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enregistré dans vos brouillons',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onViewDrafts,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(context.tr('view_drafts')),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? SmartLoader.small(
                        customSize: 18,
                        color: colorScheme.onPrimary,
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(context.tr('save_course')),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: onViewDrafts,
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: Text(context.tr('my_courses')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


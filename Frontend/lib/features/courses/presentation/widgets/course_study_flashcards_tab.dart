import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/course_study_provider.dart';
import '../../domain/entities/course_study.dart';
import 'course_study_shared.dart';

/// Student tab: flip-card deck generated from the published course.
class CourseStudyFlashcardsTab extends ConsumerWidget {
  const CourseStudyFlashcardsTab({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CourseStudyAsyncGate(
      courseId: courseId,
      builder: (context, workspace) =>
          _FlashcardsBody(courseId: courseId, workspace: workspace),
    );
  }
}

class _FlashcardsBody extends ConsumerStatefulWidget {
  const _FlashcardsBody({required this.courseId, required this.workspace});

  final String courseId;
  final CourseStudyWorkspace workspace;

  @override
  ConsumerState<_FlashcardsBody> createState() => _FlashcardsBodyState();
}

class _FlashcardsBodyState extends ConsumerState<_FlashcardsBody> {
  int _index = 0;
  bool _flipped = false;

  String get _language =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'fr';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final action = ref.watch(courseStudyControllerProvider(widget.courseId));
    final artifact = widget.workspace.latestFlashcards;
    final cards = artifact?.flashcards.cards ?? const <CourseFlashcard>[];

    ref.listen(
      courseStudyControllerProvider(widget.courseId).select((s) => s.error),
      (previous, next) {
        if (next != null && next != previous) {
          context.showErrorToast(courseStudyErrorMessage(context, next));
        }
      },
    );

    final safeIndex = cards.isEmpty ? 0 : _index.clamp(0, cards.length - 1);
    final card = cards.isEmpty ? null : cards[safeIndex];

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(courseStudyWorkspaceProvider(widget.courseId)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            children: [
              Icon(Icons.style_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('course_study_flashcards_title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (artifact != null)
                IconButton(
                  tooltip: context.tr('course_study_delete'),
                  onPressed: action.busy ? null : () => _delete(artifact.id),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: action.busy
                ? null
                : () => ref
                      .read(
                        courseStudyControllerProvider(widget.courseId).notifier,
                      )
                      .generateFlashcards(language: _language),
            icon: action.isGeneratingFlashcards
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.style_outlined, size: 18),
            label: Text(
              context.tr(
                artifact == null
                    ? 'course_study_generate'
                    : 'course_study_regenerate',
              ),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          if (artifact == null || card == null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                context.tr('course_study_flashcards_empty'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            )
          else ...[
            if (artifact.usedFallback) ...[
              const CourseStudyFallbackBadge(),
              const SizedBox(height: 12),
            ],
            _Flashcard(
              card: card,
              flipped: _flipped,
              onTap: () => setState(() => _flipped = !_flipped),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                context.tr(
                  'course_study_flashcard_of',
                  args: {
                    'current': '${safeIndex + 1}',
                    'total': '${cards.length}',
                  },
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: safeIndex == 0
                        ? null
                        : () => setState(() {
                            _index = safeIndex - 1;
                            _flipped = false;
                          }),
                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                    label: Text(context.tr('course_study_flashcard_previous')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: safeIndex >= cards.length - 1
                        ? null
                        : () => setState(() {
                            _index = safeIndex + 1;
                            _flipped = false;
                          }),
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: Text(context.tr('course_study_flashcard_next')),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _delete(String artifactId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('course_study_delete')),
        content: Text(context.tr('delete_course_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(courseStudyControllerProvider(widget.courseId).notifier)
        .deleteArtifact(artifactId);
    if (!mounted) return;
    setState(() {
      _index = 0;
      _flipped = false;
    });
    context.showInfoToast(context.tr('course_study_deleted'));
  }
}

class _Flashcard extends StatelessWidget {
  const _Flashcard({
    required this.card,
    required this.flipped,
    required this.onTap,
  });

  final CourseFlashcard card;
  final bool flipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 250,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: flipped
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.sectionTitle != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  card.sectionTitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 14),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    flipped ? card.back : card.front,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      height: 1.5,
                      fontWeight: flipped ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                context.tr('course_study_flashcard_hint'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

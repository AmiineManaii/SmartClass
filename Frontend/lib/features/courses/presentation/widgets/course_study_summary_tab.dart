import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/course_study_provider.dart';
import '../../domain/entities/course_study.dart';
import 'course_study_shared.dart';
import 'markdown_course_view.dart';

/// Student tab: AI summary of the published course (short/medium/detailed/
/// exam/ELI15/bullet styles, optional chapter focus). All content is
/// generated strictly from the course — never from outside knowledge.
class CourseStudySummaryTab extends ConsumerWidget {
  const CourseStudySummaryTab({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CourseStudyAsyncGate(
      courseId: courseId,
      builder: (context, workspace) =>
          _SummaryBody(courseId: courseId, workspace: workspace),
    );
  }
}

class _SummaryBody extends ConsumerStatefulWidget {
  const _SummaryBody({required this.courseId, required this.workspace});

  final String courseId;
  final CourseStudyWorkspace workspace;

  @override
  ConsumerState<_SummaryBody> createState() => _SummaryBodyState();
}

class _SummaryBodyState extends ConsumerState<_SummaryBody> {
  static const _modes = <String, String>{
    'short': 'study_lab_summary_short',
    'medium': 'study_lab_summary_medium',
    'detailed': 'study_lab_summary_detailed',
    'exam': 'study_lab_summary_exam',
    'eli15': 'study_lab_summary_eli15',
    'bullet_points': 'course_study_summary_bullets',
  };

  String _mode = 'medium';
  String _focus = '';

  String get _language =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'fr';

  @override
  void initState() {
    super.initState();
    final artifact = widget.workspace.latestSummary;
    final savedMode = artifact?.rawContent['mode'];
    if (savedMode is String && _modes.containsKey(savedMode)) {
      _mode = savedMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final action = ref.watch(courseStudyControllerProvider(widget.courseId));
    final artifact = widget.workspace.latestSummary;
    // Keep the dropdown valid if the teacher edited the chapters meanwhile.
    final focusValue = widget.workspace.chapters.any((c) => c.title == _focus)
        ? _focus
        : '';

    ref.listen(
      courseStudyControllerProvider(widget.courseId).select((s) => s.error),
      (previous, next) {
        if (next != null && next != previous) {
          context.showErrorToast(courseStudyErrorMessage(context, next));
        }
      },
    );

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(courseStudyWorkspaceProvider(widget.courseId)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('course_study_summary_title'),
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
          const SizedBox(height: 4),
          Text(
            context.tr('course_study_summary_style'),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _modes.entries.map((entry) {
              return ChoiceChip(
                label: Text(context.tr(entry.value)),
                selected: _mode == entry.key,
                onSelected: action.busy
                    ? null
                    : (_) => setState(() => _mode = entry.key),
              );
            }).toList(),
          ),
          if (widget.workspace.chapters.length > 1) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  context.tr('course_study_focus_label'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: focusValue,
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(context.tr('course_study_focus_all')),
                      ),
                      ...widget.workspace.chapters.map(
                        (chapter) => DropdownMenuItem(
                          value: chapter.title,
                          child: Text(
                            chapter.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: action.busy
                        ? null
                        : (value) => setState(() => _focus = value ?? ''),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: action.busy
                ? null
                : () => ref
                      .read(
                        courseStudyControllerProvider(widget.courseId).notifier,
                      )
                      .generateSummary(
                        mode: _mode,
                        focus: focusValue.isEmpty ? null : focusValue,
                        language: _language,
                      ),
            icon: action.isGeneratingSummary
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 18),
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
          const SizedBox(height: 18),
          if (artifact == null)
            _SummaryEmptyState(theme: theme)
          else
            _SummaryArtifactView(artifact: artifact),
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
    context.showInfoToast(context.tr('course_study_deleted'));
  }
}

class _SummaryEmptyState extends StatelessWidget {
  const _SummaryEmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        context.tr('course_study_summary_empty'),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }
}

class _SummaryArtifactView extends StatelessWidget {
  const _SummaryArtifactView({required this.artifact});

  final CourseStudyArtifact artifact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = artifact.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (artifact.usedFallback) ...[
          const CourseStudyFallbackBadge(),
          const SizedBox(height: 12),
        ],
        MarkdownCourseView(data: summary.markdown),
        if (summary.keyTakeaways.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            context.tr('course_study_key_takeaways'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...summary.keyTakeaways.map(
            (takeaway) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      takeaway,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

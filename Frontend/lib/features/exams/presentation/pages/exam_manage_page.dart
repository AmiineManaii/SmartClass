import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/exam_providers.dart';
import '../../domain/entities/exam_definition.dart';
import '../widgets/exam_state_views.dart';
import '../widgets/exam_tag.dart';
import '../widgets/exam_ui.dart';

/// Teacher view of one exam: correction, settings, lifecycle and attempts.
/// Opening this page never creates an attempt and never starts a timer.
class ExamManagePage extends ConsumerWidget {
  const ExamManagePage({required this.examId, super.key});

  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exam = ref.watch(teacherExamProvider(examId));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('exam_manage_title')),
        actions: [
          IconButton(
            tooltip: context.tr('refresh'),
            onPressed: () {
              ref.invalidate(teacherExamProvider(examId));
              ref.invalidate(examResultsProvider(examId));
              ref.invalidate(myExamsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: exam.when(
        loading: () => const Center(child: SmartLoader()),
        error: (error, _) => ExamErrorView(
          errorKey: examErrorKey(error),
          detail: examErrorDetail(error),
          onRetry: () => ref.invalidate(teacherExamProvider(examId)),
        ),
        data: (detail) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(teacherExamProvider(examId));
            ref.invalidate(examResultsProvider(examId));
          },
          child: ListView(
            padding: EdgeInsets.all(context.isDesktop ? 32 : 16),
            children: [
              _ExamHeader(detail: detail),
              const SizedBox(height: 16),
              _LifecycleActions(detail: detail),
              const SizedBox(height: 16),
              _AttemptsSection(detail: detail),
              const SizedBox(height: 16),
              _CorrectionSection(detail: detail),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamHeader extends StatelessWidget {
  const _ExamHeader({required this.detail});

  final ExamDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ExamTag(
                labelKey: examStatusKey(detail.status),
                tone: detail.status == ExamStatus.draft
                    ? ExamTagTone.warning
                    : ExamTagTone.primary,
              ),
              ExamTag(
                labelKey: examSourceKey(detail.source),
                icon: examSourceIcon(detail.source),
              ),
              ExamTag(
                labelKey: 'exam_question_count',
                args: <String, String>{
                  'count': '${detail.questionCount}',
                },
                tone: ExamTagTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            detail.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (detail.description != null && detail.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detail.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _Meta(
                icon: Icons.groups_rounded,
                text: detail.className ?? context.tr('exam_class_unknown'),
              ),
              _Meta(
                icon: Icons.event_rounded,
                text: formatExamDateTime(context, detail.startsAt),
              ),
              _Meta(
                icon: Icons.event_available_rounded,
                text: formatExamDateTime(context, detail.endsAt),
              ),
              _Meta(
                icon: Icons.access_time_rounded,
                text: context.tr(
                  'exam_minutes',
                  args: <String, String>{'count': '${detail.durationMinutes}'},
                ),
              ),
              _Meta(
                icon: Icons.help_outline_rounded,
                text: context.tr(
                  'exam_question_count',
                  args: <String, String>{'count': '${detail.questionCount}'},
                ),
              ),
              _Meta(
                icon: Icons.stars_rounded,
                text: context.tr(
                  'exam_points',
                  args: <String, String>{'count': '${detail.totalPoints}'},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LifecycleActions extends ConsumerWidget {
  const _LifecycleActions({required this.detail});

  final ExamDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('exam_lifecycle_title'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(
              switch (detail.status) {
                ExamStatus.draft => 'exam_lifecycle_draft_hint',
                ExamStatus.published => 'exam_lifecycle_published_hint',
                ExamStatus.closed => 'exam_lifecycle_closed_hint',
              },
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (detail.status == ExamStatus.draft)
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/exams/${detail.id}/edit'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(context.tr('edit')),
                ),
              if (detail.status == ExamStatus.draft)
                FilledButton.icon(
                  onPressed: () => _publish(context, ref),
                  icon: const Icon(Icons.publish_rounded, size: 18),
                  label: Text(context.tr('exam_publish_action')),
                ),
              if (detail.status != ExamStatus.draft)
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/exams/${detail.id}/results'),
                  icon: const Icon(Icons.assessment_outlined, size: 18),
                  label: Text(context.tr('exam_results')),
                ),
              if (detail.status == ExamStatus.published)
                OutlinedButton.icon(
                  onPressed: () => _close(context, ref),
                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                  label: Text(context.tr('exam_close_action')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _publish(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(examRepositoryProvider).publishExam(detail.id);
      ref.invalidate(teacherExamProvider(detail.id));
      ref.invalidate(myExamsProvider);
      if (context.mounted) {
        context.showSuccessToast(context.tr('exam_published_toast'));
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        context.showErrorToast(context.tr(examErrorKey(error)));
      }
    }
  }

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('exam_close_confirm_title')),
        content: Text(context.tr('exam_close_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('exam_close_action')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final result = await ref.read(examRepositoryProvider).closeExam(detail.id);
      ref.invalidate(teacherExamProvider(detail.id));
      ref.invalidate(examResultsProvider(detail.id));
      ref.invalidate(myExamsProvider);
      if (context.mounted) {
        context.showSuccessToast(
          context.tr(
            'exam_closed_toast',
            args: <String, String>{
              'count': '${result.finalizedAttempts}',
            },
          ),
        );
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        context.showErrorToast(context.tr(examErrorKey(error)));
      }
    }
  }
}

class _AttemptsSection extends ConsumerWidget {
  const _AttemptsSection({required this.detail});

  final ExamDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(examResultsProvider(detail.id));
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('exam_attempts_title'),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (detail.status != ExamStatus.draft)
                TextButton(
                  onPressed: () =>
                      context.push('/exams/${detail.id}/results'),
                  child: Text(context.tr('exam_results')),
                ),
            ],
          ),
          const SizedBox(height: 8),
          results.when(
            loading: () => const Center(child: SmartLoader.small()),
            error: (error, _) => Text(
              context.tr(examErrorKey(error)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            data: (payload) {
              if (payload.results.isEmpty) {
                return Text(
                  context.tr('exam_attempts_empty'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              }
              return Column(
                children: [
                  for (final entry in payload.results)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          entry.studentName.isEmpty
                              ? '?'
                              : entry.studentName
                                    .characters
                                    .first
                                    .toUpperCase(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        entry.studentName.isEmpty
                            ? context.tr('exam_student_unknown')
                            : entry.studentName,
                      ),
                      subtitle: Text(
                        context.tr(
                          entry.violationCount > 0
                              ? 'exam_attempt_subtitle_violations'
                              : 'exam_attempt_subtitle_clean',
                          args: <String, String>{
                            'status': context.tr(attemptStatusKey(entry.status)),
                            'count': '${entry.violationCount}',
                          },
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (entry.score != null)
                            Text(
                              context.tr(
                                'exam_score_fraction',
                                args: <String, String>{
                                  'score': '${entry.score}',
                                  'max': '${entry.maxScore}',
                                },
                              ),
                              style: theme.textTheme.labelMedium,
                            ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      onTap: () => context.push(
                        '/exams/${detail.id}/attempts/${entry.attemptId}',
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CorrectionSection extends StatelessWidget {
  const _CorrectionSection({required this.detail});

  final ExamDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('exam_correction_title'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < detail.questions.length; index += 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      'exam_question_number',
                      args: <String, String>{'number': '${index + 1}'},
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail.questions[index].prompt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final option in detail.questions[index].options)
                        ExamTag(
                          labelKey: option.text,
                          icon: detail.questions[index].correctOptionIds
                                  .contains(option.id)
                              ? Icons.check_circle_rounded
                              : null,
                          tone: detail.questions[index].correctOptionIds
                                  .contains(option.id)
                              ? ExamTagTone.primary
                              : ExamTagTone.neutral,
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

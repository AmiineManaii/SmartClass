import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/exam_providers.dart';
import '../../domain/entities/exam_attempt.dart';
import '../../domain/entities/exam_definition.dart';
import '../widgets/exam_state_views.dart';
import '../widgets/exam_tag.dart';
import '../widgets/exam_ui.dart';

/// Teacher results for one exam. Scores and statuses are the server
/// projections; the page never computes a grade or estimates a missing one.
class ExamResultsPage extends ConsumerWidget {
  const ExamResultsPage({required this.examId, super.key});

  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(examResultsProvider(examId));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('exam_results')),
        actions: [
          IconButton(
            tooltip: context.tr('refresh'),
            onPressed: () {
              ref.invalidate(examResultsProvider(examId));
              ref.invalidate(teacherExamProvider(examId));
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: results.when(
        loading: () => const Center(child: SmartLoader()),
        error: (error, _) => ExamErrorView(
          errorKey: examErrorKey(error),
          detail: examErrorDetail(error),
          onRetry: () => ref.invalidate(examResultsProvider(examId)),
        ),
        data: (payload) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(examResultsProvider(examId));
            ref.invalidate(teacherExamProvider(examId));
          },
          child: ListView(
            padding: EdgeInsets.all(context.isDesktop ? 32 : 16),
            children: [
              _ResultsHeader(results: payload),
              const SizedBox(height: 16),
              if (payload.results.isEmpty)
                const ExamEmptyView(
                  icon: Icons.people_outline_rounded,
                  titleKey: 'exam_results_empty',
                  messageKey: 'exam_results_empty_hint',
                )
              else
                for (final entry in payload.results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ResultRow(examId: examId, entry: entry),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.results});

  final ExamResults results;

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
                labelKey: examStatusKey(results.status),
                tone: results.status == ExamStatus.draft
                    ? ExamTagTone.warning
                    : ExamTagTone.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            results.examTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Metric(
                icon: Icons.people_alt_outlined,
                labelKey: 'exam_results_attempts',
                value: '${results.attemptCount}',
              ),
              _Metric(
                icon: Icons.insights_rounded,
                labelKey: 'exam_results_average',
                value: results.averageScore == null
                    ? context.tr('exam_results_no_average')
                    : results.averageScore!.toStringAsFixed(1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.labelKey,
    required this.value,
  });

  final IconData icon;
  final String labelKey;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(labelKey),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.examId, required this.entry});

  final String examId;
  final ExamResultEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = entry.studentName.isEmpty
        ? '?'
        : entry.studentName.characters.first.toUpperCase();
    return AppCard(
      onTap: () =>
          context.push('/exams/$examId/attempts/${entry.attemptId}'),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Text(
              initial,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.studentName.isEmpty
                      ? context.tr('exam_student_unknown')
                      : entry.studentName,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ExamTag(
                      labelKey: attemptStatusKey(entry.status),
                      tone: entry.status == AttemptStatus.terminated
                          ? ExamTagTone.danger
                          : ExamTagTone.primary,
                    ),
                    if (entry.violationCount > 0)
                      ExamTag(
                        labelKey: 'exam_results_violations',
                        icon: Icons.warning_amber_rounded,
                        tone: ExamTagTone.warning,
                      ),
                    Text(
                      context.tr(
                        'exam_results_correct_count',
                        args: <String, String>{
                          'correct': '${entry.correctCount}',
                          'total': '${entry.questionCount}',
                        },
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (entry.submittedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                      'exam_results_submitted_at',
                      args: <String, String>{
                        'date': formatExamDateTime(
                          context,
                          entry.submittedAt!,
                        ),
                      },
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (entry.score != null)
            Text(
              context.tr(
                'exam_score_fraction',
                args: <String, String>{
                  'score': '${entry.score}',
                  'max': '${entry.maxScore}',
                },
              ),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

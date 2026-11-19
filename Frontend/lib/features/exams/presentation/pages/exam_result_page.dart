import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/exam_providers.dart';
import '../../domain/entities/exam_attempt.dart';
import '../widgets/exam_state_views.dart';
import '../widgets/exam_tag.dart';
import '../widgets/exam_ui.dart';

/// Student result, only after the backend releases it. The payload never
/// carries correct option ids or explanations, so the page can show
/// correctness but never the answer key.
class ExamResultPage extends ConsumerWidget {
  const ExamResultPage({required this.examId, super.key});

  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(studentResultProvider(examId));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('exam_result_title')),
        actions: [
          IconButton(
            tooltip: context.tr('refresh'),
            onPressed: () => ref.invalidate(studentResultProvider(examId)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: result.when(
        loading: () => const Center(child: SmartLoader()),
        error: (error, _) {
          if (error is ApiException &&
              error.code == 'EXAM_RESULTS_NOT_AVAILABLE') {
            return _NotReleasedView(
              detail: error.message,
              onRefresh: () =>
                  ref.invalidate(studentResultProvider(examId)),
            );
          }
          return ExamErrorView(
            errorKey: examErrorKey(error),
            detail: examErrorDetail(error),
            onRetry: () => ref.invalidate(studentResultProvider(examId)),
          );
        },
        data: (payload) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(studentResultProvider(examId)),
          child: ListView(
            padding: EdgeInsets.all(context.isDesktop ? 32 : 16),
            children: [
              _ResultHeader(result: payload),
              const SizedBox(height: 16),
              _ResultItems(result: payload),
              const SizedBox(height: 24),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/exams'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(context.tr('exam_attempt_back_to_exams')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotReleasedView extends StatelessWidget {
  const _NotReleasedView({this.detail, this.onRefresh});

  final String? detail;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_clock_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('exam_result_not_released_title'),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('exam_result_not_released_body'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRefresh != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.result});

  final StudentResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.examTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ExamTag(
                labelKey: attemptStatusKey(result.status),
                tone: result.status == AttemptStatus.terminated
                    ? ExamTagTone.danger
                    : ExamTagTone.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.score}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  '/ ${result.maxScore}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(
              'exam_result_correct_count',
              args: <String, String>{
                'correct': '${result.correctCount}',
                'total': '${result.questionCount}',
              },
            ),
            style: theme.textTheme.bodyMedium,
          ),
          if (result.submittedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              context.tr(
                'exam_result_submitted_at',
                args: <String, String>{
                  'date': formatExamDateTime(context, result.submittedAt!),
                },
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (result.terminatedReason != null) ...[
            const SizedBox(height: 10),
            Text(
              context.tr(
                'exam_monitoring_terminated_reason',
                args: <String, String>{
                  'reason': context.tr(
                    terminatedReasonKey(result.terminatedReason),
                  ),
                },
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            context.tr('exam_result_released_hint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultItems extends StatelessWidget {
  const _ResultItems({required this.result});

  final StudentResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('exam_result_questions_title'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          if (result.items.isEmpty)
            Text(
              context.tr('exam_result_no_items'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (var index = 0; index < result.items.length; index += 1)
              _ResultItemRow(number: index + 1, item: result.items[index]),
        ],
      ),
    );
  }
}

class _ResultItemRow extends StatelessWidget {
  const _ResultItemRow({required this.number, required this.item});

  final int number;
  final StudentResultItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            context.tr(
              'exam_question_number',
              args: <String, String>{'number': '$number'},
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          ExamTag(
            labelKey: item.correct
                ? 'exam_result_correct_tag'
                : 'exam_result_incorrect_tag',
            icon: item.correct
                ? Icons.check_circle_rounded
                : Icons.cancel_outlined,
            tone: item.correct ? ExamTagTone.primary : ExamTagTone.danger,
          ),
          const Spacer(),
          Text(
            context.tr(
              'exam_score_fraction',
              args: <String, String>{
                'score': '${item.pointsAwarded}',
                'max': '${item.pointsMax}',
              },
            ),
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

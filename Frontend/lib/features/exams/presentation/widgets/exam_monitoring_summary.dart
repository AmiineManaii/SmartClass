import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/exam_attempt.dart';
import '../../domain/entities/exam_definition.dart';
import '../../domain/entities/exam_monitoring.dart';
import 'exam_tag.dart';
import 'exam_ui.dart';

/// Attempt summary + corrected question sheet of the monitoring page.
class ExamMonitoringSummary extends StatelessWidget {
  const ExamMonitoringSummary({required this.monitoring, super.key});

  final AttemptMonitoring monitoring;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attempt = monitoring.attempt;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monitoring.examTitle,
            style: theme.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ExamTag(
                labelKey: attemptStatusKey(attempt.status),
                tone: attempt.status == AttemptStatus.terminated
                    ? ExamTagTone.danger
                    : ExamTagTone.primary,
              ),
              ExamTag(
                labelKey: 'exam_monitoring_violations',
                icon: Icons.warning_amber_rounded,
                tone: attempt.violationCount > 0
                    ? ExamTagTone.warning
                    : ExamTagTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            attempt.studentName.isEmpty
                ? context.tr('exam_student_unknown')
                : attempt.studentName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (attempt.terminatedReason != null) ...[
            const SizedBox(height: 8),
            Text(
              context.tr(
                'exam_monitoring_terminated_reason',
                args: <String, String>{
                  'reason': context.tr(
                    terminatedReasonKey(attempt.terminatedReason),
                  ),
                },
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _SummaryMeta(
                icon: Icons.play_circle_outline_rounded,
                labelKey: 'exam_monitoring_started',
                value: formatExamDateTime(context, attempt.startedAt),
              ),
              _SummaryMeta(
                icon: Icons.timer_outlined,
                labelKey: 'exam_monitoring_expires',
                value: formatExamDateTime(context, attempt.expiresAt),
              ),
              if (attempt.submittedAt != null)
                _SummaryMeta(
                  icon: Icons.check_circle_outline_rounded,
                  labelKey: 'exam_monitoring_submitted',
                  value: formatExamDateTime(context, attempt.submittedAt!),
                ),
              if (attempt.score != null)
                _SummaryMeta(
                  icon: Icons.emoji_events_outlined,
                  labelKey: 'exam_monitoring_score',
                  value: context.tr(
                    'exam_score_fraction',
                    args: <String, String>{
                      'score': '${attempt.score}',
                      'max': '${attempt.maxScore}',
                    },
                  ),
                ),
              _SummaryMeta(
                icon: Icons.help_outline_rounded,
                labelKey: 'exam_monitoring_violations_count',
                value: '${attempt.violationCount}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMeta extends StatelessWidget {
  const _SummaryMeta({
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
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(
          '${context.tr(labelKey)} · $value',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Teacher-only correction crossed with the answers actually saved.
class ExamMonitoringQuestions extends StatelessWidget {
  const ExamMonitoringQuestions({required this.monitoring, super.key});

  final AttemptMonitoring monitoring;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answers = <String, List<String>>{
      for (final answer in monitoring.attempt.answers)
        answer.questionId: answer.selectedOptionIds,
    };
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('exam_correction_title'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          for (var index = 0;
              index < monitoring.questions.length;
              index += 1)
            _CorrectedQuestion(
              number: index + 1,
              question: monitoring.questions[index],
              selected: answers[monitoring.questions[index].id] ??
                  const <String>[],
            ),
        ],
      ),
    );
  }
}

class _CorrectedQuestion extends StatelessWidget {
  const _CorrectedQuestion({
    required this.number,
    required this.question,
    required this.selected,
  });

  final int number;
  final TeacherQuestion question;
  final List<String> selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correctIds = question.correctOptionIds;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 2),
          Text(
            question.prompt,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (selected.isEmpty) ...[
            const SizedBox(height: 6),
            const ExamTag(
              labelKey: 'exam_monitoring_no_answer',
              tone: ExamTagTone.warning,
            ),
          ],
          const SizedBox(height: 6),
          for (final option in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    selected.contains(option.id)
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 16,
                    color: selected.contains(option.id)
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      option.text,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  if (correctIds.contains(option.id))
                    const ExamTag(
                      labelKey: 'exam_monitoring_correct_option',
                      icon: Icons.check_circle_rounded,
                      tone: ExamTagTone.primary,
                    ),
                  if (selected.contains(option.id))
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: ExamTag(
                        labelKey: 'exam_monitoring_selected_option',
                      ),
                    ),
                ],
              ),
            ),
          if (question.explanation != null &&
              question.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              context.tr(
                'exam_monitoring_explanation',
                args: <String, String>{'text': question.explanation!.trim()},
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

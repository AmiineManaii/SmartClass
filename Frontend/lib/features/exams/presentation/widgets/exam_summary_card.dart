import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/exam_attempt.dart';
import '../../domain/entities/exam_definition.dart';
import 'exam_tag.dart';
import 'exam_ui.dart';

/// Role-aware exam row. Every value comes from the backend projection; the
/// card never invents a score, a state or an availability.
class ExamSummaryCard extends StatelessWidget {
  const ExamSummaryCard({
    required this.exam,
    this.availability,
    this.attemptStatus,
    this.remainingMs,
    this.onTap,
    this.actions = const <Widget>[],
    super.key,
  });

  final ExamSummary exam;
  final ExamAvailability? availability;
  final AttemptStatus? attemptStatus;
  final int? remainingMs;
  final VoidCallback? onTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDraft = exam.status == ExamStatus.draft;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  examSourceIcon(exam.source),
                  color: scheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exam.className ??
                          context.tr('exam_class_unknown'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (attemptStatus != null)
                ExamTag(
                  labelKey: attemptStatusKey(attemptStatus!),
                  tone: attemptStatus == AttemptStatus.terminated
                      ? ExamTagTone.danger
                      : ExamTagTone.primary,
                )
              else
                ExamTag(
                  labelKey: availability == null
                      ? examStatusKey(exam.status)
                      : availabilityKey(availability!),
                  tone: isDraft ? ExamTagTone.warning : ExamTagTone.primary,
                ),
            ],
          ),
          if (exam.description != null && exam.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              exam.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Info(
                icon: Icons.event_rounded,
                label: formatExamDateTime(context, exam.startsAt),
              ),
              _Info(
                icon: Icons.access_time_rounded,
                label: context.tr(
                  'exam_minutes',
                  args: {'count': '${exam.durationMinutes}'},
                ),
              ),
              _Info(
                icon: Icons.help_outline_rounded,
                label: context.tr(
                  'exam_question_count',
                  args: {'count': '${exam.questionCount}'},
                ),
              ),
              _Info(
                icon: Icons.stars_rounded,
                label: context.tr(
                  'exam_points',
                  args: {'count': '${exam.totalPoints}'},
                ),
              ),
              if (remainingMs != null && remainingMs! > 0)
                _Info(
                  icon: Icons.timer_outlined,
                  label: context.tr(
                    'exam_time_left',
                    args: {'time': formatRemainingTime(remainingMs!)},
                  ),
                ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

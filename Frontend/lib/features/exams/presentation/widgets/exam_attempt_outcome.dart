import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';

/// Terminal attempt screen. It never displays a score: a result is only shown
/// by the dedicated result page once the backend releases it.
class ExamAttemptOutcome extends StatelessWidget {
  const ExamAttemptOutcome({
    required this.terminated,
    required this.autoSubmitted,
    required this.terminatedReasonKey,
    required this.onViewResult,
    required this.onBackToExams,
    super.key,
  });

  final bool terminated;
  final bool autoSubmitted;
  final String terminatedReasonKey;
  final VoidCallback onViewResult;
  final VoidCallback onBackToExams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  terminated
                      ? Icons.gpp_bad_outlined
                      : Icons.check_circle_outline_rounded,
                  size: 56,
                  color: terminated ? scheme.error : scheme.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr(
                    terminated
                        ? 'exam_attempt_terminated_title'
                        : 'exam_attempt_completed_title',
                  ),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (terminated)
                  Text(
                    context.tr(
                      'exam_attempt_terminated_body',
                      args: <String, String>{
                        'reason': context.tr(terminatedReasonKey),
                      },
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    context.tr(
                      autoSubmitted
                          ? 'exam_attempt_auto_submitted_body'
                          : 'exam_attempt_completed_body',
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 12),
                Text(
                  context.tr('exam_attempt_result_hint'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onViewResult,
                  icon: const Icon(Icons.assessment_outlined),
                  label: Text(context.tr('exam_view_result')),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onBackToExams,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(context.tr('exam_attempt_back_to_exams')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

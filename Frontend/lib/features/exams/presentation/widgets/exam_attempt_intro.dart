import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/exam_attempt.dart';

/// Pre-attempt briefing. Nothing is created server-side until the student
/// confirms: the button is what triggers the idempotent `POST /start`.
class ExamAttemptIntro extends StatelessWidget {
  const ExamAttemptIntro({
    required this.exam,
    required this.consent,
    required this.cameraConsent,
    required this.busy,
    required this.onConsentChanged,
    required this.onCameraConsentChanged,
    required this.onStart,
    super.key,
  });

  final AvailableExam? exam;
  final bool consent;
  final bool cameraConsent;
  final bool busy;
  final ValueChanged<bool> onConsentChanged;
  final ValueChanged<bool> onCameraConsentChanged;
  final VoidCallback onStart;

  bool get _cameraRequired => exam?.settings.requireCamera ?? false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canStart = consent && (!_cameraRequired || cameraConsent) && !busy;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('exam_attempt_intro_title'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (exam != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          exam!.title,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          exam!.className ??
                              context.tr('exam_class_unknown'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        context.tr('exam_attempt_intro_subtitle'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (exam != null) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _IntroMeta(
                              icon: Icons.access_time_rounded,
                              text: context.tr(
                                'exam_minutes',
                                args: <String, String>{
                                  'count': '${exam!.durationMinutes}',
                                },
                              ),
                            ),
                            _IntroMeta(
                              icon: Icons.help_outline_rounded,
                              text: context.tr(
                                'exam_question_count',
                                args: <String, String>{
                                  'count': '${exam!.questionCount}',
                                },
                              ),
                            ),
                            _IntroMeta(
                              icon: Icons.stars_rounded,
                              text: context.tr(
                                'exam_points',
                                args: <String, String>{
                                  'count': '${exam!.totalPoints}',
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('exam_attempt_rules_title'),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 10),
                      _Rule(
                        icon: Icons.timer_outlined,
                        textKey: 'exam_attempt_rule_timer',
                      ),
                      _Rule(
                        icon: Icons.fullscreen_rounded,
                        textKey: 'exam_attempt_rule_fullscreen',
                      ),
                      _Rule(
                        icon: Icons.exit_to_app_rounded,
                        textKey: 'exam_attempt_rule_leave',
                      ),
                      _Rule(
                        icon: Icons.content_copy_rounded,
                        textKey: 'exam_attempt_rule_copy',
                      ),
                      if (_cameraRequired)
                        _Rule(
                          icon: Icons.videocam_outlined,
                          textKey: 'exam_attempt_rule_camera',
                        ),
                      _Rule(
                        icon: Icons.screenshot_outlined,
                        textKey: 'exam_attempt_rule_screenshot',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: consent,
                  onChanged: busy
                      ? null
                      : (value) => onConsentChanged(value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.tr('exam_attempt_consent'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (_cameraRequired)
                  CheckboxListTile(
                    value: cameraConsent,
                    onChanged: busy
                        ? null
                        : (value) =>
                            onCameraConsentChanged(value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      context.tr('exam_attempt_camera_consent'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: canStart ? onStart : null,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    context.tr(
                      busy
                          ? 'exam_attempt_starting'
                          : exam?.canResume == true
                              ? 'exam_resume_action'
                              : 'start_exam',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('exam_attempt_intro_server_note'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroMeta extends StatelessWidget {
  const _IntroMeta({required this.icon, required this.text});

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

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.textKey});

  final IconData icon;
  final String textKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr(textKey),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

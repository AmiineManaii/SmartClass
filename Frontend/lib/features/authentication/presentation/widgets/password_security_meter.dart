import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

/// Segmented 4-bar password strength meter (mockup: `nouveau mot de passe`).
/// Score 0..4 → filled bars in tertiary. Label: Weak / Medium / Strong / Very strong.
class PasswordSecurityMeter extends StatelessWidget {
  final int score;

  const PasswordSecurityMeter({required this.score, super.key})
      : assert(score >= 0 && score <= 4);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final levelKey = switch (score) {
      <= 1 => 'strength_weak',
      2 => 'strength_medium',
      3 => 'strength_strong',
      _ => 'strength_very_strong',
    };
    final levelColor = switch (score) {
      <= 1 => colorScheme.error,
      2 => colorScheme.secondary,
      _ => colorScheme.tertiaryContainer,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('security_level'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: levelColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  context.tr(levelKey),
                  style: theme.textTheme.labelMedium?.copyWith(color: levelColor),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(4, (i) {
            final filled = i < score;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                decoration: BoxDecoration(
                  color: filled ? colorScheme.tertiaryFixed : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

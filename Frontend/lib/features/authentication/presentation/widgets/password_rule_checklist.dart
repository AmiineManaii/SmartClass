import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

/// Validation checklist for the new-password rules.
/// `met` must align with [PasswordRuleChecklist.ruleKeys] order.
class PasswordRuleChecklist extends StatelessWidget {
  final List<bool> met;

  const PasswordRuleChecklist({required this.met, super.key})
      : assert(met.length == 4);

  static const ruleKeys = [
    'rule_min_length',
    'rule_digit',
    'rule_uppercase',
    'rule_special',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow ?? colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: List.generate(ruleKeys.length, (i) {
          final ok = met[i];
          return Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
            child: Row(
              children: [
                Icon(
                  ok ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: ok ? colorScheme.tertiaryContainer : colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(ruleKeys[i]),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

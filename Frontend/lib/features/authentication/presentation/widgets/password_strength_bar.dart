import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({required this.password, super.key});

  double get _strength {
    if (password.isEmpty) return 0;
    if (password.length < 6) return 0.33;
    if (password.length < 10) return 0.66;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: _strength,
              minHeight: 4,
              backgroundColor: colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          context.tr('password_rule'),
          style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

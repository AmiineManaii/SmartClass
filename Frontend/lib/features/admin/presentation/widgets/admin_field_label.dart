import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

/// External field label with optional trailing hint (admin forms).
class AdminFieldLabel extends StatelessWidget {
  final String labelKey;
  final String? trailingKey;
  final bool showTrailing;
  final bool requiredStar;

  const AdminFieldLabel({
    required this.labelKey,
    this.trailingKey,
    this.showTrailing = false,
    this.requiredStar = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            children: [
              TextSpan(text: context.tr(labelKey)),
              if (requiredStar)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: colorScheme.error),
                ),
            ],
          ),
        ),
        if (showTrailing)
          Text(
            context.tr(trailingKey ?? 'admin_required'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.secondary,
            ),
          ),
      ],
    );
  }
}

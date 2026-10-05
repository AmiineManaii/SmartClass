import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class FieldLabel extends StatelessWidget {
  final String labelKey;
  final String? trailingKey;
  final bool showTrailing;

  const FieldLabel({
    required this.labelKey,
    this.trailingKey,
    this.showTrailing = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(labelKey.isEmpty ? '' : context.tr(labelKey), style: theme.textTheme.labelMedium),
        if (showTrailing)
          Text(
            context.tr(trailingKey ?? 'required_badge'),
            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
          ),
      ],
    );
  }
}

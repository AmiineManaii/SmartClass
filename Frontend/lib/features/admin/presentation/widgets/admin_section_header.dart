import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

/// Section title (+ optional subtitle) or title + trailing action link.
class AdminSectionHeader extends StatelessWidget {
  final String titleKey;
  final Map<String, String> titleArgs;
  final String? subtitleKey;
  final String? actionKey;
  final Map<String, String> actionArgs;
  final VoidCallback? onAction;

  const AdminSectionHeader({
    required this.titleKey,
    this.titleArgs = const {},
    this.subtitleKey,
    this.actionKey,
    this.actionArgs = const {},
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                context.tr(titleKey, args: titleArgs),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (actionKey != null)
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr(actionKey!, args: actionArgs),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward, size: 16, color: colorScheme.secondary),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (subtitleKey != null) ...[
          const SizedBox(height: 2),
          Text(
            context.tr(subtitleKey!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

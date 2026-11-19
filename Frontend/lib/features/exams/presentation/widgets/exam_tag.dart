import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

/// Small rounded label used for exam statuses, availability, severity and
/// event decisions. Colors always come from the active [ColorScheme].
class ExamTag extends StatelessWidget {
  const ExamTag({
    required this.labelKey,
    this.args,
    this.icon,
    this.tone = ExamTagTone.neutral,
    super.key,
  });

  final String labelKey;
  final Map<String, String>? args;
  final IconData? icon;
  final ExamTagTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = switch (tone) {
      ExamTagTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      ExamTagTone.primary => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      ExamTagTone.warning => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      ExamTagTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            context.tr(labelKey, args: args),
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum ExamTagTone { neutral, primary, warning, danger }

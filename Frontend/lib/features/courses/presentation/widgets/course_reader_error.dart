import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';

/// État d'erreur du lecteur de cours avec bouton de retry.
class CourseReaderError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const CourseReaderError({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('server_error'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: context.tr('retry'),
              onPressed: onRetry,
              isFullWidth: false,
              variant: AppButtonVariant.outlined,
            ),
          ],
        ),
      ),
    );
  }
}

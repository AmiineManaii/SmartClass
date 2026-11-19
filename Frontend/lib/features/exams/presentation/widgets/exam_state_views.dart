import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import 'exam_tag.dart';

/// Shared loading / error / empty presentation for the exam pages.
class ExamErrorView extends StatelessWidget {
  const ExamErrorView({
    required this.errorKey,
    this.detail,
    this.onRetry,
    super.key,
  });

  final String errorKey;
  final String? detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr(errorKey),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ExamEmptyView extends StatelessWidget {
  const ExamEmptyView({
    required this.icon,
    required this.titleKey,
    this.messageKey,
    this.action,
    super.key,
  });

  final IconData icon;
  final String titleKey;
  final String? messageKey;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 34,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(titleKey),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (messageKey != null) ...[
              const SizedBox(height: 6),
              Text(
                context.tr(messageKey!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class ExamTagRow extends StatelessWidget {
  const ExamTagRow({required this.tags, super.key});

  final List<ExamTag> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 6, runSpacing: 6, children: tags);
  }
}

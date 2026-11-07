part of '../widgets/teacher_dashboard_view.dart';
class _DashboardError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          context.tr('something_went_wrong'),
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(context.tr('retry')),
        ),
      ],
    );
  }
}


part of '../pages/admin_planning_page.dart';
class _BreakRow extends StatelessWidget {
  final PlannerEvent event;

  const _BreakRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.start,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (event.end.isNotEmpty)
                Text(
                  event.end,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Row(
            children: [
              Icon(
                event.kind == PlannerEventKind.lunch
                    ? Icons.restaurant_outlined
                    : Icons.local_cafe_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (event.noteDuration != null)
                Text(
                  event.noteDuration!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}


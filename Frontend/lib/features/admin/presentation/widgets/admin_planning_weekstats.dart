part of '../pages/admin_planning_page.dart';
class _WeekStats extends StatelessWidget {
  final String hours;
  final int conflicts;

  const _WeekStats({required this.hours, required this.conflicts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget item(IconData icon, Color color, String text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          item(
            Icons.schedule_rounded,
            colorScheme.secondary,
            context.tr('admin_hours_scheduled', args: {'hours': hours}),
          ),
          item(
            conflicts == 0
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            conflicts == 0 ? colorScheme.tertiary : colorScheme.error,
            context.tr('admin_no_conflict', args: {'count': '$conflicts'}),
          ),
        ],
      ),
    );
  }
}


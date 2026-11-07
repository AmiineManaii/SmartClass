part of '../pages/admin_planning_page.dart';
class _DayCell extends StatelessWidget {
  final DateTime date;
  final PlannerDay day;
  final bool selected;
  final String localeTag;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.day,
    required this.selected,
    required this.localeTag,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEE', localeTag).format(date).toUpperCase();
    final sub = context.tr(
      'admin_day_courses',
      args: {'count': '${day.courseCount}'},
    );

    return Material(
      color: selected
          ? colorScheme.primary
          : colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                dayName.length > 3 ? dayName.substring(0, 3) : dayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${date.day}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.onPrimary.withValues(alpha: 0.2)
                      : colorScheme.secondaryFixed,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  sub,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSecondaryFixed,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


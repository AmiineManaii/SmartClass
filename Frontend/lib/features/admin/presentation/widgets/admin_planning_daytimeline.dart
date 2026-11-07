part of '../pages/admin_planning_page.dart';
class _DayTimeline extends StatelessWidget {
  final DateTime monday;
  final int selectedDay;
  final List<PlannerEvent> events;
  final String localeTag;
  final VoidCallback onTakeAttendance;
  final VoidCallback onReserve;

  const _DayTimeline({
    required this.monday,
    required this.selectedDay,
    required this.events,
    required this.localeTag,
    required this.onTakeAttendance,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = monday.add(Duration(days: selectedDay));
    final dayKey = DateFormat('yyyy-MM-dd').format(date);
    final dayEvents = events
        .where((e) => e.date.isEmpty || e.date == dayKey)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.tr('admin_day_planning'),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            Text(
              DateFormat('EEEE d MMM', localeTag).format(date).toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (dayEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              context.tr('admin_no_timetable'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final event in dayEvents) ...[
            _TimelineRow(
              event: event,
              onTakeAttendance: onTakeAttendance,
              onReserve: onReserve,
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}


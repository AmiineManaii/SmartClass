part of '../pages/admin_planning_page.dart';
class _TimelineRow extends StatelessWidget {
  final PlannerEvent event;
  final VoidCallback onTakeAttendance;
  final VoidCallback onReserve;

  const _TimelineRow({
    required this.event,
    required this.onTakeAttendance,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (event.kind == PlannerEventKind.pause ||
        event.kind == PlannerEventKind.lunch) {
      return _BreakRow(event: event);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  fontWeight: FontWeight.w600,
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
        Container(
          width: 3,
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: event.kind == PlannerEventKind.free
              ? _FreeSlotCard(event: event, onReserve: onReserve)
              : _SessionCard(event: event, onTakeAttendance: onTakeAttendance),
        ),
      ],
    );
  }
}


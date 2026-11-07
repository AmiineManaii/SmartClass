part of '../pages/admin_planning_page.dart';
class _TypeChip extends StatelessWidget {
  final PlannerEventKind kind;

  const _TypeChip({required this.kind});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (IconData icon, String labelKey) = switch (kind) {
      PlannerEventKind.cm => (Icons.auto_stories_outlined, 'admin_event_cm'),
      PlannerEventKind.tp => (Icons.terminal_rounded, 'admin_event_tp'),
      PlannerEventKind.td => (Icons.assignment_outlined, 'admin_event_td'),
      _ => (Icons.event_outlined, 'admin_event_cm'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.secondary),
          const SizedBox(width: 4),
          Text(
            context.tr(labelKey),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


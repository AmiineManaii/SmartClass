part of '../pages/admin_planning_page.dart';
class _FreeSlotCard extends StatelessWidget {
  final PlannerEvent event;
  final VoidCallback onReserve;

  const _FreeSlotCard({required this.event, required this.onReserve});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 16,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('admin_free_slot'),
                    style: theme.textTheme.labelLarge,
                  ),
                ],
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
          const SizedBox(height: 4),
          Text(
            context.tr('admin_free_desc'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (event.roomValue != null)
                Text(
                  context.tr(
                    'admin_room_available',
                    args: {'room': event.roomValue!},
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.secondary,
                  ),
                )
              else
                const Spacer(),
              OutlinedButton.icon(
                onPressed: onReserve,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(context.tr('admin_book')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  textStyle: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

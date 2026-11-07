part of '../pages/admin_planning_page.dart';
class _SessionCard extends StatelessWidget {
  final PlannerEvent event;
  final VoidCallback onTakeAttendance;

  const _SessionCard({required this.event, required this.onTakeAttendance});

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
          _TypeChip(kind: event.kind),
          const SizedBox(height: 8),
          Text(event.title, style: theme.textTheme.headlineSmall),
          if (event.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              event.subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (event.teacherName != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryFixed,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: event.teacherInitials == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: colorScheme.onSecondaryFixed,
                        )
                      : Text(
                          event.teacherInitials!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryFixed,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.teacherName!,
                        style: theme.textTheme.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.teacherRole != null)
                        Text(
                          event.teacherRole!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (event.roomValue != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 14,
                          color: colorScheme.secondary,
                        ),
                        Text(
                          event.roomValue!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (event.statusLines.isNotEmpty || event.statusNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final line in event.statusLines)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _StatusLine(textKey: line),
              ),
            for (final note in event.statusNotes)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _RawStatusLine(text: note),
              ),
          ],
          if (event.actionKey != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTakeAttendance,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr(event.actionKey!),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: colorScheme.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


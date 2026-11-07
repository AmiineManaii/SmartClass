part of '../widgets/student_dashboard_view.dart';
class _DailyScheduleCard extends ConsumerWidget {
  const _DailyScheduleCard();

  Color _kindColor(ColorScheme colorScheme, String? kind) {
    switch (kind) {
      case 'CM':
        return colorScheme.primary;
      case 'TD':
        return colorScheme.secondary;
      case 'TP':
        return colorScheme.tertiary;
      default:
        return colorScheme.primary;
    }
  }

  ({int h, int m}) _parseTime(String? value) {
    final parts = (value ?? '').split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return (h: h, m: m);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final async = ref.watch(studentDayTimetableProvider);
    final events = async.valueOrNull ?? const <Map<String, dynamic>>[];
    final now = TimeOfDay.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Planning du jour',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.tr(
                    'dashboard_sessions_count',
                    args: {'count': '${events.length}'},
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryFixed,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (async.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('dashboard_no_sessions'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...events.asMap().entries.expand((entry) {
              final i = entry.key;
              final e = entry.value;
              final start = _parseTime(e['start'] as String?);
              final end = _parseTime(e['end'] as String?);
              final startMinutes = start.h * 60 + start.m;
              final endMinutes = end.h * 60 + end.m;
              final nowMinutes = now.hour * 60 + now.minute;
              final isCurrent =
                  nowMinutes >= startMinutes && nowMinutes < endMinutes;
              final teacher =
                  (e['teacher'] is Map && (e['teacher'] as Map)['name'] != null)
                  ? '${(e['teacher'] as Map)['name']}'
                  : '';
              final room = e['room']?.toString() ?? '';
              final subtitle = [
                if (teacher.isNotEmpty) teacher,
                if (room.isNotEmpty) room,
                if (e['kind'] != null) '${e['kind']}',
              ].join(' â€¢ ');
              final slot = _ScheduleSlot(
                time: '${e['start'] ?? ''} - ${e['end'] ?? ''}',
                subject: '${e['title'] ?? ''}',
                location: isCurrent
                    ? '${context.tr('dashboard_live_now')} ðŸ”´'
                    : subtitle,
                color: _kindColor(colorScheme, e['kind'] as String?),
                isCurrent: isCurrent,
              );
              return i == 0 ? [slot] : [const SizedBox(height: 10), slot];
            }),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.push('/videoconference'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Consulter l\'emploi du temps complet',
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: colorScheme.secondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


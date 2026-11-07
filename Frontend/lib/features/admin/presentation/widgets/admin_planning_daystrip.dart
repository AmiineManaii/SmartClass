part of '../pages/admin_planning_page.dart';
class _DayStrip extends StatelessWidget {
  final DateTime monday;
  final List<PlannerDay> days;
  final int selectedDay;
  final String localeTag;
  final ValueChanged<int> onSelect;

  const _DayStrip({
    required this.monday,
    required this.days,
    required this.selectedDay,
    required this.localeTag,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        for (int i = 0; i < days.length; i++) ...[
          Expanded(
            child: _DayCell(
              date: monday.add(Duration(days: i)),
              day: days[i],
              selected: i == selectedDay,
              localeTag: localeTag,
              colorScheme: colorScheme,
              theme: theme,
              onTap: () => onSelect(i),
            ),
          ),
          if (i < days.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}


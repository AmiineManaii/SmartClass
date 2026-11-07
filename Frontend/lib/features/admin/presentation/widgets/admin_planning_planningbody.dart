part of '../pages/admin_planning_page.dart';
class _PlanningBody extends StatelessWidget {
  final PlannerWeek week;
  final AdminClassSummary? selectedClass;
  final int weekOffset;
  final int selectedDay;
  final String localeTag;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onToday;
  final ValueChanged<int> onSelectDay;
  final VoidCallback onTakeAttendance;
  final VoidCallback onReserve;
  final VoidCallback onNewSlot;

  const _PlanningBody({
    required this.week,
    required this.selectedClass,
    required this.weekOffset,
    required this.selectedDay,
    required this.localeTag,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onToday,
    required this.onSelectDay,
    required this.onTakeAttendance,
    required this.onReserve,
    required this.onNewSlot,
  });

  @override
  Widget build(BuildContext context) {
    final monday = week.monday.add(Duration(days: weekOffset * 7));
    final friday = monday.add(const Duration(days: 4));
    final range =
        '${DateFormat('d', localeTag).format(monday)} - ${DateFormat('d MMM y', localeTag).format(friday)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PromoCard(selectedClass: selectedClass),
        const SizedBox(height: 12),
        _WeekNavigator(
          range: range,
          onPrev: onPrevWeek,
          onNext: onNextWeek,
          onToday: onToday,
        ),
        const SizedBox(height: 12),
        _DayStrip(
          monday: monday,
          days: week.days,
          selectedDay: selectedDay,
          localeTag: localeTag,
          onSelect: onSelectDay,
        ),
        const SizedBox(height: 12),
        _WeekStats(hours: week.hoursScheduled, conflicts: week.conflicts),
        const SizedBox(height: 20),
        _DayTimeline(
          monday: monday,
          selectedDay: selectedDay,
          events: week.events,
          localeTag: localeTag,
          onTakeAttendance: onTakeAttendance,
          onReserve: onReserve,
        ),
        const SizedBox(height: 96),
      ],
    );
  }
}


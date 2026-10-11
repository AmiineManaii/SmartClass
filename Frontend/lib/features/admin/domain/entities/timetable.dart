/// Timetable / planning models (pure Dart).
///
/// Backend endpoints: none yet (videoconference/courses modules planned).
enum PlannerEventKind { cm, tp, td, pause, lunch, free }

class PlannerDay {
  final DateTime date;
  final int courseCount;
  final bool isMakeup;
  final bool isToday;

  const PlannerDay({
    required this.date,
    required this.courseCount,
    this.isMakeup = false,
    this.isToday = false,
  });
}

class PlannerEvent {
  final String id;
  final String start;
  final String end;
  final PlannerEventKind kind;
  final String title;
  final String? subtitle;
  final String? teacherName;
  final String? teacherRole;
  final String? teacherInitials;
  final String? roomKey;
  final String? roomValue;
  final List<String> statusLines;
  final String? actionKey;
  final String? note;
  final String? noteDuration;

  const PlannerEvent({
    required this.id,
    required this.start,
    required this.end,
    required this.kind,
    required this.title,
    this.subtitle,
    this.teacherName,
    this.teacherRole,
    this.teacherInitials,
    this.roomKey,
    this.roomValue,
    this.statusLines = const [],
    this.actionKey,
    this.note,
    this.noteDuration,
  });
}

class PlannerWeek {
  final DateTime monday;
  final List<PlannerDay> days;
  final String hoursScheduled;
  final int conflicts;
  final int ratePct;
  final List<PlannerEvent> events;

  const PlannerWeek({
    required this.monday,
    required this.days,
    required this.hoursScheduled,
    required this.conflicts,
    required this.ratePct,
    required this.events,
  });
}

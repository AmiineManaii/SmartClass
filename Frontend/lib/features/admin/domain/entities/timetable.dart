/// Timetable / planning models (pure Dart).
///
/// Shapes mirror `contracts/videoconference.openapi.yaml` (TimetableWeek).
/// Week statistics (hours, conflicts) are computed from the real events;
/// no fill-rate figure exists server-side, so none is modelled here.
enum PlannerEventKind { cm, tp, td, pause, lunch, free }

class PlannerDay {
  final DateTime date;
  final int courseCount;
  final bool isToday;

  const PlannerDay({
    required this.date,
    required this.courseCount,
    this.isToday = false,
  });
}

class PlannerEvent {
  final String id;

  /// ISO day (YYYY-MM-DD) the event belongs to, for day filtering.
  final String date;
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

  /// Legacy i18n status keys (kept for compatibility, unused by the API).
  final List<String> statusLines;

  /// Raw backend status notes, displayed verbatim.
  final List<String> statusNotes;
  final String? actionKey;
  final String? note;
  final String? noteDuration;

  const PlannerEvent({
    required this.id,
    this.date = '',
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
    this.statusNotes = const [],
    this.actionKey,
    this.note,
    this.noteDuration,
  });
}

class PlannerWeek {
  final DateTime monday;
  final List<PlannerDay> days;

  /// Computed total course time, e.g. "7h30".
  final String hoursScheduled;

  /// Computed same-day overlap count between course events.
  final int conflicts;
  final List<PlannerEvent> events;

  const PlannerWeek({
    required this.monday,
    required this.days,
    required this.hoursScheduled,
    required this.conflicts,
    required this.events,
  });
}

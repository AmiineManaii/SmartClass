/// A live course session scheduled for today, shown with a join CTA.
///
/// Pure Dart — no Flutter dependency.
///
/// Source of truth (planned): today's-course calendar endpoint
/// (videoconference module, contract not yet written). Until it lands,
/// [studentTodayLiveProvider] resolves to `null` and the dashboard hides
/// the live widget instead of showing invented sessions.
class TodayLiveSession {
  final String id;
  final String subject;
  final String instructor;
  final String chapter;
  final String time;
  final int minutesRemaining;
  final List<String> attendeesInitials;
  final int extraAttendeesCount;

  const TodayLiveSession({
    required this.id,
    required this.subject,
    required this.instructor,
    required this.chapter,
    required this.time,
    required this.minutesRemaining,
    this.attendeesInitials = const [],
    this.extraAttendeesCount = 0,
  });
}

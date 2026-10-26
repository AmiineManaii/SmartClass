import '../../../videoconference/domain/entities/video_session.dart';

/// A live course session scheduled for today, shown with a join CTA.
///
/// Pure Dart — no Flutter dependency.
///
/// Fed reactively by `nextSessionFeedProvider` from the videoconference module.
class TodayLiveSession {
  final String id;
  final String subject;
  final String instructor;
  final String chapter;
  final String time;
  final int minutesRemaining;
  final List<String> attendeesInitials;
  final int extraAttendeesCount;
  final VideoSession? videoSession;
  final Duration serverOffset;

  const TodayLiveSession({
    required this.id,
    required this.subject,
    required this.instructor,
    required this.chapter,
    required this.time,
    required this.minutesRemaining,
    this.attendeesInitials = const [],
    this.extraAttendeesCount = 0,
    this.videoSession,
    this.serverOffset = Duration.zero,
  });
}

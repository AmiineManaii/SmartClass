import 'video_session.dart';

enum SessionPhase {
  upcoming,
  joinOpen,
  live,
  ended,
  canceled;
}

SessionPhase phaseOf(
  VideoSession session,
  DateTime now, {
  Duration serverOffset = Duration.zero,
}) {
  if (session.status == VideoSessionStatus.canceled) {
    return SessionPhase.canceled;
  }
  if (session.status == VideoSessionStatus.completed) {
    return SessionPhase.ended;
  }

  final effectiveNow = now.add(serverOffset);

  // If time has passed the end of the session, it's ended
  if (effectiveNow.isAfter(session.endsAt) ||
      effectiveNow.isAtSameMomentAs(session.endsAt)) {
    return SessionPhase.ended;
  }

  if (session.status == VideoSessionStatus.inProgress) {
    return SessionPhase.live;
  }

  final joinOpensAt = session.joinOpensAt;
  if (effectiveNow.isAfter(joinOpensAt) ||
      effectiveNow.isAtSameMomentAs(joinOpensAt)) {
    return SessionPhase.joinOpen;
  }

  return SessionPhase.upcoming;
}

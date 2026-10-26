import 'package:flutter_test/flutter_test.dart';
import 'package:smartclass/features/videoconference/domain/entities/session_phase.dart';
import 'package:smartclass/features/videoconference/domain/entities/video_session.dart';

void main() {
  group('SessionPhase - phaseOf', () {
    final baseStart = DateTime.utc(2026, 10, 25, 14, 0, 0);
    final baseEnd = DateTime.utc(2026, 10, 25, 15, 0, 0);

    VideoSession createSession({
      VideoSessionStatus status = VideoSessionStatus.scheduled,
      int joinOpensMinutesBefore = 5,
      DateTime? startsAt,
      DateTime? endsAt,
    }) {
      return VideoSession(
        id: 'session-1',
        classGroupId: 'class-1',
        title: 'Mathématiques - Analyse',
        status: status,
        startsAt: startsAt ?? baseStart,
        endsAt: endsAt ?? baseEnd,
        joinOpensMinutesBefore: joinOpensMinutesBefore,
        createdAt: DateTime.utc(2026, 10, 20),
        updatedAt: DateTime.utc(2026, 10, 20),
      );
    }

    test('returns canceled when status is canceled regardless of time', () {
      final session = createSession(status: VideoSessionStatus.canceled);
      final phase = phaseOf(session, baseStart.add(const Duration(minutes: 10)));
      expect(phase, SessionPhase.canceled);
    });

    test('returns ended when status is completed regardless of time', () {
      final session = createSession(status: VideoSessionStatus.completed);
      final phase = phaseOf(session, baseStart);
      expect(phase, SessionPhase.ended);
    });

    test('returns live when status is inProgress regardless of scheduled bounds', () {
      final session = createSession(status: VideoSessionStatus.inProgress);
      final phase = phaseOf(session, baseStart.subtract(const Duration(hours: 1)));
      expect(phase, SessionPhase.live);
    });

    test('returns upcoming when now is before join window', () {
      final session = createSession(joinOpensMinutesBefore: 10);
      // 15 minutes before start (join window is 10 mins before)
      final now = baseStart.subtract(const Duration(minutes: 15));
      expect(phaseOf(session, now), SessionPhase.upcoming);
    });

    test('returns joinOpen when now is exactly at joinOpensAt', () {
      final session = createSession(joinOpensMinutesBefore: 10);
      final now = baseStart.subtract(const Duration(minutes: 10));
      expect(phaseOf(session, now), SessionPhase.joinOpen);
    });

    test('returns joinOpen when now is between joinOpensAt and startsAt', () {
      final session = createSession(joinOpensMinutesBefore: 10);
      final now = baseStart.subtract(const Duration(minutes: 3));
      expect(phaseOf(session, now), SessionPhase.joinOpen);
    });

    test('returns joinOpen when now is between startsAt and endsAt while still scheduled', () {
      final session = createSession();
      final now = baseStart.add(const Duration(minutes: 20));
      expect(phaseOf(session, now), SessionPhase.joinOpen);
    });

    test('returns ended when now is after endsAt', () {
      final session = createSession();
      final now = baseEnd.add(const Duration(seconds: 1));
      expect(phaseOf(session, now), SessionPhase.ended);
    });

    test('correctly applies serverOffset for skewed client clock', () {
      final session = createSession(joinOpensMinutesBefore: 5);
      // Client clock is 10 minutes fast (shows 13:58, but server is 13:48)
      final clientNow = baseStart.subtract(const Duration(minutes: 2));
      final serverOffset = const Duration(minutes: -10);

      // Effective server time is 13:48, which is before the 5 min window (13:55)
      expect(phaseOf(session, clientNow, serverOffset: serverOffset),
          SessionPhase.upcoming);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartclass/core/localization/app_localizations.dart';
import 'package:smartclass/features/home/domain/entities/today_live_session.dart';
import 'package:smartclass/features/home/presentation/widgets/student_imminent_live_card.dart';
import 'package:smartclass/features/home/presentation/widgets/teacher_imminent_live_card.dart';
import 'package:smartclass/features/videoconference/domain/entities/video_session.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  final baseSession = VideoSession(
    id: 'sess-live-widget-1',
    classGroupId: 'class-1',
    hostId: 'teacher-euler',
    hostName: 'Professeur Euler',
    subject: 'Mathématiques',
    title: 'Topologie Algébrique',
    startsAt: DateTime.now().add(const Duration(minutes: 30)),
    endsAt: DateTime.now().add(const Duration(minutes: 90)),
    status: VideoSessionStatus.scheduled,
    joinOpensMinutesBefore: 15,
    chatEnabled: true,
    participantCount: 12,
    className: 'Master 1 Math',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('StudentImminentLiveCard Tests', () {
    testWidgets('Upcoming phase: Join button is disabled with countdown', (tester) async {
      // Starts in 30 min, join opens 15 min before -> 15 min until join opens
      final upcomingSession = baseSession.copyWith(
        startsAt: DateTime.now().add(const Duration(minutes: 30)),
        endsAt: DateTime.now().add(const Duration(minutes: 90)),
        status: VideoSessionStatus.scheduled,
      );

      final todaySession = TodayLiveSession(
        id: upcomingSession.id,
        subject: upcomingSession.subject ?? '',
        instructor: upcomingSession.hostName ?? '',
        chapter: upcomingSession.title,
        time: '14:00 - 15:30',
        minutesRemaining: 30,
        videoSession: upcomingSession,
      );

      var joinTapped = false;

      await tester.pumpWidget(wrapWidget(
        StudentImminentLiveCard(
          session: todaySession,
          onJoin: () => joinTapped = true,
        ),
      ));

      await tester.pump();

      expect(find.text('Mathématiques'), findsOneWidget);
      expect(find.text('Bientôt disponible'), findsOneWidget);

      // Verify button is disabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      // Tap disabled button does not trigger callback
      await tester.tap(find.byType(ElevatedButton));
      expect(joinTapped, false);
    });

    testWidgets('JoinOpen phase: Join button is enabled and taps callback', (tester) async {
      // Starts in 5 min, join opens 15 min before -> Join is already open!
      final joinOpenSession = baseSession.copyWith(
        startsAt: DateTime.now().add(const Duration(minutes: 5)),
        endsAt: DateTime.now().add(const Duration(minutes: 65)),
        status: VideoSessionStatus.scheduled,
      );

      final todaySession = TodayLiveSession(
        id: joinOpenSession.id,
        subject: joinOpenSession.subject ?? '',
        instructor: joinOpenSession.hostName ?? '',
        chapter: joinOpenSession.title,
        time: '14:00 - 15:00',
        minutesRemaining: 5,
        videoSession: joinOpenSession,
      );

      var joinTapped = false;

      await tester.pumpWidget(wrapWidget(
        StudentImminentLiveCard(
          session: todaySession,
          onJoin: () => joinTapped = true,
        ),
      ));

      await tester.pump();

      expect(find.text('ACCÈS OUVERT'), findsOneWidget);
      expect(find.text('Rejoindre le sas'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);

      await tester.tap(find.byType(ElevatedButton));
      expect(joinTapped, true);
    });

    testWidgets('Live phase: Live badge and Join Live button enabled', (tester) async {
      final liveSession = baseSession.copyWith(
        startsAt: DateTime.now().subtract(const Duration(minutes: 10)),
        endsAt: DateTime.now().add(const Duration(minutes: 50)),
        status: VideoSessionStatus.inProgress,
      );

      final todaySession = TodayLiveSession(
        id: liveSession.id,
        subject: liveSession.subject ?? '',
        instructor: liveSession.hostName ?? '',
        chapter: liveSession.title,
        time: '14:00 - 15:00',
        minutesRemaining: 0,
        videoSession: liveSession,
      );

      var joinTapped = false;

      await tester.pumpWidget(wrapWidget(
        StudentImminentLiveCard(
          session: todaySession,
          onJoin: () => joinTapped = true,
        ),
      ));

      await tester.pump();

      expect(find.text('En direct'), findsOneWidget);
      expect(find.text('Rejoindre le Live'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      expect(joinTapped, true);
    });
  });

  group('TeacherImminentLiveCard Tests', () {
    testWidgets('JoinOpen phase shows Démarrer la session button', (tester) async {
      final joinOpenSession = baseSession.copyWith(
        startsAt: DateTime.now().add(const Duration(minutes: 5)),
        endsAt: DateTime.now().add(const Duration(minutes: 65)),
        status: VideoSessionStatus.scheduled,
      );

      await tester.pumpWidget(wrapWidget(
        TeacherImminentLiveCard(session: joinOpenSession),
      ));

      await tester.pump();

      expect(find.text('ACCÈS OUVERT'), findsOneWidget);
      expect(find.text('Master 1 Math'), findsOneWidget);
      expect(find.text('Démarrer la session'), findsOneWidget);
    });

    testWidgets('Live phase shows Rejoindre le cours button and EN DIRECT badge', (tester) async {
      final liveSession = baseSession.copyWith(
        startsAt: DateTime.now().subtract(const Duration(minutes: 10)),
        endsAt: DateTime.now().add(const Duration(minutes: 50)),
        status: VideoSessionStatus.inProgress,
      );

      await tester.pumpWidget(wrapWidget(
        TeacherImminentLiveCard(session: liveSession),
      ));

      await tester.pump();

      expect(find.text('En direct'), findsOneWidget);
      expect(find.text('Rejoindre le cours'), findsOneWidget);
    });

    testWidgets('Ended phase: TeacherImminentLiveCard is removed and renders nothing', (tester) async {
      final endedSession = baseSession.copyWith(
        startsAt: DateTime.now().subtract(const Duration(minutes: 60)),
        endsAt: DateTime.now().subtract(const Duration(minutes: 10)),
        status: VideoSessionStatus.completed,
      );

      await tester.pumpWidget(wrapWidget(
        TeacherImminentLiveCard(session: endedSession),
      ));

      await tester.pump();

      // Card is completely removed from view
      expect(find.text('Topologie Algébrique'), findsNothing);
      expect(find.text('Démarrer la session'), findsNothing);
      expect(find.text('Rejoindre le sas'), findsNothing);
      expect(find.byType(TeacherImminentLiveCard), findsOneWidget);
    });
  });
}

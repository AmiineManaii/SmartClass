import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartclass/app/app_providers.dart';
import 'package:smartclass/core/localization/app_localizations.dart';
import 'package:smartclass/features/videoconference/application/live_room_controller.dart';
import 'package:smartclass/features/videoconference/application/videoconference_providers.dart';
import 'package:smartclass/features/videoconference/domain/entities/join_token.dart';
import 'package:smartclass/features/videoconference/domain/entities/live_participant.dart';
import 'package:smartclass/features/videoconference/domain/entities/room_connection_state.dart';
import 'package:smartclass/features/videoconference/domain/entities/session_chat_message.dart';
import 'package:smartclass/features/videoconference/domain/entities/session_event.dart';
import 'package:smartclass/features/videoconference/domain/entities/video_session.dart';
import 'package:smartclass/features/videoconference/domain/ports/room_port.dart';
import 'package:smartclass/features/videoconference/domain/repositories/videoconference_repository.dart';
import 'package:smartclass/features/videoconference/presentation/pages/live_room_page.dart';
import 'package:smartclass/features/videoconference/presentation/pages/lobby_page.dart';
import 'package:smartclass/features/videoconference/presentation/views/mobile_live_room_view.dart';
import 'package:smartclass/features/videoconference/presentation/views/web_live_room_view.dart';

class _FakeAuthNotifier extends StateNotifier<AsyncValue<AuthState>>
    implements AuthNotifier {
  _FakeAuthNotifier(String role)
      : super(AsyncValue.data(AuthState(
          isAuthenticated: true,
          role: role,
        )));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRoomPort implements RoomPort {
  final _connectionStateCtrl = StreamController<RoomConnectionState>.broadcast();
  final _participantJoinedCtrl = StreamController<LiveParticipant>.broadcast();
  final _participantLeftCtrl = StreamController<String>.broadcast();
  final _participantUpdatedCtrl = StreamController<LiveParticipant>.broadcast();
  final _activeSpeakerCtrl = StreamController<String>.broadcast();
  final _dataMessageCtrl = StreamController<Map<String, dynamic>>.broadcast();

  RoomConnectionState _state = RoomConnectionState.disconnected;

  @override
  RoomConnectionState get connectionState => _state;
  @override
  Stream<RoomConnectionState> get connectionStateStream => _connectionStateCtrl.stream;
  @override
  Stream<LiveParticipant> get participantJoinedStream => _participantJoinedCtrl.stream;
  @override
  Stream<String> get participantLeftStream => _participantLeftCtrl.stream;
  @override
  Stream<LiveParticipant> get participantUpdatedStream => _participantUpdatedCtrl.stream;
  @override
  Stream<String> get activeSpeakerStream => _activeSpeakerCtrl.stream;
  @override
  Stream<Map<String, dynamic>> get dataMessageStream => _dataMessageCtrl.stream;

  @override
  Future<void> connect(String url, String token) async {
    _state = RoomConnectionState.connected;
    _connectionStateCtrl.add(RoomConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    _state = RoomConnectionState.disconnected;
    _connectionStateCtrl.add(RoomConnectionState.disconnected);
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {}
  @override
  Future<void> setCameraEnabled(bool enabled) async {}
  @override
  Future<void> setScreenShareEnabled(bool enabled) async {}
  @override
  Future<void> flipCamera() async {}
  @override
  Future<void> sendData(List<int> data, {String? topic}) async {}
  @override
  void dispose() {
    _connectionStateCtrl.close();
    _participantJoinedCtrl.close();
    _participantLeftCtrl.close();
    _participantUpdatedCtrl.close();
    _activeSpeakerCtrl.close();
    _dataMessageCtrl.close();
  }
}

class _FakeVideoconferenceRepository implements VideoconferenceRepository {
  final VideoSession session;

  _FakeVideoconferenceRepository({required this.session});

  @override
  Future<VideoSession> getSession(String id) async => session;

  @override
  Future<JoinToken> getJoinToken(String id) async => JoinToken(
        token: 'fake.jwt.token',
        url: 'wss://livekit.smartclass.local',
        roomName: 'room-$id',
        role: 'TEACHER',
        permissions: const SessionPermissions(
          canPublishAudio: true,
          canPublishVideo: true,
          canPublishScreen: true,
          canModerate: true,
        ),
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );

  @override
  Future<List<SessionChatMessage>> listChatMessages(String id, {String? before, int limit = 50}) async => [];

  @override
  Stream<SessionEvent> streamEvents() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testScheduledSession = VideoSession(
    id: 'session-lobby-1',
    classGroupId: 'class-math-1',
    hostId: 'teacher-id',
    hostName: 'Professeur Euler',
    subject: 'Mathématiques',
    title: 'Topologie Algébrique',
    startsAt: DateTime.now().add(const Duration(minutes: 10)),
    endsAt: DateTime.now().add(const Duration(minutes: 70)),
    status: VideoSessionStatus.scheduled,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    chatEnabled: true,
    className: 'Master 1 Info',
  );

  final testLiveSession = VideoSession(
    id: 'session-live-1',
    classGroupId: 'class-math-1',
    hostId: 'teacher-id',
    hostName: 'Professeur Euler',
    subject: 'Mathématiques',
    title: 'Topologie Algébrique',
    startsAt: DateTime.now().subtract(const Duration(minutes: 10)),
    endsAt: DateTime.now().add(const Duration(minutes: 50)),
    status: VideoSessionStatus.inProgress,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    chatEnabled: true,
    className: 'Master 1 Info',
  );

  Widget createTestWidget({
    required Widget child,
    required String role,
    required VideoSession session,
    RoomPort? roomPort,
    Size size = const Size(1280, 800),
  }) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => _FakeAuthNotifier(role)),
        videoconferenceRepositoryProvider
            .overrideWithValue(_FakeVideoconferenceRepository(session: session)),
        roomPortProvider.overrideWithValue(roomPort ?? _FakeRoomPort()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: child,
      ),
    );
  }

  group('LobbyPage Widget Tests', () {
    testWidgets('LobbyPage displays session details and camera/mic toggle buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        child: const LobbyPage(sessionId: 'session-lobby-1'),
        role: 'TEACHER',
        session: testScheduledSession,
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Topologie Algébrique'), findsOneWidget);
      expect(find.text('Master 1 Info'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

      // Tap mic button to toggle
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
    });

    testWidgets('LobbyPage shows teacher Start Session button when scheduled',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        child: const LobbyPage(sessionId: 'session-lobby-1'),
        role: 'TEACHER',
        session: testScheduledSession,
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Démarrer la session'), findsOneWidget);
    });

    testWidgets('LobbyPage shows student waiting indicator when scheduled',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        child: const LobbyPage(sessionId: 'session-lobby-1'),
        role: 'STUDENT',
        session: testScheduledSession,
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('En attente de l\'hôte'), findsOneWidget);
      expect(find.text('Démarrer la session'), findsNothing);
    });
  });

  group('LiveRoomPage Widget Tests', () {
    testWidgets('LiveRoomPage displays WebLiveRoomView on large screen',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        child: const LiveRoomPage(sessionId: 'session-live-1'),
        role: 'TEACHER',
        session: testLiveSession,
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(WebLiveRoomView), findsOneWidget);
      expect(find.byType(MobileLiveRoomView), findsNothing);
    });

    testWidgets('LiveRoomPage displays MobileLiveRoomView on small screen',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        child: const LiveRoomPage(sessionId: 'session-live-1'),
        role: 'STUDENT',
        session: testLiveSession,
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(MobileLiveRoomView), findsOneWidget);
      expect(find.byType(WebLiveRoomView), findsNothing);
    });
  });
}

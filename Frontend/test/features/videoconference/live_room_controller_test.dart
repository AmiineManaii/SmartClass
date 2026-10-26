import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartclass/features/videoconference/application/live_room_controller.dart';
import 'package:smartclass/features/videoconference/application/videoconference_providers.dart';
import 'package:smartclass/features/videoconference/domain/entities/join_token.dart';
import 'package:smartclass/features/videoconference/domain/entities/live_participant.dart';
import 'package:smartclass/features/videoconference/domain/entities/room_connection_state.dart';
import 'package:smartclass/features/videoconference/domain/entities/screen_annotation.dart';
import 'package:smartclass/features/videoconference/domain/entities/session_chat_message.dart';
import 'package:smartclass/features/videoconference/domain/entities/video_session.dart';
import 'package:smartclass/features/videoconference/domain/ports/room_port.dart';
import 'package:smartclass/features/videoconference/domain/repositories/videoconference_repository.dart';

class FakeRoomPort implements RoomPort {
  final _connectionStateCtrl = StreamController<RoomConnectionState>.broadcast();
  final _participantJoinedCtrl = StreamController<LiveParticipant>.broadcast();
  final _participantLeftCtrl = StreamController<String>.broadcast();
  final _participantUpdatedCtrl = StreamController<LiveParticipant>.broadcast();
  final _activeSpeakerCtrl = StreamController<String>.broadcast();
  final _dataMessageCtrl = StreamController<Map<String, dynamic>>.broadcast();

  RoomConnectionState _state = RoomConnectionState.disconnected;
  bool connected = false;
  String? connectedUrl;
  String? connectedToken;
  bool micEnabled = false;
  bool cameraEnabled = false;
  bool screenShareEnabled = false;
  bool flippedCamera = false;
  List<List<int>> sentData = [];

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

  void emitConnectionState(RoomConnectionState state) {
    _state = state;
    _connectionStateCtrl.add(state);
  }

  void emitParticipantJoined(LiveParticipant p) => _participantJoinedCtrl.add(p);
  void emitParticipantLeft(String identity) => _participantLeftCtrl.add(identity);
  void emitParticipantUpdated(LiveParticipant p) => _participantUpdatedCtrl.add(p);
  void emitActiveSpeaker(String identity) => _activeSpeakerCtrl.add(identity);
  void emitDataMessage(Map<String, dynamic> data) => _dataMessageCtrl.add(data);

  @override
  Future<void> connect(String url, String token) async {
    connected = true;
    connectedUrl = url;
    connectedToken = token;
    emitConnectionState(RoomConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    connected = false;
    emitConnectionState(RoomConnectionState.disconnected);
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    micEnabled = enabled;
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    cameraEnabled = enabled;
  }

  @override
  Future<void> setScreenShareEnabled(bool enabled) async {
    screenShareEnabled = enabled;
  }

  @override
  Future<void> flipCamera() async {
    flippedCamera = true;
  }

  @override
  Future<void> sendData(List<int> data, {String? topic}) async {
    sentData.add(data);
  }

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

class FakeVideoconferenceRepository implements VideoconferenceRepository {
  final VideoSession mockSession;
  final JoinToken mockJoinToken;
  List<SessionChatMessage> messages = [];
  bool endSessionCalled = false;
  bool leaveSessionCalled = false;
  bool muteAllCalled = false;

  FakeVideoconferenceRepository({
    required this.mockSession,
    required this.mockJoinToken,
  });

  @override
  Future<VideoSession> getSession(String id) async => mockSession;

  @override
  Future<JoinToken> getJoinToken(String id) async => mockJoinToken;

  @override
  Future<List<SessionChatMessage>> listChatMessages(
    String sessionId, {
    String? before,
    int limit = 50,
  }) async =>
      messages;

  @override
  Future<SessionChatMessage> sendChatMessage(String sessionId, {required String content}) async {
    final msg = SessionChatMessage(
      id: 'msg-${messages.length + 1}',
      sessionId: sessionId,
      senderId: 'user-me',
      senderDisplayName: 'Test Teacher',
      senderRole: 'TEACHER',
      content: content,
      createdAt: DateTime.now(),
    );
    messages.add(msg);
    return msg;
  }

  @override
  Future<void> leaveSession(String sessionId) async {
    leaveSessionCalled = true;
  }

  @override
  Future<VideoSession> endSession(String sessionId) async {
    endSessionCalled = true;
    return mockSession;
  }

  @override
  Future<void> muteAll(String sessionId, {bool mute = true}) async {
    muteAllCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummySession = VideoSession(
    id: 'session-123',
    classGroupId: 'class-1',
    hostId: 'teacher-1',
    hostName: 'Professeur Turing',
    subject: 'Mathématiques',
    title: 'Algèbre Linéaire',
    startsAt: DateTime.now().add(const Duration(minutes: 5)),
    endsAt: DateTime.now().add(const Duration(minutes: 65)),
    status: VideoSessionStatus.inProgress,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    chatEnabled: true,
  );

  final dummyJoinToken = JoinToken(
    token: 'jwt.token.here',
    url: 'wss://livekit.smartclass.local',
    roomName: 'room-session-123',
    role: 'TEACHER',
    permissions: const SessionPermissions(
      canPublishAudio: true,
      canPublishVideo: true,
      canPublishScreen: true,
      canModerate: true,
    ),
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
  );

  late FakeRoomPort fakeRoomPort;
  late FakeVideoconferenceRepository fakeRepo;
  late ProviderContainer container;
  late ProviderSubscription subscription;

  setUp(() {
    fakeRoomPort = FakeRoomPort();
    fakeRepo = FakeVideoconferenceRepository(
      mockSession: dummySession,
      mockJoinToken: dummyJoinToken,
    );

    container = ProviderContainer(
      overrides: [
        roomPortProvider.overrideWithValue(fakeRoomPort),
        videoconferenceRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    subscription = container.listen(liveRoomControllerProvider, (_, next) {});
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  test('LiveRoomController joins room and updates connection state to connected', () async {
    final controller = container.read(liveRoomControllerProvider.notifier);
    expect(container.read(liveRoomControllerProvider).connectionState, RoomConnectionState.disconnected);

    await controller.joinRoom('session-123', initialMic: true, initialCamera: false);

    final state = container.read(liveRoomControllerProvider);
    expect(state.connectionState, RoomConnectionState.connected);
    expect(state.session?.id, 'session-123');
    expect(state.joinToken?.token, 'jwt.token.here');
    expect(state.isMicEnabled, true);
    expect(state.isCameraEnabled, false);
    expect(fakeRoomPort.connected, true);
    expect(fakeRoomPort.connectedUrl, 'wss://livekit.smartclass.local');
  });

  test('LiveRoomController tracks participant join, update, active speaker, and leave', () async {
    final controller = container.read(liveRoomControllerProvider.notifier);
    await controller.joinRoom('session-123');

    // Remote participant joins
    final remoteP = LiveParticipant(
      identity: 'student-42',
      name: 'Alice Student',
      isLocal: false,
      isHost: false,
      isAudioMuted: false,
      isVideoMuted: false,
      isScreenSharing: false,
      isSpeaking: false,
      joinedAt: DateTime.now(),
    );
    fakeRoomPort.emitParticipantJoined(remoteP);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(liveRoomControllerProvider).remoteParticipants.containsKey('student-42'), true);

    // Active speaker changes
    fakeRoomPort.emitActiveSpeaker('student-42');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(liveRoomControllerProvider).activeSpeakerIdentity, 'student-42');
    expect(container.read(liveRoomControllerProvider).activeSpeaker?.identity, 'student-42');

    // Hand raise via data channel
    fakeRoomPort.emitDataMessage({
      'type': 'raise_hand',
      'identity': 'student-42',
      'raised': true,
    });
    await Future<void>.delayed(Duration.zero);
    expect(container.read(liveRoomControllerProvider).raisedHands.contains('student-42'), true);

    // Participant leaves
    fakeRoomPort.emitParticipantLeft('student-42');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(liveRoomControllerProvider).remoteParticipants.containsKey('student-42'), false);
    expect(container.read(liveRoomControllerProvider).raisedHands.contains('student-42'), false);
  });

  test('LiveRoomController sends chat message and appends to local list', () async {
    final controller = container.read(liveRoomControllerProvider.notifier);
    await controller.joinRoom('session-123');

    await controller.sendChatMessage('Bonjour la classe!');
    final state = container.read(liveRoomControllerProvider);
    expect(state.chatMessages.length, 1);
    expect(state.chatMessages.first.content, 'Bonjour la classe!');
  });

  test('LiveRoomController leaveRoom disconnects and notifies repository', () async {
    final controller = container.read(liveRoomControllerProvider.notifier);
    await controller.joinRoom('session-123');

    await controller.leaveRoom();
    expect(container.read(liveRoomControllerProvider).connectionState, RoomConnectionState.disconnected);
    expect(fakeRepo.leaveSessionCalled, true);
  });

  test('LiveRoomController manages screen share permissions and presenter roles', () async {
    final controller = container.read(liveRoomControllerProvider.notifier);
    await controller.joinRoom('session-123');

    // Host initially can share screen, students cannot
    expect(container.read(liveRoomControllerProvider).isHost, true);
    expect(container.read(liveRoomControllerProvider).canShareScreen, true);

    // Host allows students to share screen
    controller.setAllowStudentsScreenShare(true);
    expect(container.read(liveRoomControllerProvider).allowStudentsScreenShare, true);

    // Host designates student-42 as presenter
    controller.togglePresenter('student-42');
    expect(container.read(liveRoomControllerProvider).presenterIdentities.contains('student-42'), true);

    // Toggling again removes presenter role
    controller.togglePresenter('student-42');
    expect(container.read(liveRoomControllerProvider).presenterIdentities.contains('student-42'), false);
  });

  test('LiveRoomController manages co-annotation and interactive pointer (Option A)', () async {
    final controller = container.read(liveRoomControllerProvider.notifier);
    await controller.joinRoom('session-123');

    // Host can annotate by default
    expect(container.read(liveRoomControllerProvider).canAnnotate, true);

    // Host grants control to Alice
    controller.giveAnnotationControl('student-42', targetName: 'Alice');
    expect(container.read(liveRoomControllerProvider).activeControllerIdentity, 'student-42');
    expect(container.read(liveRoomControllerProvider).activeControllerName, 'Alice');

    // Add annotation stroke locally
    final stroke = AnnotationStroke(
      id: 'stroke-1',
      authorIdentity: 'user-1',
      authorName: 'Prof',
      colorValue: 0xFFFF0000,
      strokeWidth: 3.0,
      points: const [
        AnnotationPoint(0.1, 0.1),
        AnnotationPoint(0.2, 0.2),
      ],
    );
    controller.addAnnotationStroke(stroke);
    expect(container.read(liveRoomControllerProvider).annotationStrokes.length, 1);

    // Clear annotations
    controller.clearAnnotations();
    expect(container.read(liveRoomControllerProvider).annotationStrokes.isEmpty, true);

    // Host revokes control
    controller.giveAnnotationControl(null);
    expect(container.read(liveRoomControllerProvider).activeControllerIdentity, null);
  });

  test('LiveRoomController receives screen permission and annotation packets via data channel', () async {
    final controller = container.read(liveRoomControllerProvider.notifier);
    await controller.joinRoom('session-123');

    // Simulate remote permission broadcast
    fakeRoomPort.emitDataMessage({
      'type': 'screen_permission_update',
      'allowStudents': true,
      'presenters': ['student-42', 'student-99'],
    });
    await Future<void>.delayed(Duration.zero);

    var state = container.read(liveRoomControllerProvider);
    expect(state.allowStudentsScreenShare, true);
    expect(state.presenterIdentities, contains('student-42'));

    // Simulate remote grant control broadcast
    fakeRoomPort.emitDataMessage({
      'type': 'grant_control',
      'targetIdentity': 'student-42',
      'targetName': 'Alice',
    });
    await Future<void>.delayed(Duration.zero);

    state = container.read(liveRoomControllerProvider);
    expect(state.activeControllerIdentity, 'student-42');
    expect(state.activeControllerName, 'Alice');

    // Simulate remote pointer move
    fakeRoomPort.emitDataMessage({
      'type': 'pointer_move',
      'identity': 'student-42',
      'name': 'Alice',
      'x': 0.45,
      'y': 0.75,
    });
    await Future<void>.delayed(Duration.zero);

    state = container.read(liveRoomControllerProvider);
    expect(state.livePointers.containsKey('student-42'), true);
    expect(state.livePointers['student-42']!.x, 0.45);
    expect(state.livePointers['student-42']!.y, 0.75);
  });
}


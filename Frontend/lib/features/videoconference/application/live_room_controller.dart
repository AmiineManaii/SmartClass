import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/services/sound_effect_service.dart';
import '../domain/entities/join_token.dart';
import '../domain/entities/live_participant.dart';
import '../domain/entities/room_connection_state.dart';
import '../domain/entities/screen_annotation.dart';
import '../domain/entities/session_chat_message.dart';
import '../domain/entities/session_event.dart';
import '../domain/entities/video_session.dart';
import '../domain/ports/room_port.dart';
import '../domain/repositories/videoconference_repository.dart';
import '../infrastructure/adapters/livekit_room_adapter.dart';
import '../infrastructure/models/session_chat_message_model.dart';
import 'videoconference_providers.dart';

final roomPortProvider = Provider<RoomPort>((ref) {
  final adapter = LiveKitRoomAdapter();
  ref.onDispose(() {
    adapter.dispose();
  });
  return adapter;
});

class HandRaiseNotice {
  final String identity;
  final String displayName;
  final bool isRaised;
  final DateTime timestamp;

  const HandRaiseNotice({
    required this.identity,
    required this.displayName,
    required this.isRaised,
    required this.timestamp,
  });
}

class LiveRoomState {
  final VideoSession? session;
  final JoinToken? joinToken;
  final RoomConnectionState connectionState;
  final LiveParticipant? localParticipant;
  final Map<String, LiveParticipant> remoteParticipants;
  final String? activeSpeakerIdentity;
  final Set<String> raisedHands;
  final List<SessionChatMessage> chatMessages;
  final bool isChatOpen;
  final bool isParticipantsOpen;
  final int unreadChatCount;
  final bool isMicEnabled;
  final bool isCameraEnabled;
  final bool isScreenSharing;
  final bool isHandRaised;
  final HandRaiseNotice? latestHandRaise;
  final String? errorMessage;

  // Screen share & co-annotation features
  final bool allowStudentsScreenShare;
  final Set<String> presenterIdentities;
  final bool isAnnotationActive;
  final String? activeControllerIdentity;
  final String? activeControllerName;
  final Map<String, LivePointerState> livePointers;
  final List<AnnotationStroke> annotationStrokes;
  final AnnotationToolMode currentToolMode;
  final int currentAnnotationColor;

  const LiveRoomState({
    this.session,
    this.joinToken,
    this.connectionState = RoomConnectionState.disconnected,
    this.localParticipant,
    this.remoteParticipants = const {},
    this.activeSpeakerIdentity,
    this.raisedHands = const {},
    this.chatMessages = const [],
    this.isChatOpen = false,
    this.isParticipantsOpen = false,
    this.unreadChatCount = 0,
    this.isMicEnabled = false,
    this.isCameraEnabled = false,
    this.isScreenSharing = false,
    this.isHandRaised = false,
    this.latestHandRaise,
    this.errorMessage,
    this.allowStudentsScreenShare = false,
    this.presenterIdentities = const {},
    this.isAnnotationActive = false,
    this.activeControllerIdentity,
    this.activeControllerName,
    this.livePointers = const {},
    this.annotationStrokes = const [],
    this.currentToolMode = AnnotationToolMode.pointer,
    this.currentAnnotationColor = 0xFFEF4444,
  });

  bool get isHost {
    final role = joinToken?.role.toLowerCase();
    return role == 'host' || role == 'teacher' || role == 'admin';
  }

  bool get canShareScreen {
    if (isHost) return true;
    if (allowStudentsScreenShare) return true;
    final myId = localParticipant?.identity;
    if (myId != null && presenterIdentities.contains(myId)) return true;
    return false;
  }

  bool get canPublishScreen => canShareScreen;

  bool get canAnnotate {
    if (isHost) return true;
    if (activeControllerIdentity == 'all') return true;
    final myId = localParticipant?.identity;
    return myId != null && activeControllerIdentity == myId;
  }

  LiveParticipant? get screenSharingParticipant {
    if (localParticipant?.isScreenSharing == true) return localParticipant;
    for (final p in remoteParticipants.values) {
      if (p.isScreenSharing) return p;
    }
    return null;
  }

  LiveParticipant? get activeSpeaker {
    if (activeSpeakerIdentity == null) {
      if (remoteParticipants.isNotEmpty) return remoteParticipants.values.first;
      return localParticipant;
    }
    if (localParticipant?.identity == activeSpeakerIdentity) {
      return localParticipant;
    }
    return remoteParticipants[activeSpeakerIdentity] ??
        (remoteParticipants.isNotEmpty
            ? remoteParticipants.values.first
            : localParticipant);
  }

  LiveRoomState copyWith({
    VideoSession? session,
    JoinToken? joinToken,
    RoomConnectionState? connectionState,
    LiveParticipant? localParticipant,
    Map<String, LiveParticipant>? remoteParticipants,
    String? activeSpeakerIdentity,
    Set<String>? raisedHands,
    List<SessionChatMessage>? chatMessages,
    bool? isChatOpen,
    bool? isParticipantsOpen,
    int? unreadChatCount,
    bool? isMicEnabled,
    bool? isCameraEnabled,
    bool? isScreenSharing,
    bool? isHandRaised,
    HandRaiseNotice? latestHandRaise,
    String? errorMessage,
    bool? allowStudentsScreenShare,
    Set<String>? presenterIdentities,
    bool? isAnnotationActive,
    String? activeControllerIdentity,
    String? activeControllerName,
    bool clearActiveController = false,
    Map<String, LivePointerState>? livePointers,
    List<AnnotationStroke>? annotationStrokes,
    AnnotationToolMode? currentToolMode,
    int? currentAnnotationColor,
  }) {
    return LiveRoomState(
      session: session ?? this.session,
      joinToken: joinToken ?? this.joinToken,
      connectionState: connectionState ?? this.connectionState,
      localParticipant: localParticipant ?? this.localParticipant,
      remoteParticipants: remoteParticipants ?? this.remoteParticipants,
      activeSpeakerIdentity:
          activeSpeakerIdentity ?? this.activeSpeakerIdentity,
      raisedHands: raisedHands ?? this.raisedHands,
      chatMessages: chatMessages ?? this.chatMessages,
      isChatOpen: isChatOpen ?? this.isChatOpen,
      isParticipantsOpen: isParticipantsOpen ?? this.isParticipantsOpen,
      unreadChatCount: unreadChatCount ?? this.unreadChatCount,
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      latestHandRaise: latestHandRaise ?? this.latestHandRaise,
      errorMessage: errorMessage ?? this.errorMessage,
      allowStudentsScreenShare:
          allowStudentsScreenShare ?? this.allowStudentsScreenShare,
      presenterIdentities: presenterIdentities ?? this.presenterIdentities,
      isAnnotationActive: isAnnotationActive ?? this.isAnnotationActive,
      activeControllerIdentity: clearActiveController
          ? null
          : (activeControllerIdentity ?? this.activeControllerIdentity),
      activeControllerName: clearActiveController
          ? null
          : (activeControllerName ?? this.activeControllerName),
      livePointers: livePointers ?? this.livePointers,
      annotationStrokes: annotationStrokes ?? this.annotationStrokes,
      currentToolMode: currentToolMode ?? this.currentToolMode,
      currentAnnotationColor:
          currentAnnotationColor ?? this.currentAnnotationColor,
    );
  }
}

class LiveRoomController extends StateNotifier<LiveRoomState> {
  final Ref _ref;
  final RoomPort _roomPort;
  final VideoconferenceRepository _repository;

  final List<StreamSubscription> _subscriptions = [];
  ProviderSubscription<AsyncValue<SessionEvent>>? _eventsSubscription;

  LiveRoomController(this._ref, this._roomPort, this._repository)
      : super(const LiveRoomState()) {
    _listenToRoomEvents();
    _listenToSseEvents();
  }

  void _listenToRoomEvents() {
    _subscriptions.add(_roomPort.connectionStateStream.listen((connState) {
      state = state.copyWith(connectionState: connState);
    }));

    _subscriptions.add(_roomPort.participantJoinedStream.listen((participant) {
      if (participant.isLocal) {
        state = state.copyWith(localParticipant: participant);
      } else {
        final remotes = Map<String, LiveParticipant>.from(state.remoteParticipants);
        remotes[participant.identity] = participant;
        state = state.copyWith(remoteParticipants: remotes);
      }
    }));

    _subscriptions.add(_roomPort.participantLeftStream.listen((identity) {
      final remotes = Map<String, LiveParticipant>.from(state.remoteParticipants);
      remotes.remove(identity);
      final raised = Set<String>.from(state.raisedHands)..remove(identity);
      state = state.copyWith(
        remoteParticipants: remotes,
        raisedHands: raised,
      );
    }));

    _subscriptions.add(_roomPort.participantUpdatedStream.listen((participant) {
      if (participant.isLocal) {
        state = state.copyWith(
          localParticipant: participant,
          isScreenSharing: participant.isScreenSharing,
        );
      } else {
        final remotes = Map<String, LiveParticipant>.from(state.remoteParticipants);
        remotes[participant.identity] = participant;
        state = state.copyWith(remoteParticipants: remotes);
      }
    }));

    _subscriptions.add(_roomPort.activeSpeakerStream.listen((identity) {
      state = state.copyWith(activeSpeakerIdentity: identity);
    }));

    _subscriptions.add(_roomPort.dataMessageStream.listen((data) {
      final type = data['type'] as String?;
      if (type == 'raise_hand') {
        final id = data['identity'] as String?;
        final raised = data['raised'] == true;
        final name = (data['name'] as String?) ??
            state.remoteParticipants[id]?.name ??
            'Participant';
        if (id != null) {
          final updated = Set<String>.from(state.raisedHands);
          if (raised) {
            updated.add(id);
          } else {
            updated.remove(id);
          }
          state = state.copyWith(
            raisedHands: updated,
            latestHandRaise: HandRaiseNotice(
              identity: id,
              displayName: name,
              isRaised: raised,
              timestamp: DateTime.now(),
            ),
          );
        }
      } else if (type == 'chat_message') {
        final rawMsg = data['message'];
        if (rawMsg is Map) {
          final msg = SessionChatMessageModel.fromJson(
            Map<String, dynamic>.from(rawMsg),
          );
          _addIncomingChatMessage(msg);
        }
      } else if (type == 'screen_permission_update') {
        final allowStudents = data['allowStudents'] == true;
        final presentersList = (data['presenters'] as List?)?.cast<String>() ?? [];
        state = state.copyWith(
          allowStudentsScreenShare: allowStudents,
          presenterIdentities: presentersList.toSet(),
        );
      } else if (type == 'grant_control') {
        final targetId = data['targetIdentity'] as String?;
        final targetName = data['targetName'] as String?;
        if (targetId == null) {
          state = state.copyWith(
            clearActiveController: true,
            isAnnotationActive: false,
          );
        } else {
          state = state.copyWith(
            activeControllerIdentity: targetId,
            activeControllerName: targetName,
            isAnnotationActive: true,
          );
        }
      } else if (type == 'pointer_move') {
        final id = data['identity'] as String? ?? '';
        final name = data['name'] as String? ?? 'Participant';
        final x = (data['x'] as num).toDouble();
        final y = (data['y'] as num).toDouble();
        final colorVal = data['color'] as int? ?? 0xFFEF4444;
        final pointers = Map<String, LivePointerState>.from(state.livePointers);
        pointers[id] = LivePointerState(
          identity: id,
          name: name,
          x: x,
          y: y,
          color: Color(colorVal),
          updatedAt: DateTime.now(),
        );
        state = state.copyWith(livePointers: pointers);
      } else if (type == 'annotation_stroke') {
        final strokeMap = data['stroke'];
        if (strokeMap is Map) {
          final stroke = AnnotationStroke.fromJson(Map<String, dynamic>.from(strokeMap));
          state = state.copyWith(
            annotationStrokes: [...state.annotationStrokes, stroke],
          );
        }
      } else if (type == 'annotation_clear') {
        state = state.copyWith(
          annotationStrokes: const [],
          livePointers: const {},
        );
      }
    }));
  }

  void _addIncomingChatMessage(SessionChatMessage msg) {
    if (msg.id.isEmpty) return;
    if (!state.chatMessages.any((m) => m.id == msg.id)) {
      final newUnread = state.isChatOpen ? 0 : state.unreadChatCount + 1;
      state = state.copyWith(
        chatMessages: [...state.chatMessages, msg],
        unreadChatCount: newUnread,
      );
    }
  }

  void _listenToSseEvents() {
    _eventsSubscription = _ref.listen<AsyncValue<SessionEvent>>(
      liveEventsStreamProvider,
      (_, next) {
        final event = next.valueOrNull;
        if (event == null || event.sessionId != state.session?.id) return;

        if (event.type == 'session.ended') {
          state = state.copyWith(connectionState: RoomConnectionState.endedByHost);
          WakelockPlus.disable().catchError((_) {});
        } else if (event.type == 'session.chat-message-created') {
          final raw = event.data;
          final msgMap = raw['message'] is Map
              ? Map<String, dynamic>.from(raw['message'] as Map)
              : raw;
          if (msgMap.isNotEmpty && (msgMap['id'] != null || msgMap['content'] != null)) {
            final msg = SessionChatMessageModel.fromJson(msgMap);
            _addIncomingChatMessage(msg);
          }
        } else if (event.type == 'session.chat-settings-updated') {
          final enabled = event.data['chatEnabled'] != false;
          if (state.session != null) {
            state = state.copyWith(
              session: VideoSession(
                id: state.session!.id,
                classGroupId: state.session!.classGroupId,
                hostId: state.session!.hostId,
                hostName: state.session!.hostName,
                subject: state.session!.subject,
                title: state.session!.title,
                description: state.session!.description,
                startsAt: state.session!.startsAt,
                endsAt: state.session!.endsAt,
                startedAt: state.session!.startedAt,
                endedAt: state.session!.endedAt,
                status: state.session!.status,
                joinOpensMinutesBefore: state.session!.joinOpensMinutesBefore,
                chatEnabled: enabled,
                createdAt: state.session!.createdAt,
                updatedAt: state.session!.updatedAt,
                className: state.session!.className,
                participantCount: state.session!.participantCount,
              ),
            );
          }
        }
      },
    );
  }

  String _resolveLiveKitUrl(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl);
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        final apiUri = Uri.parse(ApiConfig.baseUrl);
        if (apiUri.host.isNotEmpty &&
            apiUri.host != 'localhost' &&
            apiUri.host != '127.0.0.1') {
          return uri.replace(host: apiUri.host).toString();
        }
      }
    } catch (_) {}
    return rawUrl;
  }

  Future<void> joinRoom(
    String sessionId, {
    bool? initialMic,
    bool? initialCamera,
  }) async {
    state = state.copyWith(
      connectionState: RoomConnectionState.connecting,
      errorMessage: null,
    );

    try {
      // 1. Fetch Session and Join Token
      final session = await _repository.getSession(sessionId);
      final joinToken = await _repository.getJoinToken(sessionId);

      state = state.copyWith(
        session: session,
        joinToken: joinToken,
      );

      // 2. Enable Wakelock
      await WakelockPlus.enable().catchError((_) {});

      // 3. Connect LiveKit
      final resolvedUrl = _resolveLiveKitUrl(joinToken.url);
      debugPrint('[LiveRoomController] Connecting to LiveKit at: $resolvedUrl');
      await _roomPort.connect(resolvedUrl, joinToken.token);

      // 4. Initial Media Tracks (strictly respect settings from the lobby)
      final shouldEnableMic = initialMic ?? state.isHost;
      final shouldEnableCamera = initialCamera ?? state.isHost;
      debugPrint('[LiveRoomController] Initial media applied: mic=$shouldEnableMic, cam=$shouldEnableCamera');

      try {
        await _roomPort.setMicrophoneEnabled(shouldEnableMic);
        state = state.copyWith(isMicEnabled: shouldEnableMic);
      } catch (e) {
        debugPrint('[LiveRoomController] Initial mic error: $e');
      }

      try {
        await _roomPort.setCameraEnabled(shouldEnableCamera);
        state = state.copyWith(isCameraEnabled: shouldEnableCamera);
      } catch (e) {
        debugPrint('[LiveRoomController] Initial camera error: $e');
      }

      // 5. Initial Chat History (non-fatal)
      try {
        final history = await _repository.listChatMessages(sessionId);
        state = state.copyWith(chatMessages: history);
      } catch (e) {
        debugPrint('[LiveRoomController] Initial chat history error (non-fatal): $e');
      }
    } catch (e) {
      debugPrint('[LiveRoomController] Join error: $e');
      state = state.copyWith(
        connectionState: RoomConnectionState.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> toggleMicrophone() async {
    final next = !state.isMicEnabled;
    state = state.copyWith(isMicEnabled: next);
    try {
      await _roomPort.setMicrophoneEnabled(next);
    } catch (e) {
      debugPrint('[LiveRoomController] Mic error: $e');
      state = state.copyWith(isMicEnabled: !next);
    }
  }

  Future<void> toggleCamera() async {
    final next = !state.isCameraEnabled;
    state = state.copyWith(isCameraEnabled: next);
    try {
      await _roomPort.setCameraEnabled(next);
    } catch (e) {
      debugPrint('[LiveRoomController] Camera error: $e');
      state = state.copyWith(isCameraEnabled: !next);
    }
  }

  Future<void> toggleScreenShare() async {
    if (!state.canShareScreen && !state.isScreenSharing) return;
    final next = !state.isScreenSharing;
    try {
      await _roomPort.setScreenShareEnabled(next);
      state = state.copyWith(isScreenSharing: next);
    } catch (e) {
      debugPrint('[LiveRoomController] Screen share error: $e');
    }
  }

  void setAllowStudentsScreenShare(bool allowed) {
    if (!state.isHost) return;
    state = state.copyWith(allowStudentsScreenShare: allowed);
    final payload = jsonEncode({
      'type': 'screen_permission_update',
      'allowStudents': allowed,
      'presenters': state.presenterIdentities.toList(),
    });
    _roomPort.sendData(utf8.encode(payload), topic: 'screen_permission');
  }

  void togglePresenter(String identity) {
    if (!state.isHost) return;
    final presenters = Set<String>.from(state.presenterIdentities);
    if (presenters.contains(identity)) {
      presenters.remove(identity);
    } else {
      presenters.add(identity);
    }
    state = state.copyWith(presenterIdentities: presenters);
    final payload = jsonEncode({
      'type': 'screen_permission_update',
      'allowStudents': state.allowStudentsScreenShare,
      'presenters': presenters.toList(),
    });
    _roomPort.sendData(utf8.encode(payload), topic: 'screen_permission');
  }

  void giveAnnotationControl(String? targetIdentity, {String? targetName}) {
    if (!state.isHost) return;
    if (targetIdentity == null) {
      state = state.copyWith(
        clearActiveController: true,
        isAnnotationActive: false,
      );
    } else {
      state = state.copyWith(
        activeControllerIdentity: targetIdentity,
        activeControllerName: targetName,
        isAnnotationActive: true,
      );
    }
    final payload = jsonEncode({
      'type': 'grant_control',
      'targetIdentity': targetIdentity,
      'targetName': targetName,
    });
    _roomPort.sendData(utf8.encode(payload), topic: 'annotation');
  }

  void toggleAnnotationMode() {
    state = state.copyWith(isAnnotationActive: !state.isAnnotationActive);
  }

  void setAnnotationToolMode(AnnotationToolMode mode) {
    state = state.copyWith(currentToolMode: mode);
  }

  void setAnnotationColor(int colorValue) {
    state = state.copyWith(currentAnnotationColor: colorValue);
  }

  void sendPointerMove(double x, double y) {
    if (!state.canAnnotate) return;
    final myId = state.localParticipant?.identity ?? 'local';
    final myName = state.localParticipant?.name ?? 'Vous';
    final pointers = Map<String, LivePointerState>.from(state.livePointers);
    pointers[myId] = LivePointerState(
      identity: myId,
      name: myName,
      x: x,
      y: y,
      color: Color(state.currentAnnotationColor),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(livePointers: pointers);

    final payload = jsonEncode({
      'type': 'pointer_move',
      'x': x,
      'y': y,
      'identity': myId,
      'name': myName,
      'color': state.currentAnnotationColor,
    });
    _roomPort.sendData(utf8.encode(payload), topic: 'annotation');
  }

  void addAnnotationStroke(AnnotationStroke stroke) {
    if (!state.canAnnotate) return;
    state = state.copyWith(
      annotationStrokes: [...state.annotationStrokes, stroke],
    );
    final payload = jsonEncode({
      'type': 'annotation_stroke',
      'stroke': stroke.toJson(),
    });
    _roomPort.sendData(utf8.encode(payload), topic: 'annotation');
  }

  void clearAnnotations() {
    if (!state.canAnnotate) return;
    state = state.copyWith(
      annotationStrokes: const [],
      livePointers: const {},
    );
    final payload = jsonEncode({
      'type': 'annotation_clear',
    });
    _roomPort.sendData(utf8.encode(payload), topic: 'annotation');
  }

  Future<void> toggleRaiseHand() async {
    final next = !state.isHandRaised;
    state = state.copyWith(isHandRaised: next);

    if (next) {
      SoundEffectService.instance.playHandRaiseSound();
    }

    final myIdentity = state.localParticipant?.identity ?? 'local';
    final myName = state.localParticipant?.name ?? 'Vous';
    final raised = Set<String>.from(state.raisedHands);
    if (next) {
      raised.add(myIdentity);
    } else {
      raised.remove(myIdentity);
    }
    state = state.copyWith(
      raisedHands: raised,
      latestHandRaise: HandRaiseNotice(
        identity: myIdentity,
        displayName: myName,
        isRaised: next,
        timestamp: DateTime.now(),
      ),
    );
    try {
      final payload = jsonEncode({
        'type': 'raise_hand',
        'identity': myIdentity,
        'name': myName,
        'raised': next,
      });
      await _roomPort.sendData(utf8.encode(payload), topic: 'hand_raise');
    } catch (e) {
      debugPrint('[LiveRoomController] Error sending hand raise data: $e');
    }
  }

  Future<void> flipCamera() async {
    await _roomPort.flipCamera();
  }

  Future<void> sendChatMessage(String content) async {
    if (state.session == null || content.trim().isEmpty) return;
    if (!state.session!.chatEnabled && !state.isHost) return;

    try {
      final sent = await _repository.sendChatMessage(
        state.session!.id,
        content: content.trim(),
      );
      _addIncomingChatMessage(sent);

      // Broadcast immediately via LiveKit WebRTC data channel for instant real-time delivery
      try {
        final payload = jsonEncode({
          'type': 'chat_message',
          'message': SessionChatMessageModel.toJson(sent),
        });
        await _roomPort.sendData(utf8.encode(payload), topic: 'chat');
      } catch (e) {
        debugPrint('[LiveRoomController] LiveKit chat data broadcast error: $e');
      }
    } catch (e) {
      debugPrint('[LiveRoomController] Send chat error: $e');
      rethrow;
    }
  }

  void toggleChat([bool? open]) {
    final next = open ?? !state.isChatOpen;
    state = state.copyWith(
      isChatOpen: next,
      unreadChatCount: next ? 0 : state.unreadChatCount,
    );
  }

  void toggleParticipants([bool? open]) {
    final next = open ?? !state.isParticipantsOpen;
    state = state.copyWith(isParticipantsOpen: next);
  }

  Future<void> muteParticipant(String participantId, {bool mute = true}) async {
    if (state.session == null || !state.isHost) return;
    await _repository.muteParticipant(
      state.session!.id,
      participantId: participantId,
      mute: mute,
    );
  }

  Future<void> muteAll({bool mute = true}) async {
    if (state.session == null || !state.isHost) return;
    await _repository.muteAll(state.session!.id, mute: mute);
  }

  Future<void> removeParticipant(String participantId, {String? reason}) async {
    if (state.session == null || !state.isHost) return;
    await _repository.removeParticipant(
      state.session!.id,
      participantId: participantId,
      reason: reason,
    );
  }

  Future<void> updateChatSettings(bool enabled) async {
    if (state.session == null || !state.isHost) return;
    await _repository.updateChatSettings(
      state.session!.id,
      chatEnabled: enabled,
    );
  }

  Future<void> leaveRoom() async {
    final sessionId = state.session?.id;
    await WakelockPlus.disable().catchError((_) {});
    await _roomPort.disconnect();
    state = state.copyWith(connectionState: RoomConnectionState.disconnected);
    if (sessionId != null) {
      try {
        await _repository.leaveSession(sessionId);
      } catch (_) {}
    }
    _ref.invalidate(nextSessionFeedProvider);
  }

  Future<void> endRoomForEveryone() async {
    if (state.session == null || !state.isHost) return;
    final sessionId = state.session!.id;
    await WakelockPlus.disable().catchError((_) {});
    await _roomPort.disconnect();
    state = state.copyWith(connectionState: RoomConnectionState.endedByHost);
    try {
      await _repository.endSession(sessionId);
    } catch (_) {}
    _ref.invalidate(nextSessionFeedProvider);
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((_) {});
    _eventsSubscription?.close();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _roomPort.dispose();
    super.dispose();
  }
}

final liveRoomControllerProvider =
    StateNotifierProvider.autoDispose<LiveRoomController, LiveRoomState>((ref) {
  final roomPort = ref.watch(roomPortProvider);
  final repository = ref.watch(videoconferenceRepositoryProvider);
  return LiveRoomController(ref, roomPort, repository);
});

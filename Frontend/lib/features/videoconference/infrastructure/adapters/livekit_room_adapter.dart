import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../domain/entities/live_participant.dart';
import '../../domain/entities/room_connection_state.dart';
import '../../domain/ports/room_port.dart';

class LiveKitRoomAdapter implements RoomPort {
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _listener;

  RoomConnectionState _connectionState = RoomConnectionState.disconnected;

  final _connectionStateController =
      StreamController<RoomConnectionState>.broadcast();
  final _participantJoinedController =
      StreamController<LiveParticipant>.broadcast();
  final _participantLeftController = StreamController<String>.broadcast();
  final _participantUpdatedController =
      StreamController<LiveParticipant>.broadcast();
  final _activeSpeakerController = StreamController<String>.broadcast();
  final _dataMessageController =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  RoomConnectionState get connectionState => _connectionState;

  @override
  Stream<RoomConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  Stream<LiveParticipant> get participantJoinedStream =>
      _participantJoinedController.stream;

  @override
  Stream<String> get participantLeftStream => _participantLeftController.stream;

  @override
  Stream<LiveParticipant> get participantUpdatedStream =>
      _participantUpdatedController.stream;

  @override
  Stream<String> get activeSpeakerStream => _activeSpeakerController.stream;

  @override
  Stream<Map<String, dynamic>> get dataMessageStream =>
      _dataMessageController.stream;

  void _updateState(RoomConnectionState state) {
    _connectionState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  @override
  Future<void> connect(String url, String token) async {
    _updateState(RoomConnectionState.connecting);

    // Safely cleanup any prior active room before connecting
    if (_room != null || _listener != null) {
      try {
        await _listener?.dispose();
        await _room?.disconnect();
        await _room?.dispose();
      } catch (_) {}
      _listener = null;
      _room = null;
    }

    final roomOptions = const lk.RoomOptions(
      adaptiveStream: true,
      dynacast: true,
      defaultCameraCaptureOptions: lk.CameraCaptureOptions(
        maxFrameRate: 30,
        params: lk.VideoParametersPresets.h720_169,
      ),
      defaultAudioCaptureOptions: lk.AudioCaptureOptions(
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      ),
    );

    final room = lk.Room(roomOptions: roomOptions);
    _room = room;

    final listener = room.createListener();
    _listener = listener;

    _setupEventListeners(listener, room);

    try {
      await room.connect(url, token);
      _updateState(RoomConnectionState.connected);

      // Force mobile audio output to speakerphone for classroom clarity
      try {
        await lk.AudioManager.instance.setSpeakerOutputPreferred(true);
      } catch (e) {
        debugPrint('[LiveKitAdapter] Speakerphone error (non-fatal): $e');
      }

      // Emit local participant
      final local = room.localParticipant;
      if (local != null) {
        _participantJoinedController.add(_mapParticipant(local, isLocal: true));
      }

      // Emit existing remote participants
      for (final p in room.remoteParticipants.values) {
        _participantJoinedController.add(_mapParticipant(p, isLocal: false));
      }
    } catch (e) {
      debugPrint('[LiveKitAdapter] Connect error: $e');
      _updateState(RoomConnectionState.error);
      rethrow;
    }
  }

  void _setupEventListeners(
    lk.EventsListener<lk.RoomEvent> listener,
    lk.Room currentRoom,
  ) {
    listener
      ..on<lk.RoomDisconnectedEvent>((event) {
        debugPrint('[LiveKitAdapter] Disconnected: ${event.reason}');
        if (_room == currentRoom) {
          _updateState(RoomConnectionState.disconnected);
        }
      })
      ..on<lk.ParticipantConnectedEvent>((event) {
        _participantJoinedController
            .add(_mapParticipant(event.participant, isLocal: false));
      })
      ..on<lk.ParticipantDisconnectedEvent>((event) {
        _participantLeftController.add(event.participant.identity);
      })
      ..on<lk.TrackSubscribedEvent>((event) {
        _participantUpdatedController
            .add(_mapParticipant(event.participant, isLocal: false));
      })
      ..on<lk.TrackUnsubscribedEvent>((event) {
        _participantUpdatedController
            .add(_mapParticipant(event.participant, isLocal: false));
      })
      ..on<lk.TrackPublishedEvent>((event) {
        final p = event.participant;
        _participantUpdatedController
            .add(_mapParticipant(p, isLocal: p is lk.LocalParticipant));
      })
      ..on<lk.TrackUnpublishedEvent>((event) {
        final p = event.participant;
        _participantUpdatedController
            .add(_mapParticipant(p, isLocal: p is lk.LocalParticipant));
      })
      ..on<lk.TrackStreamStateUpdatedEvent>((event) {
        final p = event.participant;
        _participantUpdatedController
            .add(_mapParticipant(p, isLocal: p is lk.LocalParticipant));
      })
      ..on<lk.TrackMutedEvent>((event) {
        final p = event.participant;
        _participantUpdatedController
            .add(_mapParticipant(p, isLocal: p is lk.LocalParticipant));
      })
      ..on<lk.TrackUnmutedEvent>((event) {
        final p = event.participant;
        _participantUpdatedController
            .add(_mapParticipant(p, isLocal: p is lk.LocalParticipant));
      })
      ..on<lk.ActiveSpeakersChangedEvent>((event) {
        if (event.speakers.isNotEmpty) {
          _activeSpeakerController.add(event.speakers.first.identity);
        }
      })
      ..on<lk.LocalTrackPublishedEvent>((event) {
        final local = _room?.localParticipant;
        if (local != null) {
          _participantUpdatedController
              .add(_mapParticipant(local, isLocal: true));
        }
      })
      ..on<lk.LocalTrackUnpublishedEvent>((event) {
        final local = _room?.localParticipant;
        if (local != null) {
          _participantUpdatedController
              .add(_mapParticipant(local, isLocal: true));
        }
      })
      ..on<lk.DataReceivedEvent>((event) {
        try {
          final str = utf8.decode(event.data);
          final decoded = jsonDecode(str);
          if (decoded is Map<String, dynamic>) {
            _dataMessageController.add(decoded);
          }
        } catch (_) {}
      });
  }

  LiveParticipant _mapParticipant(lk.Participant p, {required bool isLocal}) {
    lk.VideoTrack? videoTrack;
    lk.VideoTrack? screenTrack;

    for (final pub in p.videoTrackPublications) {
      if (pub.source == lk.TrackSource.screenShareVideo) {
        screenTrack = pub.track as lk.VideoTrack?;
      } else if (pub.source == lk.TrackSource.camera) {
        videoTrack = pub.track as lk.VideoTrack?;
      }
    }

    final isHost = (p.metadata != null && p.metadata!.contains('"isHost":true')) ||
        p.permissions.canUpdateMetadata == true;

    final micPub = p.getTrackPublicationBySource(lk.TrackSource.microphone);
    final isAudioMuted = micPub == null || micPub.muted;
    final camPub = p.getTrackPublicationBySource(lk.TrackSource.camera);
    final isVideoMuted = videoTrack == null || (camPub?.muted ?? true);

    return LiveParticipant(
      identity: p.identity,
      name: p.name.isNotEmpty ? p.name : p.identity,
      isLocal: isLocal,
      isHost: isHost,
      isAudioMuted: isAudioMuted,
      isVideoMuted: isVideoMuted,
      isScreenSharing: screenTrack != null,
      isSpeaking: p.isSpeaking,
      joinedAt: p.joinedAt,
      videoTrack: videoTrack,
      screenTrack: screenTrack,
    );
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    final local = _room?.localParticipant;
    if (local != null) {
      await local.setMicrophoneEnabled(enabled);
      _participantUpdatedController.add(_mapParticipant(local, isLocal: true));
    }
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    final local = _room?.localParticipant;
    if (local != null) {
      await local.setCameraEnabled(enabled);
      _participantUpdatedController.add(_mapParticipant(local, isLocal: true));
    }
  }

  @override
  Future<void> setScreenShareEnabled(bool enabled) async {
    final local = _room?.localParticipant;
    if (local != null) {
      await local.setScreenShareEnabled(enabled);
      _participantUpdatedController.add(_mapParticipant(local, isLocal: true));
    }
  }

  @override
  Future<void> flipCamera() async {
    // Mobile camera flip
    final local = _room?.localParticipant;
    if (local != null) {
      for (final pub in local.videoTrackPublications) {
        final track = pub.track;
        if (track is lk.LocalVideoTrack) {
          final opts = track.currentOptions;
          if (opts is lk.CameraCaptureOptions) {
            final newPos = opts.cameraPosition == lk.CameraPosition.front
                ? lk.CameraPosition.back
                : lk.CameraPosition.front;
            try {
              await track.restartTrack(opts.copyWith(cameraPosition: newPos));
            } catch (_) {}
          }
        }
      }
    }
  }

  @override
  Future<void> sendData(List<int> data, {String? topic}) async {
    final local = _room?.localParticipant;
    if (local != null) {
      await local.publishData(data, topic: topic);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _room?.disconnect();
    } catch (_) {}
    _listener?.dispose();
    _room?.dispose();
    _room = null;
    _listener = null;
    _updateState(RoomConnectionState.disconnected);
  }

  @override
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _participantJoinedController.close();
    _participantLeftController.close();
    _participantUpdatedController.close();
    _activeSpeakerController.close();
    _dataMessageController.close();
  }
}

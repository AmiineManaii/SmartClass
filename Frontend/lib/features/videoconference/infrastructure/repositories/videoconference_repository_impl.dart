import 'dart:async';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/sse_client.dart';
import '../../domain/entities/join_token.dart';
import '../../domain/entities/next_session_feed.dart';
import '../../domain/entities/session_chat_message.dart';
import '../../domain/entities/session_event.dart';
import '../../domain/entities/video_session.dart';
import '../../domain/repositories/videoconference_repository.dart';
import '../datasources/videoconference_remote_datasource.dart';

class VideoconferenceRepositoryImpl implements VideoconferenceRepository {
  final VideoconferenceRemoteDataSource _remoteDataSource;
  final ApiClient _client;
  SseConnectionManager? _sseManager;
  StreamController<SessionEvent>? _eventsController;

  VideoconferenceRepositoryImpl(this._remoteDataSource, this._client);

  @override
  Future<PaginatedSessions> listSessions({
    String? status,
    String? classGroupId,
    String? scope,
    int page = 1,
    int limit = 20,
  }) {
    return _remoteDataSource.listSessions(
      status: status,
      classGroupId: classGroupId,
      scope: scope,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<VideoSession> getSession(String id) {
    return _remoteDataSource.getSession(id);
  }

  @override
  Future<VideoSession> createSession({
    required String classGroupId,
    required String title,
    String? subject,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    int? durationMinutes,
    int joinOpensMinutesBefore = 5,
    bool chatEnabled = true,
    String mode = 'SCHEDULED',
  }) {
    return _remoteDataSource.createSession(
      classGroupId: classGroupId,
      title: title,
      subject: subject,
      description: description,
      startsAt: startsAt,
      endsAt: endsAt,
      durationMinutes: durationMinutes,
      joinOpensMinutesBefore: joinOpensMinutesBefore,
      chatEnabled: chatEnabled,
      mode: mode,
    );
  }

  @override
  Future<VideoSession> updateSession({
    required String id,
    String? title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    int? joinOpensMinutesBefore,
    bool? chatEnabled,
  }) {
    return _remoteDataSource.updateSession(
      id: id,
      title: title,
      description: description,
      startsAt: startsAt,
      endsAt: endsAt,
      joinOpensMinutesBefore: joinOpensMinutesBefore,
      chatEnabled: chatEnabled,
    );
  }

  @override
  Future<VideoSession> cancelSession(String id, {String? cancelReason}) {
    return _remoteDataSource.cancelSession(id, cancelReason: cancelReason);
  }

  @override
  Future<VideoSession> startSession(String id) {
    return _remoteDataSource.startSession(id);
  }

  @override
  Future<JoinToken> getJoinToken(String id) {
    return _remoteDataSource.getJoinToken(id);
  }

  @override
  Future<VideoSession> endSession(String id) {
    return _remoteDataSource.endSession(id);
  }

  @override
  Future<void> leaveSession(String id) {
    return _remoteDataSource.leaveSession(id);
  }

  @override
  Future<void> muteParticipant(
    String id, {
    required String participantId,
    bool mute = true,
  }) {
    return _remoteDataSource.muteParticipant(
      id,
      participantId: participantId,
      mute: mute,
    );
  }

  @override
  Future<void> muteAll(String id, {bool mute = true}) {
    return _remoteDataSource.muteAll(id, mute: mute);
  }

  @override
  Future<void> removeParticipant(
    String id, {
    required String participantId,
    String? reason,
  }) {
    return _remoteDataSource.removeParticipant(
      id,
      participantId: participantId,
      reason: reason,
    );
  }

  @override
  Future<List<SessionChatMessage>> listChatMessages(
    String id, {
    int limit = 50,
    String? before,
  }) {
    return _remoteDataSource.listChatMessages(
      id,
      limit: limit,
      before: before,
    );
  }

  @override
  Future<SessionChatMessage> sendChatMessage(
    String id, {
    required String content,
  }) {
    return _remoteDataSource.sendChatMessage(id, content: content);
  }

  @override
  Future<void> updateChatSettings(String id, {required bool chatEnabled}) {
    return _remoteDataSource.updateChatSettings(
      id,
      chatEnabled: chatEnabled,
    );
  }

  @override
  Future<NextSessionFeed> getNextSession({int horizonHours = 24}) {
    return _remoteDataSource.getNextSession(horizonHours: horizonHours);
  }

  @override
  Stream<SessionEvent> streamEvents() {
    if (_eventsController != null && !_eventsController!.isClosed) {
      return _eventsController!.stream;
    }

    _eventsController = StreamController<SessionEvent>.broadcast(
      onCancel: () {
        // Keep active or dispose as needed
      },
    );

    _sseManager = SseConnectionManager(
      client: _client,
      path: '${ApiConfig.apiPrefix}/videoconference/events',
    );

    _sseManager!.stream.listen((message) {
      if (message.event == 'resync') {
        _eventsController?.add(SessionEvent.resync());
        return;
      }
      final json = message.jsonMap;
      if (json != null) {
        _eventsController?.add(SessionEvent.fromJson(json));
      }
    });

    _sseManager!.connect();

    return _eventsController!.stream;
  }

  void pauseEvents() => _sseManager?.pause();
  void resumeEvents() => _sseManager?.resume();
  void disposeEvents() {
    _sseManager?.dispose();
    _sseManager = null;
    _eventsController?.close();
    _eventsController = null;
  }
}

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/join_token.dart';
import '../../domain/entities/next_session_feed.dart';
import '../../domain/entities/session_chat_message.dart';
import '../../domain/entities/video_session.dart';
import '../../domain/repositories/videoconference_repository.dart';
import '../models/session_chat_message_model.dart';
import '../models/video_session_model.dart';

class VideoconferenceRemoteDataSource {
  final ApiClient _client;

  VideoconferenceRemoteDataSource(this._client);

  Future<PaginatedSessions> listSessions({
    String? status,
    String? classGroupId,
    String? scope,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (classGroupId != null && classGroupId.isNotEmpty) {
      query['classGroupId'] = classGroupId;
    }
    if (scope != null && scope.isNotEmpty) query['scope'] = scope;

    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions',
      queryParameters: query,
    );

    final body = res.data;
    if (body is Map<String, dynamic> && body['data'] is List) {
      final items = (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(VideoSessionModel.fromJson)
          .toList();

      final meta = body['meta'] as Map<String, dynamic>?;
      final total = (meta?['total'] as num?)?.toInt() ?? items.length;
      final p = (meta?['page'] as num?)?.toInt() ?? page;
      final l = (meta?['limit'] as num?)?.toInt() ?? limit;

      return PaginatedSessions(
        items: items,
        total: total,
        page: p,
        limit: l,
      );
    }
    throw const ApiException(message: 'Unexpected response format');
  }

  Future<VideoSession> getSession(String id) async {
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$id',
    );
    final data = apiEnvelope(res);
    return VideoSessionModel.fromJson(data);
  }

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
  }) async {
    final payload = <String, dynamic>{
      'classGroupId': classGroupId,
      'title': title,
      'mode': mode,
      'joinOpensMinutesBefore': joinOpensMinutesBefore,
      'chatEnabled': chatEnabled,
    };
    if (subject != null && subject.isNotEmpty) payload['subject'] = subject;
    if (description != null && description.isNotEmpty) {
      payload['description'] = description;
    }
    if (startsAt != null) payload['startsAt'] = startsAt.toUtc().toIso8601String();
    if (endsAt != null) payload['endsAt'] = endsAt.toUtc().toIso8601String();
    if (durationMinutes != null) payload['durationMinutes'] = durationMinutes;

    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions',
      data: payload,
    );
    final data = apiEnvelope(res);
    return VideoSessionModel.fromJson(data);
  }

  Future<VideoSession> updateSession({
    required String id,
    String? title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    int? joinOpensMinutesBefore,
    bool? chatEnabled,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title;
    if (description != null) payload['description'] = description;
    if (startsAt != null) payload['startsAt'] = startsAt.toUtc().toIso8601String();
    if (endsAt != null) payload['endsAt'] = endsAt.toUtc().toIso8601String();
    if (joinOpensMinutesBefore != null) {
      payload['joinOpensMinutesBefore'] = joinOpensMinutesBefore;
    }
    if (chatEnabled != null) payload['chatEnabled'] = chatEnabled;

    final res = await _client.patch<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$id',
      data: payload,
    );
    final data = apiEnvelope(res);
    return VideoSessionModel.fromJson(data);
  }

  Future<VideoSession> cancelSession(
    String id, {
    String? cancelReason,
  }) async {
    final payload = <String, dynamic>{};
    if (cancelReason != null && cancelReason.isNotEmpty) {
      payload['cancelReason'] = cancelReason;
    }

    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$id/cancel',
      data: payload,
    );
    final data = apiEnvelope(res);
    return VideoSessionModel.fromJson(data);
  }

  Future<VideoSession> startSession(String id) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$id/start',
    );
    final data = apiEnvelope(res);
    return VideoSessionModel.fromJson(data);
  }

  Future<JoinToken> getJoinToken(String id) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$id/join-token',
    );
    final data = apiEnvelope(res);
    return JoinToken.fromJson(data);
  }

  Future<VideoSession> endSession(String id) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$id/end',
    );
    final data = apiEnvelope(res);
    return VideoSessionModel.fromJson(data);
  }

  Future<void> leaveSession(String id) async {
    await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$id/leave',
    );
  }

  Future<void> muteParticipant(
    String id, {
    required String participantId,
    bool mute = true,
  }) async {
    await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$id/moderation/mute-participant',
      data: {
        'participantId': participantId,
        'mute': mute,
      },
    );
  }

  Future<void> muteAll(
    String id, {
    bool mute = true,
  }) async {
    await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$id/moderation/mute-all',
      data: {
        'mute': mute,
      },
    );
  }

  Future<void> removeParticipant(
    String id, {
    required String participantId,
    String? reason,
  }) async {
    await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$id/moderation/remove-participant',
      data: {
        'participantId': participantId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  Future<List<SessionChatMessage>> listChatMessages(
    String id, {
    int limit = 50,
    String? before,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (before != null && before.isNotEmpty) query['before'] = before;

    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$id/chat/messages',
      queryParameters: query,
    );
    final body = res.data;
    if (body is Map<String, dynamic> && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(SessionChatMessageModel.fromJson)
          .toList();
    }
    throw const ApiException(message: 'Unexpected response format');
  }

  Future<SessionChatMessage> sendChatMessage(
    String id, {
    required String content,
  }) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$id/chat/messages',
      data: {'content': content},
    );
    final data = apiEnvelope(res);
    return SessionChatMessageModel.fromJson(data);
  }

  Future<void> updateChatSettings(
    String id, {
    required bool chatEnabled,
  }) async {
    await _client.patch<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$id/chat/settings',
      data: {'chatEnabled': chatEnabled},
    );
  }

  Future<NextSessionFeed> getNextSession({int horizonHours = 24}) async {
    final fetchedAt = DateTime.now();
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/me/next-session',
      queryParameters: {'horizonHours': horizonHours},
    );
    final data = apiEnvelope(res);
    final liveJson = data['liveSession'] as Map<String, dynamic>?;
    final upcomingJson = data['upcomingSession'] as Map<String, dynamic>?;
    final serverNowStr = data['serverNow'] as String? ?? fetchedAt.toIso8601String();

    return NextSessionFeed(
      liveSession: liveJson != null ? VideoSessionModel.fromJson(liveJson) : null,
      upcomingSession:
          upcomingJson != null ? VideoSessionModel.fromJson(upcomingJson) : null,
      serverNow: DateTime.parse(serverNowStr),
      clientFetchedAt: fetchedAt,
    );
  }
}

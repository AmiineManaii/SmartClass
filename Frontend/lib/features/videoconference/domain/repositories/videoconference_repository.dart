import '../entities/join_token.dart';
import '../entities/next_session_feed.dart';
import '../entities/session_chat_message.dart';
import '../entities/session_event.dart';
import '../entities/video_session.dart';

class PaginatedSessions {
  final List<VideoSession> items;
  final int total;
  final int page;
  final int limit;

  const PaginatedSessions({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  bool get hasMore => page * limit < total;
}

abstract class VideoconferenceRepository {
  Future<PaginatedSessions> listSessions({
    String? status,
    String? classGroupId,
    String? scope,
    int page = 1,
    int limit = 20,
  });

  Future<VideoSession> getSession(String id);

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
  });

  Future<VideoSession> updateSession({
    required String id,
    String? title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    int? joinOpensMinutesBefore,
    bool? chatEnabled,
  });

  Future<VideoSession> cancelSession(
    String id, {
    String? cancelReason,
  });

  Future<VideoSession> startSession(String id);

  Future<JoinToken> getJoinToken(String id);

  Future<VideoSession> endSession(String id);

  Future<void> leaveSession(String id);

  Future<void> muteParticipant(
    String id, {
    required String participantId,
    bool mute = true,
  });

  Future<void> muteAll(
    String id, {
    bool mute = true,
  });

  Future<void> removeParticipant(
    String id, {
    required String participantId,
    String? reason,
  });

  Future<List<SessionChatMessage>> listChatMessages(
    String id, {
    int limit = 50,
    String? before,
  });

  Future<SessionChatMessage> sendChatMessage(
    String id, {
    required String content,
  });

  Future<void> updateChatSettings(
    String id, {
    required bool chatEnabled,
  });

  Future<NextSessionFeed> getNextSession({int horizonHours = 24});

  Stream<SessionEvent> streamEvents();
}

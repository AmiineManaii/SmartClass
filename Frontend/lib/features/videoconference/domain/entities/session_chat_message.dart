import 'package:equatable/equatable.dart';

class SessionChatMessage extends Equatable {
  final String id;
  final String sessionId;
  final String senderId;
  final String senderDisplayName;
  final String senderRole;
  final String content;
  final DateTime createdAt;

  const SessionChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderDisplayName,
    required this.senderRole,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        sessionId,
        senderId,
        senderDisplayName,
        senderRole,
        content,
        createdAt,
      ];
}

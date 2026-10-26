import '../../domain/entities/session_chat_message.dart';

class SessionChatMessageModel {
  static SessionChatMessage fromJson(Map<String, dynamic> json) {
    return SessionChatMessage(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderDisplayName: json['senderDisplayName'] as String? ?? '',
      senderRole: json['senderRole'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  static Map<String, dynamic> toJson(SessionChatMessage message) {
    return {
      'id': message.id,
      'sessionId': message.sessionId,
      'senderId': message.senderId,
      'senderDisplayName': message.senderDisplayName,
      'senderRole': message.senderRole,
      'content': message.content,
      'createdAt': message.createdAt.toIso8601String(),
    };
  }
}

import 'package:equatable/equatable.dart';

class SessionPermissions extends Equatable {
  final bool canPublishAudio;
  final bool canPublishVideo;
  final bool canPublishScreen;
  final bool canModerate;

  const SessionPermissions({
    required this.canPublishAudio,
    required this.canPublishVideo,
    required this.canPublishScreen,
    required this.canModerate,
  });

  factory SessionPermissions.fromJson(Map<String, dynamic> json) {
    final sources = (json['canPublishSources'] as List<dynamic>?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        const [];
    final canPublish = json['canPublish'] == true;

    return SessionPermissions(
      canPublishAudio: json['canPublishAudio'] == true ||
          (canPublish && (sources.isEmpty || sources.contains('microphone'))),
      canPublishVideo: json['canPublishVideo'] == true ||
          (canPublish && (sources.isEmpty || sources.contains('camera'))),
      canPublishScreen: json['canPublishScreen'] == true ||
          sources.contains('screen_share'),
      canModerate: json['canModerate'] == true || json['canModerate'] != null,
    );
  }

  @override
  List<Object?> get props => [
        canPublishAudio,
        canPublishVideo,
        canPublishScreen,
        canModerate,
      ];
}

class JoinToken extends Equatable {
  final String token;
  final String url;
  final String roomName;
  final String role;
  final SessionPermissions permissions;
  final DateTime expiresAt;

  const JoinToken({
    required this.token,
    required this.url,
    required this.roomName,
    required this.role,
    required this.permissions,
    required this.expiresAt,
  });

  factory JoinToken.fromJson(Map<String, dynamic> json) {
    return JoinToken(
      token: json['token'] as String,
      url: json['url'] as String,
      roomName: (json['roomName'] as String?) ?? '',
      role: json['role'] as String,
      permissions: SessionPermissions.fromJson(
        (json['permissions'] as Map<String, dynamic>?) ?? {},
      ),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        token,
        url,
        roomName,
        role,
        permissions,
        expiresAt,
      ];
}

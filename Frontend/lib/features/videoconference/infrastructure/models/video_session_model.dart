import '../../domain/entities/video_session.dart';

class VideoSessionModel {
  static VideoSession fromJson(Map<String, dynamic> json) {
    return VideoSession(
      id: json['id'] as String? ?? '',
      classGroupId: json['classGroupId'] as String? ?? '',
      hostId: json['hostId'] as String?,
      hostName: json['hostName'] as String?,
      subject: json['subject'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'] as String)
          : null,
      status: VideoSessionStatus.fromString(json['status'] as String? ?? 'SCHEDULED'),
      joinOpensMinutesBefore:
          (json['joinOpensMinutesBefore'] as num?)?.toInt() ?? 5,
      chatEnabled: json['chatEnabled'] != false,
      timetableSlotId: json['timetableSlotId'] as String?,
      courseId: json['courseId'] as String?,
      cancelReason: json['cancelReason'] as String?,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now())
          : DateTime.now(),
      className: json['className'] as String?,
      participantCount: (json['participantCount'] as num?)?.toInt(),
    );
  }

  static Map<String, dynamic> toJson(VideoSession session) {
    return {
      'id': session.id,
      'classGroupId': session.classGroupId,
      'hostId': session.hostId,
      'hostName': session.hostName,
      'subject': session.subject,
      'title': session.title,
      'description': session.description,
      'startsAt': session.startsAt.toIso8601String(),
      'endsAt': session.endsAt.toIso8601String(),
      'startedAt': session.startedAt?.toIso8601String(),
      'endedAt': session.endedAt?.toIso8601String(),
      'status': session.status.toApiString(),
      'joinOpensMinutesBefore': session.joinOpensMinutesBefore,
      'chatEnabled': session.chatEnabled,
      'timetableSlotId': session.timetableSlotId,
      'courseId': session.courseId,
      'cancelReason': session.cancelReason,
      'createdAt': session.createdAt.toIso8601String(),
      'updatedAt': session.updatedAt.toIso8601String(),
      'className': session.className,
      'participantCount': session.participantCount,
    };
  }
}

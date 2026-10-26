import 'package:equatable/equatable.dart';

enum VideoSessionStatus {
  scheduled,
  inProgress,
  completed,
  canceled;

  static VideoSessionStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'IN_PROGRESS':
        return VideoSessionStatus.inProgress;
      case 'COMPLETED':
        return VideoSessionStatus.completed;
      case 'CANCELED':
        return VideoSessionStatus.canceled;
      case 'SCHEDULED':
      default:
        return VideoSessionStatus.scheduled;
    }
  }

  String toApiString() {
    switch (this) {
      case VideoSessionStatus.inProgress:
        return 'IN_PROGRESS';
      case VideoSessionStatus.completed:
        return 'COMPLETED';
      case VideoSessionStatus.canceled:
        return 'CANCELED';
      case VideoSessionStatus.scheduled:
        return 'SCHEDULED';
    }
  }
}

class VideoSession extends Equatable {
  final String id;
  final String classGroupId;
  final String? hostId;
  final String? hostName;
  final String? subject;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime endsAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final VideoSessionStatus status;
  final int joinOpensMinutesBefore;
  final bool chatEnabled;
  final String? timetableSlotId;
  final String? courseId;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? className;
  final int? participantCount;

  const VideoSession({
    required this.id,
    required this.classGroupId,
    this.hostId,
    this.hostName,
    this.subject,
    required this.title,
    this.description,
    required this.startsAt,
    required this.endsAt,
    this.startedAt,
    this.endedAt,
    required this.status,
    this.joinOpensMinutesBefore = 5,
    this.chatEnabled = true,
    this.timetableSlotId,
    this.courseId,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
    this.className,
    this.participantCount,
  });

  DateTime get joinOpensAt =>
      startsAt.subtract(Duration(minutes: joinOpensMinutesBefore));

  VideoSession copyWith({
    String? id,
    String? classGroupId,
    String? hostId,
    String? hostName,
    String? subject,
    String? title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    DateTime? startedAt,
    DateTime? endedAt,
    VideoSessionStatus? status,
    int? joinOpensMinutesBefore,
    bool? chatEnabled,
    String? timetableSlotId,
    String? courseId,
    String? cancelReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? className,
    int? participantCount,
  }) {
    return VideoSession(
      id: id ?? this.id,
      classGroupId: classGroupId ?? this.classGroupId,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      description: description ?? this.description,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      joinOpensMinutesBefore:
          joinOpensMinutesBefore ?? this.joinOpensMinutesBefore,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      timetableSlotId: timetableSlotId ?? this.timetableSlotId,
      courseId: courseId ?? this.courseId,
      cancelReason: cancelReason ?? this.cancelReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      className: className ?? this.className,
      participantCount: participantCount ?? this.participantCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        classGroupId,
        hostId,
        hostName,
        subject,
        title,
        description,
        startsAt,
        endsAt,
        startedAt,
        endedAt,
        status,
        joinOpensMinutesBefore,
        chatEnabled,
        timetableSlotId,
        courseId,
        cancelReason,
        createdAt,
        updatedAt,
        className,
        participantCount,
      ];
}

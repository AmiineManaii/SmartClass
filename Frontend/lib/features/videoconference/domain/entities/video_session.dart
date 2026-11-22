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

class VideoSessionRecordingSummary extends Equatable {
  final String status;
  final bool hasVideo;
  final bool hasLessonPackage;
  final String? errorCode;
  final String? errorMessage;
  final String? jobStatus;
  final String? jobStage;
  final int? jobProgress;
  final DateTime? jobStartedAt;

  const VideoSessionRecordingSummary({
    required this.status,
    this.hasVideo = false,
    this.hasLessonPackage = false,
    this.errorCode,
    this.errorMessage,
    this.jobStatus,
    this.jobStage,
    this.jobProgress,
    this.jobStartedAt,
  });

  bool get isProcessing =>
      jobStatus == 'QUEUED' ||
      jobStatus == 'RUNNING' ||
      status == 'PROCESSING' ||
      status == 'FINALIZING' ||
      status == 'RECORDED' ||
      status == 'STARTING' ||
      status == 'RECORDING';

  bool get isFailed => !isProcessing && (status == 'FAILED' || jobStatus == 'FAILED');

  bool get isPublished => !isProcessing && !isFailed && status == 'PUBLISHED';

  bool get isApproved => !isProcessing && !isFailed && status == 'APPROVED';

  bool get isReadyForReview =>
      !isProcessing &&
      !isFailed &&
      (status == 'READY_FOR_REVIEW' ||
          status == 'APPROVED' ||
          (hasLessonPackage && status != 'PUBLISHED'));

  bool get hasNoRecording =>
      !isProcessing &&
      !isFailed &&
      !isPublished &&
      !isReadyForReview &&
      (status == 'NOT_STARTED' || status == 'DELETED' || !hasVideo);

  @override
  List<Object?> get props => [
        status,
        hasVideo,
        hasLessonPackage,
        errorCode,
        errorMessage,
        jobStatus,
        jobStage,
        jobProgress,
        jobStartedAt,
      ];
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
  final VideoSessionRecordingSummary? recordingSummary;

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
    this.recordingSummary,
  });

  DateTime get joinOpensAt =>
      startsAt.subtract(Duration(minutes: joinOpensMinutesBefore));

  bool get isAiProcessing => recordingSummary?.isProcessing ?? false;

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
    VideoSessionRecordingSummary? recordingSummary,
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
      recordingSummary: recordingSummary ?? this.recordingSummary,
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
        recordingSummary,
      ];
}

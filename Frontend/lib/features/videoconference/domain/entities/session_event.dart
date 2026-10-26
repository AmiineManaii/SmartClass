import 'package:equatable/equatable.dart';

class SessionEvent extends Equatable {
  final String type;
  final String? sessionId;
  final String? classGroupId;
  final String? status;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime at;
  final Map<String, dynamic> data;

  const SessionEvent({
    required this.type,
    this.sessionId,
    this.classGroupId,
    this.status,
    this.startsAt,
    this.endsAt,
    required this.at,
    this.data = const {},
  });

  factory SessionEvent.fromJson(Map<String, dynamic> json) {
    return SessionEvent(
      type: json['type'] as String? ?? 'unknown',
      sessionId: json['sessionId'] as String?,
      classGroupId: json['classGroupId'] as String?,
      status: json['status'] as String?,
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(json['startsAt'] as String)
          : null,
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt'] as String)
          : null,
      at: json['at'] != null
          ? (DateTime.tryParse(json['at'] as String) ?? DateTime.now())
          : DateTime.now(),
      data: (json['data'] as Map<String, dynamic>?) ?? const {},
    );
  }

  factory SessionEvent.resync() {
    return SessionEvent(
      type: 'resync',
      at: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        type,
        sessionId,
        classGroupId,
        status,
        startsAt,
        endsAt,
        at,
        data,
      ];
}

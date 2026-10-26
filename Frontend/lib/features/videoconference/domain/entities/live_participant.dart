import 'package:equatable/equatable.dart';

class LiveParticipant extends Equatable {
  final String identity;
  final String name;
  final bool isLocal;
  final bool isHost;
  final bool isAudioMuted;
  final bool isVideoMuted;
  final bool isHandRaised;
  final bool isScreenSharing;
  final bool isSpeaking;
  final DateTime joinedAt;
  final dynamic videoTrack;
  final dynamic screenTrack;

  const LiveParticipant({
    required this.identity,
    required this.name,
    this.isLocal = false,
    this.isHost = false,
    this.isAudioMuted = true,
    this.isVideoMuted = true,
    this.isHandRaised = false,
    this.isScreenSharing = false,
    this.isSpeaking = false,
    required this.joinedAt,
    this.videoTrack,
    this.screenTrack,
  });

  LiveParticipant copyWith({
    String? identity,
    String? name,
    bool? isLocal,
    bool? isHost,
    bool? isAudioMuted,
    bool? isVideoMuted,
    bool? isHandRaised,
    bool? isScreenSharing,
    bool? isSpeaking,
    DateTime? joinedAt,
    dynamic videoTrack,
    dynamic screenTrack,
  }) {
    return LiveParticipant(
      identity: identity ?? this.identity,
      name: name ?? this.name,
      isLocal: isLocal ?? this.isLocal,
      isHost: isHost ?? this.isHost,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoMuted: isVideoMuted ?? this.isVideoMuted,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      joinedAt: joinedAt ?? this.joinedAt,
      videoTrack: videoTrack ?? this.videoTrack,
      screenTrack: screenTrack ?? this.screenTrack,
    );
  }

  @override
  List<Object?> get props => [
        identity,
        name,
        isLocal,
        isHost,
        isAudioMuted,
        isVideoMuted,
        isHandRaised,
        isScreenSharing,
        isSpeaking,
        joinedAt,
        videoTrack,
        screenTrack,
      ];
}

import '../entities/live_participant.dart';
import '../entities/room_connection_state.dart';

abstract class RoomPort {
  RoomConnectionState get connectionState;
  Stream<RoomConnectionState> get connectionStateStream;
  Stream<LiveParticipant> get participantJoinedStream;
  Stream<String> get participantLeftStream;
  Stream<LiveParticipant> get participantUpdatedStream;
  Stream<String> get activeSpeakerStream;
  Stream<Map<String, dynamic>> get dataMessageStream;

  Future<void> connect(String url, String token);
  Future<void> disconnect();
  Future<void> setMicrophoneEnabled(bool enabled);
  Future<void> setCameraEnabled(bool enabled);
  Future<void> setScreenShareEnabled(bool enabled);
  Future<void> flipCamera();
  Future<void> sendData(List<int> data, {String? topic});
  void dispose();
}

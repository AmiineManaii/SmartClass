import 'package:equatable/equatable.dart';
import 'video_session.dart';

class NextSessionFeed extends Equatable {
  final VideoSession? liveSession;
  final VideoSession? upcomingSession;
  final DateTime serverNow;
  final DateTime clientFetchedAt;

  const NextSessionFeed({
    this.liveSession,
    this.upcomingSession,
    required this.serverNow,
    required this.clientFetchedAt,
  });

  Duration get serverOffset => serverNow.difference(clientFetchedAt);

  VideoSession? get session => liveSession ?? upcomingSession;
  bool get hasSession => session != null;

  @override
  List<Object?> get props => [
        liveSession,
        upcomingSession,
        serverNow,
        clientFetchedAt,
      ];
}

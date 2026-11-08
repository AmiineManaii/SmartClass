import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../domain/entities/recording_models.dart';
import '../domain/entities/session_event.dart';
import '../infrastructure/datasources/recording_remote_datasource.dart';
import 'videoconference_providers.dart';

final recordingRemoteDataSourceProvider =
    Provider<RecordingRemoteDataSource>((ref) {
  return RecordingRemoteDataSource(ref.watch(apiClientProvider));
});

final recordingAccessTokenProvider = FutureProvider<String?>((ref) async {
  return ref.watch(tokenStorageProvider).readAccessToken();
});

final sessionRecordingOverviewProvider =
    FutureProvider.family<RecordingOverview?, String>((ref, sessionId) async {
  ref.listen<AsyncValue<SessionEvent>>(liveEventsStreamProvider, (prev, next) {
    final event = next.valueOrNull;
    if (event != null &&
        event.sessionId == sessionId &&
        event.type.startsWith('recording.')) {
      ref.invalidateSelf();
    }
  });
  final ds = ref.watch(recordingRemoteDataSourceProvider);
  return ds.getRecording(sessionId);
});

final teacherReviewWorkspaceProvider =
    FutureProvider.family<TeacherReviewWorkspace, String>((ref, sessionId) async {
  ref.listen<AsyncValue<SessionEvent>>(liveEventsStreamProvider, (prev, next) {
    final event = next.valueOrNull;
    if (event != null &&
        event.sessionId == sessionId &&
        event.type.startsWith('recording.')) {
      ref.invalidateSelf();
    }
  });
  final ds = ref.watch(recordingRemoteDataSourceProvider);
  return ds.getTeacherReviewWorkspace(sessionId);
});

final studentLessonWorkspaceProvider =
    FutureProvider.family<StudentLessonWorkspace, String>((ref, sessionId) async {
  ref.listen<AsyncValue<SessionEvent>>(liveEventsStreamProvider, (prev, next) {
    final event = next.valueOrNull;
    if (event != null &&
        event.sessionId == sessionId &&
        event.type == 'recording.published') {
      ref.invalidateSelf();
    }
  });
  final ds = ref.watch(recordingRemoteDataSourceProvider);
  return ds.getStudentWorkspace(sessionId);
});

/// Shared synchronized playback position (in seconds) per sessionId.
final replayPositionSecondsProvider =
    StateProvider.family<double, String>((ref, sessionId) => 0.0);

/// Whether the interactive replay player is currently playing.
final replayIsPlayingProvider =
    StateProvider.family<bool, String>((ref, sessionId) => false);

/// Playback speed multiplier (0.75x, 1.0x, 1.25x, 1.5x, 2.0x).
final replaySpeedProvider =
    StateProvider.family<double, String>((ref, sessionId) => 1.0);

/// Subtitles toggle state.
final replaySubtitlesEnabledProvider =
    StateProvider.family<bool, String>((ref, sessionId) => true);

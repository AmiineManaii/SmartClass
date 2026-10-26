import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../domain/entities/next_session_feed.dart';
import '../domain/entities/session_event.dart';
import '../domain/entities/video_session.dart';
import '../domain/repositories/videoconference_repository.dart';
import '../infrastructure/datasources/videoconference_remote_datasource.dart';
import '../infrastructure/repositories/videoconference_repository_impl.dart';

final videoconferenceRemoteDataSourceProvider =
    Provider<VideoconferenceRemoteDataSource>((ref) {
  return VideoconferenceRemoteDataSource(ref.watch(apiClientProvider));
});

final videoconferenceRepositoryProvider =
    Provider<VideoconferenceRepository>((ref) {
  final repo = VideoconferenceRepositoryImpl(
    ref.watch(videoconferenceRemoteDataSourceProvider),
    ref.watch(apiClientProvider),
  );
  ref.onDispose(() {
    repo.disposeEvents();
  });
  return repo;
});

final liveEventsStreamProvider = StreamProvider<SessionEvent>((ref) {
  final repo = ref.watch(videoconferenceRepositoryProvider);
  return repo.streamEvents();
});

class VideoSessionsState {
  final List<VideoSession> sessions;
  final int total;
  final int page;
  final int limit;
  final bool isLoadingMore;
  final bool hasMore;

  const VideoSessionsState({
    required this.sessions,
    required this.total,
    required this.page,
    required this.limit,
    this.isLoadingMore = false,
    this.hasMore = false,
  });

  VideoSessionsState copyWith({
    List<VideoSession>? sessions,
    int? total,
    int? page,
    int? limit,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return VideoSessionsState(
      sessions: sessions ?? this.sessions,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class VideoSessionsNotifier
    extends FamilyAsyncNotifier<VideoSessionsState, String> {
  @override
  Future<VideoSessionsState> build(String arg) async {
    // Listen to realtime events and auto-refresh this tab when relevant events occur
    ref.listen<AsyncValue<SessionEvent>>(liveEventsStreamProvider, (prev, next) {
      final event = next.valueOrNull;
      if (event == null) return;
      // When resync or session lifecycle event occurs, refresh
      if (event.type == 'resync' || event.type.startsWith('session.')) {
        refresh();
      }
    });

    return _fetchPage(1);
  }

  Future<VideoSessionsState> _fetchPage(int page) async {
    final repo = ref.read(videoconferenceRepositoryProvider);
    String? status;
    if (arg == 'live') {
      status = 'IN_PROGRESS';
    } else if (arg == 'scheduled') {
      status = 'SCHEDULED';
    } else if (arg == 'past' || arg == 'ended') {
      status = 'COMPLETED';
    }

    final result = await repo.listSessions(
      status: status,
      page: page,
      limit: 20,
    );

    return VideoSessionsState(
      sessions: result.items,
      total: result.total,
      page: result.page,
      limit: result.limit,
      hasMore: result.hasMore,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPage(1));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.page + 1;
      final repo = ref.read(videoconferenceRepositoryProvider);
      String? status;
      if (arg == 'live') {
        status = 'IN_PROGRESS';
      } else if (arg == 'scheduled') {
        status = 'SCHEDULED';
      } else if (arg == 'past' || arg == 'ended') {
        status = 'COMPLETED';
      }

      final result = await repo.listSessions(
        status: status,
        page: nextPage,
        limit: current.limit,
      );

      final combined = [...current.sessions, ...result.items];
      state = AsyncValue.data(VideoSessionsState(
        sessions: combined,
        total: result.total,
        page: result.page,
        limit: result.limit,
        isLoadingMore: false,
        hasMore: result.hasMore,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final videoSessionsProvider =
    AsyncNotifierProviderFamily<VideoSessionsNotifier, VideoSessionsState, String>(
  VideoSessionsNotifier.new,
);

class SessionActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SessionActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  VideoconferenceRepository get _repo =>
      _ref.read(videoconferenceRepositoryProvider);

  Future<VideoSession?> createSession({
    required String classGroupId,
    required String title,
    String? subject,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    int? durationMinutes,
    int joinOpensMinutesBefore = 5,
    bool chatEnabled = true,
    String mode = 'SCHEDULED',
  }) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repo.createSession(
        classGroupId: classGroupId,
        title: title,
        subject: subject,
        description: description,
        startsAt: startsAt,
        endsAt: endsAt,
        durationMinutes: durationMinutes,
        joinOpensMinutesBefore: joinOpensMinutesBefore,
        chatEnabled: chatEnabled,
        mode: mode,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(videoSessionsProvider('scheduled'));
      _ref.invalidate(videoSessionsProvider('live'));
      _ref.invalidate(nextSessionFeedProvider);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<VideoSession?> updateSession({
    required String id,
    String? title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    int? joinOpensMinutesBefore,
    bool? chatEnabled,
  }) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repo.updateSession(
        id: id,
        title: title,
        description: description,
        startsAt: startsAt,
        endsAt: endsAt,
        joinOpensMinutesBefore: joinOpensMinutesBefore,
        chatEnabled: chatEnabled,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(videoSessionsProvider('scheduled'));
      _ref.invalidate(nextSessionFeedProvider);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<VideoSession?> cancelSession(String id, {String? cancelReason}) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repo.cancelSession(id, cancelReason: cancelReason);
      state = const AsyncValue.data(null);
      _ref.invalidate(videoSessionsProvider('scheduled'));
      _ref.invalidate(videoSessionsProvider('live'));
      _ref.invalidate(nextSessionFeedProvider);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<VideoSession?> startSession(String id) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repo.startSession(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(videoSessionsProvider('live'));
      _ref.invalidate(videoSessionsProvider('scheduled'));
      _ref.invalidate(nextSessionFeedProvider);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<VideoSession?> endSession(String id) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repo.endSession(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(videoSessionsProvider('live'));
      _ref.invalidate(videoSessionsProvider('past'));
      _ref.invalidate(nextSessionFeedProvider);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final sessionActionsNotifierProvider =
    StateNotifierProvider<SessionActionsNotifier, AsyncValue<void>>((ref) {
  return SessionActionsNotifier(ref);
});

final nextSessionFeedProvider = FutureProvider<NextSessionFeed>((ref) async {
  ref.listen<AsyncValue<SessionEvent>>(liveEventsStreamProvider, (prev, next) {
    final event = next.valueOrNull;
    if (event == null) return;
    if (event.type == 'resync' || event.type.startsWith('session.')) {
      ref.invalidateSelf();
    }
  });

  // Periodic heartbeat refresh every 10 seconds for real-time participant and status freshness
  final timer = Timer.periodic(const Duration(seconds: 10), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final repo = ref.watch(videoconferenceRepositoryProvider);
  return repo.getNextSession();
});

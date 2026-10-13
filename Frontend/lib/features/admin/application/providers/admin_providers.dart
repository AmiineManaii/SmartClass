import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../domain/entities/admin_overview.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/entities/fraud_report.dart';
import '../../domain/entities/managed_class.dart';
import '../../domain/entities/timetable.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../infrastructure/datasources/admin_remote_datasource.dart';
import '../../infrastructure/repositories/admin_repository_impl.dart';

/// Remote datasource seam (real API, ADMIN-only endpoints).
final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource(ref.watch(apiClientProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(remote: ref.watch(adminRemoteDataSourceProvider));
});

final adminOverviewProvider = FutureProvider<AdminOverview>((ref) {
  return ref.watch(adminRepositoryProvider).overview();
});

/// Server-side class search text (debounced in UI).
final adminClassSearchProvider = StateProvider<String>((ref) => '');

/// Server-side level filter (null = all).
final adminClassLevelFilterProvider = StateProvider<ClassLevel?>((ref) => null);

final adminClassesProvider = FutureProvider<List<AdminClassSummary>>((ref) {
  return ref.watch(adminRepositoryProvider).classes(
        level: ref.watch(adminClassLevelFilterProvider),
        search: ref.watch(adminClassSearchProvider).trim().isEmpty
            ? null
            : ref.watch(adminClassSearchProvider).trim(),
      );
});

final adminClassDetailProvider =
    FutureProvider.family<AdminClassDetail?, String>((ref, classId) {
  return ref.watch(adminRepositoryProvider).classDetail(classId);
});

final adminDepartmentsProvider = FutureProvider<List<DepartmentInfo>>((ref) {
  return ref.watch(adminRepositoryProvider).departments();
});

/// Server-side directory search text (debounced in UI).
final adminPersonSearchProvider = StateProvider<String>((ref) => '');

final adminStudentsProvider =
    FutureProvider.family<List<AdminStudent>, String?>((ref, classId) {
  final search = ref.watch(adminPersonSearchProvider).trim();
  return ref.watch(adminRepositoryProvider).students(
        search: search.isEmpty ? null : search,
        classId: classId,
      );
});

final adminTeachersProvider =
    FutureProvider.family<List<AdminTeacher>, String?>((ref, classId) {
  final search = ref.watch(adminPersonSearchProvider).trim();
  return ref.watch(adminRepositoryProvider).teachers(
        search: search.isEmpty ? null : search,
        classId: classId,
      );
});

// Planning ---------------------------------------------------------------

/// Class selected on the planning screen (defaults to the first class).
final adminPlanningClassProvider = StateProvider<String?>((ref) => null);

/// Week start (YYYY-MM-DD Monday) selected on the planning screen.
final adminPlanningWeekStartProvider = StateProvider<String?>((ref) => null);

final adminWeekScheduleProvider = FutureProvider<PlannerWeek?>((ref) async {
  final classId = ref.watch(adminPlanningClassProvider);
  final weekStart = ref.watch(adminPlanningWeekStartProvider);
  if (classId == null || classId.isEmpty || weekStart == null) return null;
  return ref.watch(adminRepositoryProvider).weekSchedule(
        classId: classId,
        weekStart: weekStart,
      );
});

// Frauds (cursor pagination with "load more") ------------------------------

class FraudReportsState {
  final List<FraudReport> reports;
  final String? nextCursor;
  final bool hasMore;
  final bool loadingMore;
  final String? statusFilter;

  const FraudReportsState({
    this.reports = const [],
    this.nextCursor,
    this.hasMore = false,
    this.loadingMore = false,
    this.statusFilter,
  });

  FraudReportsState copyWith({
    List<FraudReport>? reports,
    String? Function()? nextCursor,
    bool? hasMore,
    bool? loadingMore,
    String? Function()? statusFilter,
  }) {
    return FraudReportsState(
      reports: reports ?? this.reports,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
    );
  }
}

class FraudReportsNotifier extends StateNotifier<AsyncValue<FraudReportsState>> {
  FraudReportsNotifier(this._ref)
      : super(const AsyncValue.loading()) {
    loadInitial();
  }

  final Ref _ref;

  AdminRepository get _repo => _ref.read(adminRepositoryProvider);

  Future<void> loadInitial({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final page = await _repo.fraudReports(status: status);
      state = AsyncValue.data(FraudReportsState(
        reports: page.reports,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        statusFilter: status,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncValue.data(current.copyWith(loadingMore: true));
    try {
      final page = await _repo.fraudReports(
        status: current.statusFilter,
        cursor: current.nextCursor,
      );
      state = AsyncValue.data(current.copyWith(
        reports: [...current.reports, ...page.reports],
        nextCursor: () => page.nextCursor,
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } catch (_) {
      state = AsyncValue.data(current.copyWith(loadingMore: false));
      rethrow;
    }
  }

  Future<void> refresh() => loadInitial(status: state.valueOrNull?.statusFilter);
}

final adminFraudReportsProvider =
    StateNotifierProvider<FraudReportsNotifier, AsyncValue<FraudReportsState>>((ref) {
  return FraudReportsNotifier(ref);
});

final adminFraudSummaryProvider = FutureProvider<FraudSummary>((ref) {
  return ref.watch(adminRepositoryProvider).fraudSummary();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/datasources/mock_teacher_dashboard_datasource.dart';

final mockTeacherDashboardDataSourceProvider = Provider<MockTeacherDashboardDataSource>((ref) {
  return const MockTeacherDashboardDataSource();
});

final teacherLiveSessionProvider = Provider<TeacherLiveSession>((ref) {
  return ref.watch(mockTeacherDashboardDataSourceProvider).liveSession();
});

final teacherStatsProvider = Provider<List<TeacherStat>>((ref) {
  return ref.watch(mockTeacherDashboardDataSourceProvider).stats();
});

final teacherClassesProvider = Provider<List<TeacherClass>>((ref) {
  return ref.watch(mockTeacherDashboardDataSourceProvider).classes();
});

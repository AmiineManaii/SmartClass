import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/datasources/mock_student_dashboard_datasource.dart';

final mockStudentDashboardDataSourceProvider = Provider<MockStudentDashboardDataSource>((ref) {
  return const MockStudentDashboardDataSource();
});

final studentMotivationStatsProvider = Provider<StudentMotivationStats>((ref) {
  return ref.watch(mockStudentDashboardDataSourceProvider).motivationStats();
});

final studentImminentLiveProvider = Provider<StudentLiveSession>((ref) {
  return ref.watch(mockStudentDashboardDataSourceProvider).imminentLive();
});

final studentCoursesProgressProvider = Provider<List<StudentCourseProgress>>((ref) {
  return ref.watch(mockStudentDashboardDataSourceProvider).coursesProgress();
});

final studentUpcomingAssignmentsProvider = Provider<List<StudentAssignment>>((ref) {
  return ref.watch(mockStudentDashboardDataSourceProvider).upcomingAssignments();
});

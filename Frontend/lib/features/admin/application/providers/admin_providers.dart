import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_overview.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/entities/fraud_report.dart';
import '../../domain/entities/managed_class.dart';
import '../../domain/entities/timetable.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../infrastructure/datasources/mock_admin_datasource.dart';
import '../../infrastructure/repositories/admin_repository_impl.dart';

/// Swappable seam: replace [AdminRepositoryImpl] with a remote
/// implementation once contracts land — presentation stays untouched.
final mockAdminDataSourceProvider = Provider<MockAdminDataSource>((ref) {
  return const MockAdminDataSource();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(mockAdminDataSourceProvider));
});

final adminOverviewProvider = FutureProvider<AdminOverview>((ref) {
  return ref.watch(adminRepositoryProvider).overview();
});

final adminClassesProvider = FutureProvider<List<AdminClassSummary>>((ref) {
  return ref.watch(adminRepositoryProvider).classes();
});

final adminStudentsProvider = FutureProvider<List<AdminStudent>>((ref) {
  return ref.watch(adminRepositoryProvider).students();
});

final adminTeachersProvider = FutureProvider<List<AdminTeacher>>((ref) {
  return ref.watch(adminRepositoryProvider).teachers();
});

final adminWeekScheduleProvider = FutureProvider<PlannerWeek>((ref) {
  return ref.watch(adminRepositoryProvider).weekSchedule();
});

final adminFraudReportsProvider = FutureProvider<List<FraudReport>>((ref) {
  return ref.watch(adminRepositoryProvider).fraudReports();
});

final adminFraudSummaryProvider = FutureProvider<FraudSummary>((ref) {
  return ref.watch(adminRepositoryProvider).fraudSummary();
});

/// Detail of one class for the assign flows (mock capacity/department).
final adminClassDetailProvider =
    FutureProvider.family<AdminClassDetail?, String>((ref, classId) async {
  final classes = await ref.watch(adminRepositoryProvider).classes();
  final match = classes.where((c) => c.id == classId);
  if (match.isEmpty) return null;
  final summary = match.first;
  return AdminClassDetail(
    id: summary.id,
    promoTag: summary.promoTag,
    statusKey: summary.statusKey,
    statusActive: summary.statusActive,
    title: summary.title,
    icon: summary.icon,
    students: summary.students,
    teachers: summary.teachers,
    referent: summary.referent,
    presencePct: summary.presencePct,
    coursesActive: summary.coursesActive,
    level: summary.level,
    extraChips: summary.extraChips,
    capacity: 35,
    department: 'Informatique',
  );
});

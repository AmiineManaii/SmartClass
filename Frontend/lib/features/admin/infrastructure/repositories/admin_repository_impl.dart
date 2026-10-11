import '../../domain/entities/admin_overview.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/entities/fraud_report.dart';
import '../../domain/entities/managed_class.dart';
import '../../domain/entities/timetable.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/mock_admin_datasource.dart';

/// Repository implementation currently backed 100% by [MockAdminDataSource].
///
/// Swap each method body for a Dio call when the matching contract lands —
/// domain and presentation stay untouched.
class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._mock);

  final MockAdminDataSource _mock;

  @override
  Future<AdminOverview> overview() async => _mock.overview();

  @override
  Future<List<AdminClassSummary>> classes() async => _mock.classes();

  @override
  Future<String> createClass(Map<String, dynamic> payload) async =>
      'class-${DateTime.now().millisecondsSinceEpoch}';

  @override
  Future<List<AdminStudent>> students() async => _mock.students();

  @override
  Future<List<AdminTeacher>> teachers() async => _mock.teachers();

  @override
  Future<void> assignStudents(String classId, List<String> studentIds) async {}

  @override
  Future<void> assignTeachers(String classId, List<String> teacherIds) async {}

  @override
  Future<PlannerWeek> weekSchedule() async => _mock.weekSchedule();

  @override
  Future<List<FraudReport>> fraudReports() async => _mock.fraudReports();

  @override
  Future<FraudSummary> fraudSummary() async => _mock.fraudSummary();
}

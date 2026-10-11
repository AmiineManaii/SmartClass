import '../entities/admin_overview.dart';
import '../entities/admin_person.dart';
import '../entities/fraud_report.dart';
import '../entities/managed_class.dart';
import '../entities/timetable.dart';

/// Admin bounded-context contract.
///
/// Every method is currently served by [MockAdminDataSource] because no
/// backend module exists yet (users/groups/courses/exams/videoconference
/// are 📋 planned — see `contracts/README.md`). Each method carries the
/// future endpoint so wiring the real API later needs no UI change.
abstract class AdminRepository {
  /// TODO(users-contract): GET /api/v1/admin/overview
  Future<AdminOverview> overview();

  /// TODO(groups-contract): GET /api/v1/groups
  Future<List<AdminClassSummary>> classes();

  /// TODO(groups-contract): POST /api/v1/groups
  Future<String> createClass(Map<String, dynamic> payload);

  /// TODO(users-contract): GET /api/v1/users?role=STUDENT
  Future<List<AdminStudent>> students();

  /// TODO(users-contract): GET /api/v1/users?role=TEACHER
  Future<List<AdminTeacher>> teachers();

  /// TODO(groups-contract): POST /api/v1/groups/:id/members
  Future<void> assignStudents(String classId, List<String> studentIds);

  /// TODO(groups-contract): POST /api/v1/groups/:id/teachers
  Future<void> assignTeachers(String classId, List<String> teacherIds);

  /// TODO(videoconference-contract): GET /api/v1/videoconference/timetable
  Future<PlannerWeek> weekSchedule();

  /// TODO(exams-contract): GET /api/v1/exams/fraud-reports
  Future<List<FraudReport>> fraudReports();

  /// TODO(exams-contract): GET /api/v1/exams/fraud-reports/summary
  Future<FraudSummary> fraudSummary();
}

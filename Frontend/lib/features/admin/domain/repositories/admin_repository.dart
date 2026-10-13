import '../entities/admin_overview.dart';
import '../entities/admin_person.dart';
import '../entities/fraud_report.dart';
import '../entities/managed_class.dart';
import '../entities/timetable.dart';

/// Admin bounded-context contract, backed by the real API
/// (`contracts/admin|users|groups|exams|videoconference.openapi.yaml`,
/// ADMIN-only). Implementations throw [Failure]-mapped [ApiException].
abstract class AdminRepository {
  /// GET /api/v1/admin/overview
  Future<AdminOverview> overview();

  /// GET /api/v1/groups
  Future<List<AdminClassSummary>> classes({ClassLevel? level, String? search});

  /// GET /api/v1/groups/:id
  Future<AdminClassDetail?> classDetail(String classId);

  /// POST /api/v1/groups — returns the created class id.
  Future<String> createClass({
    required String name,
    required ClassLevel level,
    String? department,
    required int capacity,
    String? description,
    bool forumEnabled = true,
    bool entSyncEnabled = true,
    bool draft = false,
    String? referentId,
  });

  /// PATCH /api/v1/groups/:id
  Future<void> updateClass(String classId, Map<String, dynamic> fields);

  /// DELETE /api/v1/groups/:id
  Future<void> deleteClass(String classId);

  /// GET /api/v1/groups/departments — filières in use.
  Future<List<DepartmentInfo>> departments();

  /// GET /api/v1/users?role=STUDENT
  Future<List<AdminStudent>> students({String? search, String? classId});

  /// GET /api/v1/users?role=TEACHER merged with the class assignments.
  Future<List<AdminTeacher>> teachers({String? search, String? classId});

  /// GET /api/v1/groups/:id/members — assigned student ids.
  Future<Set<String>> classMemberIds(String classId);

  /// POST /api/v1/groups/:id/members
  Future<void> assignStudents(String classId, List<String> studentIds);

  /// DELETE /api/v1/groups/:id/members
  Future<void> removeStudents(String classId, List<String> studentIds);

  /// POST /api/v1/groups/:id/teachers
  Future<void> assignTeachers(
    String classId,
    List<TeacherAssignment> assignments,
  );

  /// DELETE /api/v1/groups/:id/teachers
  Future<void> removeTeachers(String classId, List<String> teacherIds);

  /// GET /api/v1/videoconference/timetable
  Future<PlannerWeek> weekSchedule({
    required String classId,
    required String weekStart,
  });

  /// GET /api/v1/exams/fraud-reports
  Future<FraudReportsPage> fraudReports({String? status, String? cursor});

  /// GET /api/v1/exams/fraud-reports/summary
  Future<FraudSummary> fraudSummary();

  /// PATCH /api/v1/exams/fraud-reports/:id
  Future<void> updateFraudReport(
    String id, {
    required FraudStatus status,
    String? resolution,
  });
}

/// Filière in use with its class count.
class DepartmentInfo {
  final String name;
  final int classCount;

  const DepartmentInfo({required this.name, required this.classCount});
}

/// Teacher assignment payload for POST /groups/:id/teachers.
class TeacherAssignment {
  final String teacherId;
  final String subject;
  final String? weeklyHours;

  const TeacherAssignment({
    required this.teacherId,
    required this.subject,
    this.weeklyHours,
  });

  Map<String, dynamic> toJson() => {
        'teacherId': teacherId,
        'subject': subject,
        if (weeklyHours != null && weeklyHours!.trim().isNotEmpty)
          'weeklyHours': weeklyHours!.trim(),
      };
}

/// One cursor page of fraud reports.
class FraudReportsPage {
  final List<FraudReport> reports;
  final String? nextCursor;
  final bool hasMore;

  const FraudReportsPage({
    required this.reports,
    this.nextCursor,
    this.hasMore = false,
  });
}

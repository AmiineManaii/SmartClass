import '../../../../core/network/api_exception.dart';
import '../../domain/entities/admin_overview.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/entities/fraud_report.dart';
import '../../domain/entities/managed_class.dart';
import '../../domain/entities/timetable.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';
import '../models/admin_models.dart';

/// [AdminRepository] backed by the real API. Translates transport errors
/// into [ApiException] (mapped to [Failure] by callers) — never mock data.
class AdminRepositoryImpl implements AdminRepository {
  // ignore: prefer_initializing_formals
  AdminRepositoryImpl({required AdminRemoteDataSource remote}) : _remote = remote;

  final AdminRemoteDataSource _remote;

  @override
  Future<AdminOverview> overview() async {
    final data = await _remote.getOverview();
    final frauds = await _remote.listFraudReports(status: 'UNTREATED', limit: 2);

    final students = data['students'] as Map<String, dynamic>? ?? {};
    final teachers = data['teachers'] as Map<String, dynamic>? ?? {};
    final classes = data['classes'] as Map<String, dynamic>? ?? {};
    final fraudSummary = data['frauds'] as Map<String, dynamic>? ?? {};
    final untreated = (fraudSummary['untreated'] as num?)?.toInt() ?? 0;

    final alerts = frauds.items
        .whereType<Map<String, dynamic>>()
        .map(fraudReportFromJson)
        .take(2)
        .map(
          (report) => AdminAlert(
            id: report.id,
            icon: 'shield',
            title: report.title,
            subtitle: report.subtitle,
            chips: [
              AdminAlertChip(
                text: report.studentId.isNotEmpty ? report.studentId : report.studentName,
                tone: AdminStatTone.error,
              ),
              if (report.studentClass.isNotEmpty)
                AdminAlertChip(text: report.studentClass, tone: AdminStatTone.info),
            ],
            primaryActionKey: 'admin_review_incident',
            secondaryActionKey: 'admin_ignore',
          ),
        )
        .toList();

    return AdminOverview(
      stats: [
        AdminStat(
          id: 'students',
          icon: 'school',
          value: '${(students['total'] as num?)?.toInt() ?? 0}',
          labelKey: 'admin_stat_students',
          badgeKey: 'admin_stat_students_badge',
          badgeArgs: {'count': '${(students['newThisMonth'] as num?)?.toInt() ?? 0}'},
        ),
        AdminStat(
          id: 'teachers',
          icon: 'badge',
          value: '${(teachers['total'] as num?)?.toInt() ?? 0}',
          labelKey: 'admin_stat_teachers',
          badgeKey: 'admin_stat_teachers_badge',
          badgeArgs: {'pct': '${(teachers['activePct'] as num?)?.toInt() ?? 0}'},
        ),
        AdminStat(
          id: 'classes',
          icon: 'class',
          value: '${(classes['total'] as num?)?.toInt() ?? 0}',
          labelKey: 'admin_stat_classes',
          badgeKey: 'admin_stat_students_badge',
          badgeArgs: {'count': '${(classes['newThisMonth'] as num?)?.toInt() ?? 0}'},
        ),
        AdminStat(
          id: 'frauds',
          icon: 'warning',
          value: '$untreated',
          labelKey: 'admin_stat_frauds',
          badgeKey: untreated > 0 ? 'admin_stat_frauds_badge' : 'admin_stat_frauds_ok',
          tone: untreated > 0 ? AdminStatTone.error : AdminStatTone.success,
          highlighted: untreated > 0,
        ),
      ],
      shortcuts: const [
        AdminShortcut(
          id: 'classes',
          icon: 'meeting_room',
          titleKey: 'admin_nav_classes',
          descKey: 'admin_nav_classes_desc',
          route: '/admin/classes',
        ),
        AdminShortcut(
          id: 'teachers',
          icon: 'manage_accounts',
          titleKey: 'admin_nav_teachers',
          descKey: 'admin_nav_teachers_desc',
          route: '/admin/teachers',
        ),
        AdminShortcut(
          id: 'students',
          icon: 'groups',
          titleKey: 'admin_nav_students',
          descKey: 'admin_nav_students_desc',
          route: '/admin/students',
        ),
        AdminShortcut(
          id: 'planning',
          icon: 'calendar_month',
          titleKey: 'admin_nav_planning',
          descKey: 'admin_nav_planning_desc',
          route: '/admin/planning',
        ),
      ],
      alerts: alerts,
    );
  }

  @override
  Future<List<AdminClassSummary>> classes({ClassLevel? level, String? search}) async {
    final result = await _remote.listClasses(
      level: level == null ? null : adminLevelToApi(level),
      search: search,
    );
    return result.items
        .whereType<Map<String, dynamic>>()
        .map(adminClassSummaryFromJson)
        .toList();
  }

  @override
  Future<AdminClassDetail?> classDetail(String classId) async {
    try {
      final data = await _remote.getClass(classId);
      return adminClassDetailFromJson(data);
    } on ApiException catch (e) {
      // Deleted class → null so callers show their empty state;
      // any other failure must surface.
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
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
  }) async {
    final data = await _remote.createClass(
      name: name,
      level: adminLevelToApi(level),
      department: department,
      capacity: capacity,
      description: description,
      forumEnabled: forumEnabled,
      entSyncEnabled: entSyncEnabled,
      draft: draft,
      referentId: referentId,
    );
    return data['id'] as String? ?? '';
  }

  @override
  Future<void> updateClass(String classId, Map<String, dynamic> fields) async {
    await _remote.updateClass(classId, fields);
  }

  @override
  Future<void> deleteClass(String classId) async {
    await _remote.deleteClass(classId);
  }

  @override
  Future<List<DepartmentInfo>> departments() async {
    final items = await _remote.listDepartments();
    return items.whereType<Map<String, dynamic>>().map((item) {
      return DepartmentInfo(
        name: (item['name'] as String?) ?? '',
        classCount: (item['classCount'] as num?)?.toInt() ?? 0,
      );
    }).where((department) => department.name.isNotEmpty).toList();
  }

  @override
  Future<List<AdminStudent>> students({String? search, String? classId}) async {
    final result = await _remote.listUsers(role: 'STUDENT', search: search);
    Set<String> assigned = const {};
    if (classId != null) {
      assigned = await classMemberIds(classId);
    }
    return result.items.whereType<Map<String, dynamic>>().map((item) {
      final id = item['id'] as String? ?? '';
      return adminStudentFromSafeUser(
        item,
        assignedClassId: assigned.contains(id) ? classId : null,
      );
    }).toList();
  }

  @override
  Future<List<AdminTeacher>> teachers({String? search, String? classId}) async {
    final result = await _remote.listUsers(role: 'TEACHER', search: search);
    final assignments = <String, Map<String, dynamic>>{};
    if (classId != null) {
      final data = await _remote.listTeacherAssignments(classId);
      final list = data['assignments'];
      if (list is List) {
        for (final item in list.whereType<Map<String, dynamic>>()) {
          final teacherId = item['teacherId'] as String?;
          if (teacherId != null) assignments[teacherId] = item;
        }
      }
    }
    return result.items.whereType<Map<String, dynamic>>().map((item) {
      final id = item['id'] as String? ?? '';
      final assignment = assignments[id];
      return adminTeacherFromSafeUser(
        item,
        subject: assignment?['subject'] as String?,
        weeklyHours: assignment?['weeklyHours'] as String?,
      );
    }).toList();
  }

  @override
  Future<Set<String>> classMemberIds(String classId) async {
    final result = await _remote.listMembers(classId);
    return result.items
        .whereType<Map<String, dynamic>>()
        .map((item) => item['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  @override
  Future<void> assignStudents(String classId, List<String> studentIds) async {
    await _remote.assignStudents(classId, studentIds);
  }

  @override
  Future<void> removeStudents(String classId, List<String> studentIds) async {
    await _remote.removeStudents(classId, studentIds);
  }

  @override
  Future<void> assignTeachers(
    String classId,
    List<TeacherAssignment> assignments,
  ) async {
    await _remote.assignTeachers(
      classId,
      assignments.map((assignment) => assignment.toJson()).toList(),
    );
  }

  @override
  Future<void> removeTeachers(String classId, List<String> teacherIds) async {
    await _remote.removeTeachers(classId, teacherIds);
  }

  @override
  Future<PlannerWeek> weekSchedule({
    required String classId,
    required String weekStart,
  }) async {
    final data = await _remote.getTimetable(
      classGroupId: classId,
      weekStart: weekStart,
    );
    return plannerWeekFromJson(data);
  }

  @override
  Future<FraudReportsPage> fraudReports({String? status, String? cursor}) async {
    final result = await _remote.listFraudReports(status: status, cursor: cursor);
    return FraudReportsPage(
      reports: result.items
          .whereType<Map<String, dynamic>>()
          .map(fraudReportFromJson)
          .toList(),
      nextCursor: result.meta['nextCursor'] as String?,
      hasMore: result.meta['hasMore'] as bool? ?? false,
    );
  }

  @override
  Future<FraudSummary> fraudSummary() async {
    final data = await _remote.getFraudSummary();
    return fraudSummaryFromJson(data);
  }

  @override
  Future<void> updateFraudReport(
    String id, {
    required FraudStatus status,
    String? resolution,
  }) async {
    await _remote.updateFraudReport(
      id,
      status: fraudStatusToApi(status),
      resolution: resolution,
    );
  }

  @override
  Future<void> updateTeacherApproval(String userId, String status) async {
    await _remote.updateTeacherApproval(userId, status);
  }
}

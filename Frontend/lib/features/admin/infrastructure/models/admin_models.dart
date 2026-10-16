import 'package:intl/intl.dart';

import '../../domain/entities/admin_person.dart';
import '../../domain/entities/fraud_report.dart';
import '../../domain/entities/managed_class.dart';
import '../../domain/entities/timetable.dart';

/// Parses the real admin API payloads
/// (`contracts/admin|users|groups|exams|videoconference.openapi.yaml`)
/// into domain entities. No fabricated values: every number comes from
/// the backend, every label stays a translation key resolved in UI.

ClassLevel _apiLevelToApp(String? level) {
  switch (level) {
    case 'MASTER':
      return ClassLevel.master;
    case 'DOCTORAT':
      return ClassLevel.doctorat;
    default:
      return ClassLevel.licence;
  }
}

String _apiLevelToApi(ClassLevel level) {
  switch (level) {
    case ClassLevel.master:
      return 'MASTER';
    case ClassLevel.doctorat:
      return 'DOCTORAT';
    case ClassLevel.licence:
      return 'LICENCE';
  }
}

/// Exposed for query params (GET /groups?level=...).
String adminLevelToApi(ClassLevel level) => _apiLevelToApi(level);

ClassLevel adminLevelFromApi(String? level) => _apiLevelToApp(level);

String _promoTag(Map<String, dynamic> json) {
  final department = json['department'] as String?;
  final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
  final year = createdAt?.year ?? DateTime.now().year;
  final scope = (department == null || department.trim().isEmpty)
      ? (json['level'] as String? ?? '')
      : department;
  return '$scope • $year–${year + 1}';
}

String _referentName(Map<String, dynamic> json) {
  final referent = json['referent'];
  if (referent is! Map<String, dynamic>) return '';
  final first = (referent['firstName'] as String? ?? '').trim();
  final last = (referent['lastName'] as String? ?? '').trim();
  return '$first $last'.trim();
}

bool _isPublished(Map<String, dynamic> json) => json['status'] == 'PUBLISHED';

String _classIcon(ClassLevel level) {
  switch (level) {
    case ClassLevel.master:
      return 'psychology';
    case ClassLevel.doctorat:
      return 'functions';
    case ClassLevel.licence:
      return 'school';
  }
}

AdminClassSummary adminClassSummaryFromJson(Map<String, dynamic> json) {
  final level = _apiLevelToApp(json['level'] as String?);
  return AdminClassSummary(
    id: json['id'] as String? ?? '',
    promoTag: _promoTag(json),
    statusKey: _isPublished(json) ? 'admin_active_badge' : 'admin_draft_badge',
    statusActive: _isPublished(json),
    title: json['name'] as String? ?? '',
    icon: _classIcon(level),
    students: (json['memberCount'] as num?)?.toInt() ?? 0,
    teachers: (json['teacherCount'] as num?)?.toInt() ?? 0,
    referent: _referentName(json),
    level: level,
  );
}

AdminClassDetail adminClassDetailFromJson(Map<String, dynamic> json) {
  final summary = adminClassSummaryFromJson(json);
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
    level: summary.level,
    capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    department: (json['department'] as String?) ?? '',
  );
}

String _personName(Map<String, dynamic> json) {
  final first = (json['firstName'] as String? ?? '').trim();
  final last = (json['lastName'] as String? ?? '').trim();
  final full = '$first $last'.trim();
  if (full.isNotEmpty) return full;
  return (json['email'] as String? ?? '').trim();
}

String? _initials(String name) {
  final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return null;
  final first = parts.first[0];
  final second = parts.length > 1 ? parts[1][0] : '';
  return '$first$second'.toUpperCase();
}

AdminStudent adminStudentFromSafeUser(
  Map<String, dynamic> json, {
  String? assignedClassId,
}) {
  final name = _personName(json);
  return AdminStudent(
    id: json['id'] as String? ?? '',
    name: name,
    email: json['email'] as String? ?? '',
    badge: '',
    initials: _initials(name),
    verified: json['emailVerified'] as bool? ?? false,
    assignedClassId: assignedClassId,
  );
}

AdminTeacher adminTeacherFromSafeUser(
  Map<String, dynamic> json, {
  String? subject,
  String? weeklyHours,
}) {
  final assigned = subject != null && subject.trim().isNotEmpty;
  final name = _personName(json);
  return AdminTeacher(
    id: json['id'] as String? ?? '',
    name: name,
    email: json['email'] as String? ?? '',
    specialty: assigned ? subject.trim() : '',
    department: '',
    availabilityKey: assigned ? 'admin_assigned_hours' : 'admin_not_assigned',
    availabilityArgs: assigned ? (weeklyHours ?? '') : '',
    subjectLabel: assigned ? subject.trim() : '',
    subjectValue: (weeklyHours != null && weeklyHours.trim().isNotEmpty)
        ? weeklyHours.trim()
        : 'admin_not_assigned',
    state: assigned ? PersonAssignState.assigned : PersonAssignState.unselected,
    initiallyAssigned: assigned,
    verified: json['emailVerified'] as bool? ?? false,
    approvalStatus: json['teacherApprovalStatus'] as String? ?? 'APPROVED',
  );
}

FraudSeverity _apiSeverityToApp(String? severity) {
  switch (severity) {
    case 'HIGH':
      return FraudSeverity.critical;
    default:
      return FraudSeverity.medium;
  }
}

FraudStatus _apiStatusToApp(String? status) {
  switch (status) {
    case 'IN_PROGRESS':
      return FraudStatus.ongoing;
    case 'CLOSED':
      return FraudStatus.closed;
    default:
      return FraudStatus.untreated;
  }
}

String _apiStatusToApi(FraudStatus status) {
  switch (status) {
    case FraudStatus.ongoing:
      return 'IN_PROGRESS';
    case FraudStatus.closed:
      return 'CLOSED';
    case FraudStatus.untreated:
      return 'UNTREATED';
  }
}

/// Exposed for query params (GET /fraud-reports?status=...).
String fraudStatusToApi(FraudStatus status) => _apiStatusToApi(status);

FraudReport fraudReportFromJson(Map<String, dynamic> json) {
  final occurredAt =
      DateTime.tryParse(json['occurredAt'] as String? ?? '') ?? DateTime.now();
  final closedAt = json['closedAt'] == null
      ? null
      : DateTime.tryParse(json['closedAt'] as String);
  String? studentName;
  String? studentCode;
  String? className;
  final student = json['student'];
  if (student is Map<String, dynamic>) {
    studentName = student['name'] as String?;
    studentCode = student['code'] as String?;
  }
  studentName = (studentName == null || studentName.trim().isEmpty)
      ? (json['studentName'] as String?)
      : studentName;
  final group = json['classGroup'];
  if (group is Map<String, dynamic>) {
    className = group['name'] as String?;
  }
  className = (className == null || className.trim().isEmpty)
      ? (json['className'] as String?)
      : className;
  final context = (json['context'] as String?)?.trim() ?? '';
  final classLabel = (className ?? '').trim();
  final subtitle = [context, classLabel].where((s) => s.isNotEmpty).join(' • ');
  final findings = json['findings'];
  return FraudReport(
    id: json['id'] as String? ?? '',
    severity: _apiSeverityToApp(json['severity'] as String?),
    status: _apiStatusToApp(json['status'] as String?),
    time: DateFormat('HH:mm').format(occurredAt.toLocal()),
    title: json['title'] as String? ?? '',
    subtitle: subtitle,
    studentName: (studentName ?? '').trim(),
    studentId: (studentCode ?? '').trim(),
    studentClass: classLabel,
    findings: findings is List
        ? findings.whereType<String>().toList()
        : const [],
    reason: (json['reason'] as String?)?.trim().isEmpty ?? true
        ? null
        : (json['reason'] as String).trim(),
    resolution: (json['resolution'] as String?)?.trim().isEmpty ?? true
        ? null
        : (json['resolution'] as String).trim(),
    closedDate: closedAt == null
        ? null
        : DateFormat('dd/MM/yyyy HH:mm').format(closedAt.toLocal()),
    occurredAt: occurredAt,
  );
}

FraudSummary fraudSummaryFromJson(Map<String, dynamic> json) {
  return FraudSummary(
    unresolved: (json['untreated'] as num?)?.toInt() ?? 0,
    inProgress: (json['inProgress'] as num?)?.toInt() ?? 0,
    resolvedThisMonth: (json['resolvedThisMonth'] as num?)?.toInt() ?? 0,
  );
}

PlannerEventKind _apiKindToApp(String? kind) {
  switch (kind) {
    case 'TP':
      return PlannerEventKind.tp;
    case 'TD':
      return PlannerEventKind.td;
    case 'BREAK':
      return PlannerEventKind.pause;
    case 'LUNCH':
      return PlannerEventKind.lunch;
    case 'FREE':
      return PlannerEventKind.free;
    default:
      return PlannerEventKind.cm;
  }
}

PlannerEvent plannerEventFromJson(Map<String, dynamic> json) {
  String? teacherName;
  final teacher = json['teacher'];
  if (teacher is Map<String, dynamic>) {
    teacherName = (teacher['name'] as String?)?.trim();
    if (teacherName != null && teacherName.isEmpty) teacherName = null;
  }
  final room = (json['room'] as String?)?.trim();
  final notes = json['statusNotes'];
  return PlannerEvent(
    id: json['id'] as String? ?? '',
    date: (json['date'] as String?) ?? '',
    start: json['start'] as String? ?? '',
    end: json['end'] as String? ?? '',
    kind: _apiKindToApp(json['kind'] as String?),
    title: json['title'] as String? ?? '',
    subtitle: (json['subtitle'] as String?)?.trim().isEmpty ?? true
        ? null
        : (json['subtitle'] as String).trim(),
    teacherName: teacherName,
    teacherInitials: teacherName == null ? null : _initials(teacherName),
    roomKey: (room == null || room.isEmpty) ? null : 'admin_room_label',
    roomValue: (room == null || room.isEmpty) ? null : room,
    statusLines: const [],
    statusNotes: notes is List ? notes.whereType<String>().toList() : const [],
  );
}

int _minutesOf(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return 0;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return h * 60 + m;
}

/// Total scheduled course time (CM/TP/TD) across the week, e.g. "7h30".
String scheduledHoursLabel(List<PlannerEvent> events) {
  var minutes = 0;
  for (final event in events) {
    if (event.kind != PlannerEventKind.cm &&
        event.kind != PlannerEventKind.tp &&
        event.kind != PlannerEventKind.td) {
      continue;
    }
    final duration = _minutesOf(event.end) - _minutesOf(event.start);
    if (duration > 0) minutes += duration;
  }
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '${hours}h' : '${hours}h${rest.toString().padLeft(2, '0')}';
}

/// Real overlap count between course events sharing a day.
int countOverlaps(List<PlannerEvent> events) {
  var conflicts = 0;
  final byDay = <String, List<PlannerEvent>>{};
  for (final event in events) {
    if (event.kind != PlannerEventKind.cm &&
        event.kind != PlannerEventKind.tp &&
        event.kind != PlannerEventKind.td) {
      continue;
    }
    if (event.date.isEmpty) continue;
    (byDay[event.date] ??= []).add(event);
  }
  for (final dayEvents in byDay.values) {
    dayEvents.sort((a, b) => _minutesOf(a.start).compareTo(_minutesOf(b.start)));
    for (var i = 1; i < dayEvents.length; i++) {
      if (_minutesOf(dayEvents[i].start) < _minutesOf(dayEvents[i - 1].end)) {
        conflicts++;
      }
    }
  }
  return conflicts;
}

PlannerWeek plannerWeekFromJson(Map<String, dynamic> json) {
  final weekStart =
      DateTime.tryParse((json['weekStart'] as String?) ?? '') ?? DateTime.now();
  final days = json['days'];
  final events = json['events'];
  final parsedEvents = events is List
      ? events.whereType<Map<String, dynamic>>().map(plannerEventFromJson).toList()
      : <PlannerEvent>[];
  final today = DateTime.now();
  final parsedDays = days is List
      ? days.whereType<Map<String, dynamic>>().map((day) {
          final date = DateTime.tryParse(day['date'] as String? ?? '') ?? weekStart;
          return PlannerDay(
            date: date,
            courseCount: (day['courseCount'] as num?)?.toInt() ?? 0,
            isToday: date.year == today.year &&
                date.month == today.month &&
                date.day == today.day,
          );
        }).toList()
      : <PlannerDay>[];
  return PlannerWeek(
    monday: DateTime(weekStart.year, weekStart.month, weekStart.day),
    days: parsedDays,
    hoursScheduled: scheduledHoursLabel(parsedEvents),
    conflicts: countOverlaps(parsedEvents),
    events: parsedEvents,
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../domain/entities/teacher_dashboard.dart';
import '../../infrastructure/datasources/groups_remote_datasource.dart';

/// Real teacher dashboard, built from the teacher's own classes
/// (`GET /api/v1/groups/mine`) and their timetables.
///
/// - No class assigned → empty [TeacherDashboardData] (the view shows the
///   contact-administration notice, never invented classes or figures).
/// - Next session = earliest upcoming CM/TP/TD slot across classes.
final teacherDashboardProvider =
    FutureProvider<TeacherDashboardData>((ref) async {
  // Keep the data alive during navigation so the provider doesn't dispose
  // mid-flight and trigger the '_dependents.isEmpty' assertion crash.
  final keepAlive = ref.keepAlive();

  final remote = GroupsRemoteDataSource(ref.watch(apiClientProvider));
  final groups = await remote.myGroups();
  final mine = groups
      .where((g) => g['myRole'] == 'TEACHER' || g['myRole'] == 'REFERENT')
      .toList();

  var totalStudents = 0;
  final subjects = <String>{};
  final classes = <TeacherDashboardClass>[];
  TeacherNextSlot? nextSlot;

  for (final group in mine) {
    final id = (group['id'] as String?) ?? '';
    final name = (group['name'] as String?) ?? '';
    final department = (group['department'] as String?)?.trim() ?? '';
    final createdAt =
        DateTime.tryParse(group['createdAt'] as String? ?? '');
    final year = createdAt?.year ?? DateTime.now().year;
    final scope = department.isEmpty
        ? ((group['level'] as String?) ?? '')
        : department;
    totalStudents += (group['memberCount'] as num?)?.toInt() ?? 0;
    final classSubjects = (group['mySubjects'] is List)
        ? (group['mySubjects'] as List).whereType<String>().toList()
        : <String>[];
    subjects.addAll(classSubjects);

    String? nextLabel;
    try {
      final week = await remote.weekTimetable(id);
      final upcoming = _nextSlot(week, name);
      if (upcoming != null) {
        nextLabel = '${upcoming.dayLabel} ${upcoming.start}';
        if (nextSlot == null || _isEarlier(upcoming, nextSlot)) {
          nextSlot = upcoming;
        }
      }
    } catch (_) {
      // A class without readable timetable simply has no next session.
    }

    classes.add(TeacherDashboardClass(
      id: id,
      name: name,
      promoTag: '$scope • $year–${year + 1}',
      memberCount: (group['memberCount'] as num?)?.toInt() ?? 0,
      subjects: classSubjects,
      nextSessionLabel: nextLabel,
    ));
  }

  // Once data is ready, release the keepAlive lock so the provider can
  // auto-dispose normally if no longer watched.
  keepAlive.close();

  return TeacherDashboardData(
    classes: classes,
    totalStudents: totalStudents,
    subjects: subjects.toList()..sort(),
    nextSlot: nextSlot,
  );
});

int _toMinutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

bool _isEarlier(TeacherNextSlot a, TeacherNextSlot b) {
  final dayCompare = a.dayLabel.compareTo(b.dayLabel);
  if (dayCompare != 0) return dayCompare < 0;
  return _toMinutes(a.start) < _toMinutes(b.start);
}

TeacherNextSlot? _nextSlot(Map<String, dynamic> week, String className) {
  final now = DateTime.now().toUtc();
  final todayKey =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final nowMinutes = now.hour * 60 + now.minute;
  final events = week['events'];
  if (events is! List) return null;

  TeacherNextSlot? best;
  for (final item in events.whereType<Map<String, dynamic>>()) {
    final kind = item['kind'] as String?;
    if (kind != 'CM' && kind != 'TP' && kind != 'TD') continue;
    final date = (item['date'] as String?) ?? '';
    final start = (item['start'] as String?) ?? '';
    if (date.isEmpty || start.isEmpty) continue;
    if (date.compareTo(todayKey) < 0) continue;
    if (date == todayKey && _toMinutes(start) <= nowMinutes) continue;
    final room = (item['room'] as String?)?.trim();
    final candidate = TeacherNextSlot(
      className: className,
      title: (item['title'] as String?) ?? '',
      dayLabel: date,
      start: start,
      room: (room == null || room.isEmpty) ? null : room,
    );
    if (best == null || _isEarlier(candidate, best)) best = candidate;
  }
  return best;
}

/// Teacher dashboard models (pure Dart).
///
/// Built from `GET /api/v1/groups/mine` (my classes, subjects) and
/// `GET /api/v1/videoconference/timetable` (next session). No fabricated
/// figures: stats without a server-side denominator (courses, corrections)
/// are not modelled.

/// A class taught by the current teacher.
class TeacherDashboardClass {
  final String id;
  final String name;
  final String promoTag;
  final int memberCount;
  final List<String> subjects;
  final String? nextSessionLabel;

  const TeacherDashboardClass({
    required this.id,
    required this.name,
    required this.promoTag,
    required this.memberCount,
    this.subjects = const [],
    this.nextSessionLabel,
  });
}

/// Next upcoming teaching slot across the teacher's classes, if any.
class TeacherNextSlot {
  final String className;
  final String title;
  final String dayLabel;
  final String start;
  final String? room;

  const TeacherNextSlot({
    required this.className,
    required this.title,
    required this.dayLabel,
    required this.start,
    this.room,
  });
}

class TeacherDashboardData {
  final List<TeacherDashboardClass> classes;
  final int totalStudents;
  final List<String> subjects;
  final TeacherNextSlot? nextSlot;

  const TeacherDashboardData({
    required this.classes,
    required this.totalStudents,
    required this.subjects,
    this.nextSlot,
  });
}

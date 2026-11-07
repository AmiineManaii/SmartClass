part of '../pages/class_detail_page.dart';
class _TeacherEntry {
  _TeacherEntry({
    required this.teacherId,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String teacherId;
  final String firstName;
  final String lastName;
  final String email;
  final List<_TaughtSubject> subjects = [];
}


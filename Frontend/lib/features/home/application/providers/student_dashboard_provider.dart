import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/student_assignment.dart';
import '../../domain/entities/student_class_membership.dart';
import '../../domain/entities/student_course_progress.dart';
import '../../domain/entities/today_live_session.dart';

/// Membership of the current student in a class.
///
/// Seam for `GET /api/v1/groups/memberships` (groups contract: planned,
/// see `contracts/README.md`). Resolves to `null` until wired: the dashboard
/// treats `null` as "no class joined" and shows the administration-contact
/// notice instead of inventing a class.
final studentClassMembershipProvider =
    FutureProvider<StudentClassMembership?>((ref) async {
  // TODO(groups-contract): fetch membership, e.g.
  // `ref.watch(groupsRepositoryProvider).myMembership()`.
  return null;
});

/// Today's live session, if the student really has a course today.
///
/// Seam for the today's-course calendar endpoint (videoconference module,
/// contract not yet written). Resolves to `null` until wired: the dashboard
/// hides the live widget instead of showing an invented session.
final studentTodayLiveProvider = FutureProvider<TodayLiveSession?>((ref) async {
  // TODO(videoconference-contract): fetch today's session, e.g.
  // `ref.watch(videoconferenceRepositoryProvider).todaySession()`.
  return null;
});

/// Courses authored by the teacher, displayed on the student side.
///
/// Seam for the courses module (contract not yet written). Empty until the
/// teacher adds courses; the section renders its empty state meanwhile.
final studentEnrolledCoursesProvider =
    FutureProvider<List<StudentCourseProgress>>((ref) async {
  // TODO(courses-contract): fetch enrolled courses, e.g.
  // `ref.watch(coursesRepositoryProvider).enrolled()`.
  return const [];
});

/// Homework assigned by the teacher.
///
/// Seam for the exams module (contract not yet written). Empty until the
/// teacher assigns homework; the section renders its empty state meanwhile.
final studentAssignmentsProvider =
    FutureProvider<List<StudentAssignment>>((ref) async {
  // TODO(exams-contract): fetch upcoming assignments, e.g.
  // `ref.watch(examsRepositoryProvider).upcoming()`.
  return const [];
});

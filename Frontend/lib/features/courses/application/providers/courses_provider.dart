import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../domain/entities/course_entry.dart';
import '../../domain/entities/generated_course.dart';
import '../../infrastructure/datasources/courses_remote_datasource.dart';
import '../../infrastructure/datasources/generated_courses_remote_datasource.dart';

/// "Mes cours" — real classes of the caller (`GET /api/v1/groups/mine`).
/// keepAlive so navigating away doesn't cancel an in-flight request.
final coursesDataSourceProvider = Provider<CoursesRemoteDataSource>(
  (ref) => CoursesRemoteDataSource(ref.watch(apiClientProvider)),
);

final myCoursesProvider = FutureProvider<List<CourseEntry>>((ref) async {
  final keepAlive = ref.keepAlive();
  final entries = await ref.watch(coursesDataSourceProvider).myClasses();
  keepAlive.close();
  return entries;
});

/// Filter of the chips bar: `all`, `in_progress` (PUBLISHED), `drafts`
/// (DRAFT). "Completed"/"Archived" don't exist server-side
/// (`ClassStatus = DRAFT | PUBLISHED`): no fake states.
final courseFilterProvider = StateProvider<String>((ref) => 'all');

/// Currently selected subject filter for the teacher's subject cards.
/// `null` means all subjects are shown.
final selectedSubjectProvider = StateProvider<String?>((ref) => null);

final filteredCoursesProvider = Provider<AsyncValue<List<CourseEntry>>>(
  (ref) {
    final selected = ref.watch(courseFilterProvider);
    return ref.watch(myCoursesProvider).whenData((entries) {
      if (selected == 'in_progress') {
        return entries.where((e) => e.isPublished).toList();
      }
      if (selected == 'drafts') {
        return entries.where((e) => e.isDraft).toList();
      }
      return entries;
    });
  },
);

/// Teacher-generated course library (`contracts/courses.openapi.yaml`).
/// keepAlive so navigating to the reader doesn't cancel in-flight lists.
final generatedCoursesDataSourceProvider =
    Provider<GeneratedCoursesRemoteDataSource>(
  (ref) => GeneratedCoursesRemoteDataSource(ref.watch(apiClientProvider)),
);

/// Own generated courses, drafts + published (TEACHER or ADMIN).
final myGeneratedCoursesProvider =
    FutureProvider<List<GeneratedCourse>>((ref) async {
  final keepAlive = ref.keepAlive();
  final courses =
      await ref.watch(generatedCoursesDataSourceProvider).myCourses();
  keepAlive.close();
  return courses;
});

/// Validated courses readable by every authenticated user (students too).
final publishedCoursesProvider =
    FutureProvider<List<GeneratedCourse>>((ref) async {
  final keepAlive = ref.keepAlive();
  final courses =
      await ref.watch(generatedCoursesDataSourceProvider).publishedCourses();
  keepAlive.close();
  return courses;
});

/// Full course with Markdown body (route param of the reader page).
final generatedCourseProvider =
    FutureProvider.family<GeneratedCourse, String>((ref, id) async {
  return ref.watch(generatedCoursesDataSourceProvider).getCourse(id);
});

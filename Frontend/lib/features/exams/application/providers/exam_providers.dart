import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../domain/entities/exam_attempt.dart';
import '../../domain/entities/exam_class_option.dart';
import '../../domain/entities/exam_course_option.dart';
import '../../domain/entities/exam_definition.dart';
import '../../domain/entities/exam_monitoring.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../infrastructure/datasources/exam_classes_datasource.dart';
import '../../infrastructure/datasources/exam_remote_datasource.dart';
import '../../infrastructure/repositories/exam_repository_impl.dart';
import '../controllers/exam_attempt_controller.dart';

/// Real API adapters. No mock data source exists in this feature.
final examRemoteDataSourceProvider = Provider<ExamRemoteDataSource>(
  (ref) => ExamRemoteDataSource(ref.watch(apiClientProvider)),
);

final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => ExamRepositoryImpl(remote: ref.watch(examRemoteDataSourceProvider)),
);

final examClassesDataSourceProvider = Provider<ExamClassesDataSource>(
  (ref) => ExamClassesDataSource(ref.watch(apiClientProvider)),
);

/// Classes where the caller is a teacher/referent. Exam authoring never
/// offers a class the caller only attends as a student.
final examClassesProvider = FutureProvider<List<ExamClassOption>>((ref) async {
  final keepAlive = ref.keepAlive();
  final classes = await ref.watch(examClassesDataSourceProvider).myClasses();
  keepAlive.close();
  return classes.where((option) => option.isTeacher).toList();
});

/// Published + validated courses of one class, offered as AI exam sources.
/// `autoDispose` refreshes the list each time the AI dialog is opened.
final examClassCoursesProvider =
    FutureProvider.autoDispose.family<List<ExamCourseOption>, String>(
      (ref, classGroupId) =>
          ref.watch(examRepositoryProvider).listClassCourses(classGroupId),
    );

/// Teacher: every exam authored by the caller (all statuses).
final myExamsProvider = FutureProvider<List<ExamSummary>>((ref) async {
  final keepAlive = ref.keepAlive();
  final exams = await ref.watch(examRepositoryProvider).listMyExams();
  keepAlive.close();
  return exams;
});

/// Student: published exams addressed to the caller's classes, with the
/// server-computed availability and attempt state.
final availableExamsProvider = FutureProvider<List<AvailableExam>>((ref) async {
  final keepAlive = ref.keepAlive();
  final exams = await ref.watch(examRepositoryProvider).listAvailableExams();
  keepAlive.close();
  return exams;
});

/// Teacher exam detail (includes the correction).
final teacherExamProvider = FutureProvider.family<ExamDetail, String>(
  (ref, examId) => ref.watch(examRepositoryProvider).getTeacherExam(examId),
);

final examResultsProvider = FutureProvider.family<ExamResults, String>(
  (ref, examId) => ref.watch(examRepositoryProvider).getResults(examId),
);

typedef ExamMonitoringArgs = ({String examId, String attemptId});

final examMonitoringProvider =
    FutureProvider.family<AttemptMonitoring, ExamMonitoringArgs>(
      (ref, args) => ref
          .watch(examRepositoryProvider)
          .getAttemptMonitoring(
            examId: args.examId,
            attemptId: args.attemptId,
          ),
    );

/// Dedicated student result, only fetched after release.
final studentResultProvider = FutureProvider.family<StudentResult, String>(
  (ref, examId) => ref.watch(examRepositoryProvider).getStudentResult(examId),
);

/// One controller per exam attempt route. `autoDispose` prevents leaking a
/// timer when the student leaves the page.
final examAttemptControllerProvider =
    StateNotifierProvider.autoDispose
        .family<ExamAttemptController, ExamAttemptState, String>(
          (ref, examId) => ExamAttemptController(
            repository: ref.watch(examRepositoryProvider),
            examId: examId,
          ),
        );

/// Selected filter on the teacher exam list.
final teacherExamFilterProvider = StateProvider<String>((ref) => 'all');

/// Selected filter on the student exam list.
final studentExamFilterProvider = StateProvider<String>((ref) => 'all');

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../infrastructure/datasources/ai_course_remote_datasource.dart';

final aiCourseRemoteDataSourceProvider = Provider<AiCourseRemoteDataSource>((ref) {
  return AiCourseRemoteDataSource(ref.watch(apiClientProvider));
});

/// Subjects the teacher really teaches (their assignments).
/// Empty when the teacher has no class yet.
final aiTeacherSubjectsProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(aiCourseRemoteDataSourceProvider).myTeachingSubjects();
});

/// Local model reachability (never throws: `available: false` when down).
final aiModelStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    return await ref.watch(aiCourseRemoteDataSourceProvider).status();
  } catch (_) {
    return const {'available': false, 'model': ''};
  }
});

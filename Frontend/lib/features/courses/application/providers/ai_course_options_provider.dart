import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/datasources/mock_ai_course_options_datasource.dart';

final mockAiCourseOptionsDataSourceProvider = Provider<MockAiCourseOptionsDataSource>((ref) {
  return const MockAiCourseOptionsDataSource();
});

final aiCourseSubjectsProvider = Provider<List<String>>((ref) {
  return ref.watch(mockAiCourseOptionsDataSourceProvider).subjects();
});

final aiCourseLevelsProvider = Provider<List<String>>((ref) {
  return ref.watch(mockAiCourseOptionsDataSourceProvider).levels();
});

final aiCourseSuggestionChipsProvider = Provider<List<AiSuggestionChip>>((ref) {
  return ref.watch(mockAiCourseOptionsDataSourceProvider).suggestionChips();
});

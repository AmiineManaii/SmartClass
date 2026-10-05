import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/datasources/mock_auth_options_datasource.dart';

final mockAuthOptionsDataSourceProvider = Provider<MockAuthOptionsDataSource>((ref) {
  return const MockAuthOptionsDataSource();
});

final authInstitutionsProvider = Provider<List<String>>((ref) {
  return ref.watch(mockAuthOptionsDataSourceProvider).institutions();
});

final authStudyLevelsProvider = Provider<List<String>>((ref) {
  return ref.watch(mockAuthOptionsDataSourceProvider).studyLevels();
});

final authInterestsProvider = Provider<List<AuthInterestOption>>((ref) {
  return ref.watch(mockAuthOptionsDataSourceProvider).interests();
});

final authInterestLabelsProvider = Provider<Map<String, Map<String, String>>>((ref) {
  return ref.watch(mockAuthOptionsDataSourceProvider).interestLabels();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'health_remote_datasource.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokens: ref.watch(tokenStorageProvider));
});

final healthRemoteDataSourceProvider = Provider<HealthRemoteDataSource>((ref) {
  return HealthRemoteDataSource(ref.watch(apiClientProvider));
});

/// One-shot server health snapshot for diagnostics (Settings screen).
final serverHealthProvider = FutureProvider<HealthStatus>((ref) {
  return ref.watch(healthRemoteDataSourceProvider).readiness();
});

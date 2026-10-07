import 'api_client.dart';
import 'api_exception.dart';

/// Diagnostic probes living outside `/api/v1` (see `health.openapi.yaml`).
/// Used for the Settings server-status row — not for polling.
class HealthStatus {
  final bool alive;
  final bool ready;
  final int? dbLatencyMs;

  const HealthStatus({required this.alive, required this.ready, this.dbLatencyMs});
}

class HealthRemoteDataSource {
  HealthRemoteDataSource(this._client);

  final ApiClient _client;

  Future<bool> liveness() async {
    try {
      await _client.get<dynamic>('/health/live', authenticated: false);
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<HealthStatus> readiness() async {
    final alive = await liveness();
    try {
      final res =
          await _client.get<dynamic>('/health/ready', authenticated: false);
      final body = res.data;
      int? latency;
      if (body is Map<String, dynamic>) {
        final services = body['services'];
        if (services is Map<String, dynamic>) {
          final database = services['database'];
          if (database is Map<String, dynamic>) {
            final value = database['latencyMs'];
            if (value is num) latency = value.toInt();
          }
        }
      }
      return HealthStatus(alive: alive, ready: true, dbLatencyMs: latency);
    } on ApiException catch (e) {
      if (e.statusCode == 503) {
        return HealthStatus(alive: alive, ready: false);
      }
      return HealthStatus(alive: alive, ready: false);
    }
  }
}

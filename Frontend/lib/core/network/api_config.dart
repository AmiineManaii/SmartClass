import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central configuration for the SmartClass backend API.
///
/// Mirrors `Backend/.env.example` (PORT=3000) and `contracts/README.md`:
/// modules live under `/api/v1`, health probes at the root `/health/*`.
/// The base URL is read from the app `.env` (`API_BASE_URL`) and can be
/// overridden at build time: `flutter run --dart-define=API_BASE_URL=...`
class ApiConfig {
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (dotenv.isInitialized) {
      final fromEnv = dotenv.maybeGet('API_BASE_URL');
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    }

    return 'http://localhost:3000';
  }

  static const String apiPrefix = '/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(minutes: 3);

  /// Long generations stream for minutes (local LLM: TTFT alone can
  /// exceed 20 s when server-side tools run before the first token).
  /// Must stay well above the backend SSE heartbeat interval (10 s).
  static const Duration streamReceiveTimeout = Duration(minutes: 10);

  static const String accessTokenKey = 'smartclass_access_token';
  static const String refreshTokenKey = 'smartclass_refresh_token';
}

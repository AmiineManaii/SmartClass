import 'package:flutter/foundation.dart';

/// Central configuration for the SmartClass backend API.
///
/// Mirrors `Backend/.env.example` (PORT=3000) and `contracts/README.md`:
/// modules live under `/api/v1`, health probes at the root `/health/*`.
/// Override at build time: `flutter run --dart-define=API_BASE_URL=...`
class ApiConfig {
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    // Sur Android (émulateur), localhost (127.0.0.1) pointe sur le téléphone lui-même.
    // 10.0.2.2 est l'IP spéciale pour accéder à l'hôte (PC).
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
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

import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

/// Persists the auth session tokens (SharedPreferences).
/// Synchronous in-memory API is intentionally avoided: every access
/// goes through the async SharedPreferences instance.
class TokenStorage {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(ApiConfig.accessTokenKey, accessToken);
    await prefs.setString(ApiConfig.refreshTokenKey, refreshToken);
  }

  Future<String?> readAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(ApiConfig.accessTokenKey);
  }

  Future<String?> readRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(ApiConfig.refreshTokenKey);
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(ApiConfig.accessTokenKey);
    await prefs.remove(ApiConfig.refreshTokenKey);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

/// Persists the auth session tokens (SharedPreferences/LocalStorage).
/// Synchronous in-memory API is intentionally avoided: every access
/// goes through the async SharedPreferences instance.
class TokenStorage {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static const String rememberMeKey = 'smartclass_remember_me';
  static const String savedEmailKey = 'smartclass_saved_email';
  static const String sessionTimestampKey = 'smartclass_session_timestamp';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    bool rememberMe = true,
    String? email,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(ApiConfig.accessTokenKey, accessToken);
    await prefs.setString(ApiConfig.refreshTokenKey, refreshToken);
    await prefs.setBool(rememberMeKey, rememberMe);
    await prefs.setInt(sessionTimestampKey, DateTime.now().millisecondsSinceEpoch);
    if (rememberMe && email != null && email.isNotEmpty) {
      await prefs.setString(savedEmailKey, email);
    } else if (!rememberMe) {
      await prefs.remove(savedEmailKey);
    }
  }

  Future<String?> readAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(ApiConfig.accessTokenKey);
  }

  Future<String?> readRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(ApiConfig.refreshTokenKey);
  }

  Future<bool> isRememberMe() async {
    final prefs = await _prefs;
    return prefs.getBool(rememberMeKey) ?? true;
  }

  Future<String?> getSavedEmail() async {
    final prefs = await _prefs;
    return prefs.getString(savedEmailKey);
  }

  Future<void> clear({bool keepSavedEmail = true}) async {
    final prefs = await _prefs;
    final savedEmail = keepSavedEmail ? prefs.getString(savedEmailKey) : null;
    await prefs.remove(ApiConfig.accessTokenKey);
    await prefs.remove(ApiConfig.refreshTokenKey);
    await prefs.remove(rememberMeKey);
    await prefs.remove(sessionTimestampKey);
    if (!keepSavedEmail && savedEmail != null) {
      await prefs.remove(savedEmailKey);
    }
  }

  Future<void> saveAcademicProfile({
    String? userIdOrEmail,
    String? institution,
    String? faculty,
    String? major,
    String? studentId,
    String? bio,
  }) async {
    final prefs = await _prefs;
    final prefix = 'smartclass_profile_${(userIdOrEmail != null && userIdOrEmail.isNotEmpty) ? userIdOrEmail : 'default'}';
    if (institution != null) {
      await prefs.setString('${prefix}_institution', institution);
      await prefs.setString('smartclass_current_institution', institution);
    }
    if (faculty != null) await prefs.setString('${prefix}_faculty', faculty);
    if (major != null) await prefs.setString('${prefix}_major', major);
    if (studentId != null) await prefs.setString('${prefix}_student_id', studentId);
    if (bio != null) await prefs.setString('${prefix}_bio', bio);
  }

  Future<Map<String, String?>> readAcademicProfile(String? userIdOrEmail) async {
    final prefs = await _prefs;
    final prefix = 'smartclass_profile_${(userIdOrEmail != null && userIdOrEmail.isNotEmpty) ? userIdOrEmail : 'default'}';
    final globalInst = prefs.getString('smartclass_current_institution');
    return {
      'institution': prefs.getString('${prefix}_institution') ?? globalInst,
      'faculty': prefs.getString('${prefix}_faculty'),
      'major': prefs.getString('${prefix}_major'),
      'studentId': prefs.getString('${prefix}_student_id'),
      'bio': prefs.getString('${prefix}_bio'),
    };
  }
}

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
    bool rememberMe = false,
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
    return prefs.getBool(rememberMeKey) ?? false;
  }

  Future<String?> getSavedEmail() async {
    final prefs = await _prefs;
    return prefs.getString(savedEmailKey);
  }

  Future<void> clear({bool keepSavedEmail = true}) async {
    final prefs = await _prefs;
    final savedEmail = keepSavedEmail ? prefs.getString(savedEmailKey) : null;
    final rememberMe = keepSavedEmail ? (prefs.getBool(rememberMeKey) ?? false) : false;
    await prefs.remove(ApiConfig.accessTokenKey);
    await prefs.remove(ApiConfig.refreshTokenKey);
    await prefs.remove(sessionTimestampKey);
    if (!keepSavedEmail) {
      await prefs.remove(rememberMeKey);
      await prefs.remove(savedEmailKey);
    } else {
      await prefs.setBool(rememberMeKey, rememberMe);
      if (savedEmail != null) {
        await prefs.setString(savedEmailKey, savedEmail);
      }
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
    if (faculty != null) {
      await prefs.setString('${prefix}_faculty', faculty);
      await prefs.setString('smartclass_current_faculty', faculty);
    }
    if (major != null) {
      await prefs.setString('${prefix}_major', major);
      await prefs.setString('smartclass_current_major', major);
    }
    if (studentId != null) {
      await prefs.setString('${prefix}_student_id', studentId);
      await prefs.setString('smartclass_current_student_id', studentId);
    }
    if (bio != null) {
      await prefs.setString('${prefix}_bio', bio);
      await prefs.setString('smartclass_current_bio', bio);
    }
  }

  Future<Map<String, String?>> readAcademicProfile(String? userIdOrEmail) async {
    final prefs = await _prefs;
    final prefix = 'smartclass_profile_${(userIdOrEmail != null && userIdOrEmail.isNotEmpty) ? userIdOrEmail : 'default'}';
    return {
      'institution': prefs.getString('${prefix}_institution') ?? prefs.getString('smartclass_current_institution'),
      'faculty': prefs.getString('${prefix}_faculty') ?? prefs.getString('smartclass_current_faculty'),
      'major': prefs.getString('${prefix}_major') ?? prefs.getString('smartclass_current_major'),
      'studentId': prefs.getString('${prefix}_student_id') ?? prefs.getString('smartclass_current_student_id'),
      'bio': prefs.getString('${prefix}_bio') ?? prefs.getString('smartclass_current_bio'),
    };
  }
}

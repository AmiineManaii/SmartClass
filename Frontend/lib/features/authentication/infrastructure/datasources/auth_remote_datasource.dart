import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';

/// One method per implemented backend endpoint
/// (`contracts/auth.openapi.yaml`, base `/api/v1`).
/// Returns the raw `{ data: ... }` envelope content; parsing lives in models.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final ApiClient _client;

  static String get _base => ApiConfig.apiPrefix;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? role,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/register',
      authenticated: false,
      data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': ?role,
      },
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/verify-email',
      authenticated: false,
      data: {'email': email, 'code': code},
    );
    return apiEnvelope(res);
  }

  Future<bool> checkEmail({required String email}) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/check-email',
      authenticated: false,
      data: {'email': email},
    );
    final data = apiEnvelope(res);
    return data['available'] as bool? ?? true;
  }

  Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/resend-verification',
      authenticated: false,
      data: {'email': email},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/login',
      authenticated: false,
      data: {
        'email': email,
        'password': password,
        'rememberMe': rememberMe,
      },
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> refresh({required String refreshToken}) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/refresh',
      authenticated: false,
      data: {'refreshToken': refreshToken},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/forgot-password',
      authenticated: false,
      data: {'email': email},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/reset-password',
      authenticated: false,
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> logout({String? refreshToken}) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/logout',
      authenticated: false,
      data: {'refreshToken': ?refreshToken},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _client.get<dynamic>('$_base/auth/me');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _client.get<dynamic>('$_base/auth/profile');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? birthDate,
    bool? onboardingCompleted,
  }) async {
    final res = await _client.patch<dynamic>(
      '$_base/auth/profile',
      data: {
        'firstName': ?firstName,
        'lastName': ?lastName,
        'birthDate': ?birthDate,
        'onboardingCompleted': ?onboardingCompleted,
      },
    );
    return apiEnvelope(res);
  }

  /// Persists the onboarding role (RG1, assign-once).
  /// Backend: `PATCH /api/v1/users/me/role` — TEACHER/STUDENT only,
  /// ADMIN is never self-assignable (403). Returns the `{ data: ... }`
  /// envelope content (`{ message, accessToken, refreshToken, expiresIn, user }`).
  Future<Map<String, dynamic>> setMyRole({required String role}) async {
    final res = await _client.patch<dynamic>(
      '$_base/users/me/role',
      data: {'role': role},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> setup2fa() async {
    final res = await _client.post<dynamic>('$_base/auth/2fa/setup');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> verify2fa({required String code}) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/2fa/verify',
      data: {'code': code},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> disable2fa({String? code, String? password}) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/2fa/disable',
      data: {
        'code': ?code,
        'password': ?password,
      },
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> authenticate2fa({
    required String tempToken,
    required String code,
    bool rememberMe = false,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/2fa/authenticate',
      authenticated: false,
      data: {
        'tempToken': tempToken,
        'code': code,
        'rememberMe': rememberMe,
      },
    );
    return apiEnvelope(res);
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 20}) async {
    final res = await _client.get<dynamic>('$_base/auth/audit-logs?limit=$limit');
    final body = res.data;
    if (body is Map<String, dynamic> && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    return apiEnvelope(res);
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final res = await _client.get<dynamic>('$_base/auth/sessions');
    final body = res.data;
    if (body is Map<String, dynamic> && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> revokeSession(String sessionId) async {
    final res = await _client.delete<dynamic>('$_base/auth/sessions/$sessionId');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> revokeAllOtherSessions() async {
    final res = await _client.delete<dynamic>('$_base/auth/sessions');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> freezeAccount() async {
    final res = await _client.post<dynamic>('$_base/auth/freeze-account');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> deleteAccount({
    required String passwordConfirmation,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/delete-account',
      data: {
        'passwordConfirmation': passwordConfirmation,
      },
    );
    return apiEnvelope(res);
  }
}


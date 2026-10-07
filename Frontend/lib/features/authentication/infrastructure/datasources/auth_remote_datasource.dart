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
        if (role case final r?) 'role': r,
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
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/auth/login',
      authenticated: false,
      data: {'email': email, 'password': password},
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
      data: {if (refreshToken case final t?) 'refreshToken': t},
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
        if (firstName case final v?) 'firstName': v,
        if (lastName case final v?) 'lastName': v,
        if (birthDate case final v?) 'birthDate': v,
        if (onboardingCompleted case final v?) 'onboardingCompleted': v,
      },
    );
    return apiEnvelope(res);
  }
}

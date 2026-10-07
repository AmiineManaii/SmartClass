import '../../../../core/error/failures.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_session.dart';
import '../models/user_model.dart';

/// [AuthRepository] backed by the real API. Translates [ApiException]
/// into [Failure] and persists rotated tokens in [TokenStorage].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remote, required TokenStorage tokens})
      : _remote = remote,
        _tokens = tokens;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      throw apiExceptionToFailure(e);
    }
  }

  Future<AuthenticatedSession> _persist(AuthenticatedSession session) async {
    await _tokens.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  @override
  Future<RegistrationResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? role,
  }) {
    return _guard(() async {
      final data = await _remote.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: UserModel.appRoleToApi(role),
      );
      return AuthSessionModel.fromJson(data).toRegistrationResult();
    });
  }

  @override
  Future<AuthenticatedSession> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final data = await _remote.verifyEmail(email: email, code: code);
      final session = AuthSessionModel.fromJson(data).toAuthenticatedSession();
      return _persist(session);
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        throw const AuthFailure('Invalid or expired code', code: 'INVALID_CODE');
      }
      throw apiExceptionToFailure(e);
    }
  }

  @override
  Future<String> resendVerification({required String email}) {
    return _guard(() async {
      final data = await _remote.resendVerification(email: email);
      return data['message'] as String? ?? '';
    });
  }

  @override
  Future<AuthenticatedSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _remote.login(email: email, password: password);
      final session = AuthSessionModel.fromJson(data).toAuthenticatedSession();
      return _persist(session);
    } on ApiException catch (e) {
      throw apiExceptionToFailure(e);
    }
  }

  @override
  Future<AuthenticatedSession> refreshSession({required String refreshToken}) {
    return _guard(() async {
      final data = await _remote.refresh(refreshToken: refreshToken);
      final session = AuthSessionModel.fromJson(data).toAuthenticatedSession();
      return _persist(session);
    });
  }

  @override
  Future<String> forgotPassword({required String email}) {
    return _guard(() async {
      final data = await _remote.forgotPassword(email: email);
      return data['message'] as String? ?? '';
    });
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final data = await _remote.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return data['message'] as String? ?? '';
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        throw const AuthFailure('Invalid or expired code', code: 'INVALID_CODE');
      }
      throw apiExceptionToFailure(e);
    }
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    final token = refreshToken ?? await _tokens.readRefreshToken();
    try {
      await _remote.logout(refreshToken: token);
    } catch (_) {
      // Best effort: local session is cleared regardless.
    } finally {
      await _tokens.clear();
    }
  }

  @override
  Future<UserEntity> getMe() {
    return _guard(() async {
      final data = await _remote.getMe();
      final user = data['user'];
      if (user is! Map<String, dynamic>) {
        throw const ApiException(message: 'Unexpected response format');
      }
      return UserModel.fromJson(user).toEntity();
    });
  }

  @override
  Future<UserEntity> getProfile() {
    return _guard(() async {
      final data = await _remote.getProfile();
      final user = data['user'];
      if (user is! Map<String, dynamic>) {
        throw const ApiException(message: 'Unexpected response format');
      }
      return UserModel.fromJson(user).toEntity();
    });
  }

  @override
  Future<UserEntity> updateProfile({
    String? firstName,
    String? lastName,
    String? birthDate,
    bool? onboardingCompleted,
  }) {
    return _guard(() async {
      final data = await _remote.updateProfile(
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
        onboardingCompleted: onboardingCompleted,
      );
      final user = data['user'];
      if (user is! Map<String, dynamic>) {
        throw const ApiException(message: 'Unexpected response format');
      }
      return UserModel.fromJson(user).toEntity();
    });
  }
}

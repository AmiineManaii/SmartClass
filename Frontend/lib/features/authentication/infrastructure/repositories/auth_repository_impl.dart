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
      // ignore: prefer_initializing_formals
      : _remote = remote,
        // ignore: prefer_initializing_formals
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

  Future<AuthenticatedSession> _persist(
    AuthenticatedSession session, {
    bool rememberMe = false,
    String? email,
  }) async {
    await _tokens.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      rememberMe: rememberMe,
      email: email,
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
      return _persist(session, email: email);
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        throw const AuthFailure('Invalid or expired code', code: 'INVALID_CODE');
      }
      throw apiExceptionToFailure(e);
    }
  }

  @override
  Future<bool> checkEmailAvailability({required String email}) {
    return _guard(() => _remote.checkEmail(email: email));
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
    bool rememberMe = false,
  }) async {
    try {
      final data = await _remote.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      if (data['twoFactorRequired'] == true) {
        final tempToken = data['tempToken'] as String? ?? '';
        final userJson = data['user'];
        final user = userJson is Map<String, dynamic>
            ? UserModel.fromJson(userJson).toEntity()
            : null;
        throw TwoFactorRequiredFailure(tempToken, user: user);
      }
      final session = AuthSessionModel.fromJson(data).toAuthenticatedSession();
      return _persist(session, rememberMe: rememberMe, email: email);
    } on ApiException catch (e) {
      throw apiExceptionToFailure(e);
    }
  }

  @override
  Future<AuthenticatedSession> refreshSession({required String refreshToken}) {
    return _guard(() async {
      final data = await _remote.refresh(refreshToken: refreshToken);
      final session = AuthSessionModel.fromJson(data).toAuthenticatedSession();
      final isRemember = await _tokens.isRememberMe();
      final email = await _tokens.getSavedEmail();
      return _persist(session, rememberMe: isRemember, email: email);
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

  @override
  Future<AuthenticatedSession> setMyRole({required String role}) {
    return _guard(() async {
      final apiRole = UserModel.appRoleToApi(role) ?? role.toUpperCase();
      final data = await _remote.setMyRole(role: apiRole);
      // Response envelope content: { message, accessToken, refreshToken, expiresIn, user }.
      final session = AuthSessionModel.fromJson(data).toAuthenticatedSession();
      return _persist(session);
    });
  }

  @override
  Future<Map<String, dynamic>> setup2fa() {
    return _guard(() async {
      return await _remote.setup2fa();
    });
  }

  @override
  Future<bool> verify2fa({required String code}) {
    return _guard(() async {
      final data = await _remote.verify2fa(code: code);
      return data['success'] as bool? ?? true;
    });
  }

  @override
  Future<bool> disable2fa({String? code, String? password}) {
    return _guard(() async {
      final data = await _remote.disable2fa(code: code, password: password);
      return data['success'] as bool? ?? true;
    });
  }

  @override
  Future<AuthenticatedSession> authenticate2fa({
    required String tempToken,
    required String code,
    bool rememberMe = false,
  }) {
    return _guard(() async {
      final data = await _remote.authenticate2fa(
        tempToken: tempToken,
        code: code,
        rememberMe: rememberMe,
      );
      final session = AuthSessionModel.fromJson(data).toAuthenticatedSession();
      return _persist(session, rememberMe: rememberMe, email: session.user.email);
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 20}) {
    return _guard(() async {
      return await _remote.getAuditLogs(limit: limit);
    });
  }

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _guard(() async {
      final data = await _remote.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return data['message'] as String? ?? 'Mot de passe modifié avec succès.';
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getSessions() {
    return _guard(() async {
      return await _remote.getSessions();
    });
  }

  @override
  Future<void> revokeSession(String sessionId) {
    return _guard(() async {
      await _remote.revokeSession(sessionId);
    });
  }

  @override
  Future<void> revokeAllOtherSessions() {
    return _guard(() async {
      await _remote.revokeAllOtherSessions();
    });
  }

  @override
  Future<String> freezeAccount() {
    return _guard(() async {
      final data = await _remote.freezeAccount();
      await _tokens.clear();
      return data['message'] as String? ?? 'Compte gelé avec succès.';
    });
  }

  @override
  Future<String> deleteAccount({required String passwordConfirmation}) {
    return _guard(() async {
      final data = await _remote.deleteAccount(passwordConfirmation: passwordConfirmation);
      await _tokens.clear();
      return data['message'] as String? ?? 'Compte supprimé définitivement.';
    });
  }
}


import '../entities/user_entity.dart';

/// Authenticated session returned by login / email verification / refresh.
class AuthenticatedSession {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserEntity user;

  const AuthenticatedSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });
}

/// Registration result: no tokens are issued until email verification.
class RegistrationResult {
  final UserEntity user;
  final String message;

  const RegistrationResult({required this.user, required this.message});
}

/// Auth repository contract. Covers every implemented backend endpoint
/// (`contracts/auth.openapi.yaml`). Implementations throw [Failure]
/// (see `lib/core/error/failures.dart`) — never raw exceptions.
abstract class AuthRepository {
  Future<RegistrationResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? role,
  });

  Future<AuthenticatedSession> verifyEmail({
    required String email,
    required String code,
  });

  Future<String> resendVerification({required String email});

  Future<AuthenticatedSession> login({
    required String email,
    required String password,
  });

  Future<AuthenticatedSession> refreshSession({required String refreshToken});

  Future<String> forgotPassword({required String email});

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<void> logout({String? refreshToken});

  Future<UserEntity> getMe();

  Future<UserEntity> getProfile();

  Future<UserEntity> updateProfile({
    String? firstName,
    String? lastName,
    String? birthDate,
    bool? onboardingCompleted,
  });
}

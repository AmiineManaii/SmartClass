import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import 'user_model.dart';

/// Parses login / verify-email / refresh payloads:
/// `{ message?, accessToken, refreshToken, expiresIn, user? }`.
class AuthSessionModel {
  final String? message;
  final String? accessToken;
  final String? refreshToken;
  final int expiresIn;
  final UserModel? user;

  const AuthSessionModel({
    this.message,
    this.accessToken,
    this.refreshToken,
    this.expiresIn = 900,
    this.user,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return AuthSessionModel(
      message: json['message'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 900,
      user: userJson is Map<String, dynamic> ? UserModel.fromJson(userJson) : null,
    );
  }

  AuthenticatedSession toAuthenticatedSession() {
    return AuthenticatedSession(
      accessToken: accessToken ?? '',
      refreshToken: refreshToken ?? '',
      expiresIn: expiresIn,
      user: user?.toEntity() ??
          const UserEntity(id: '', email: '', firstName: '', lastName: ''),
    );
  }

  RegistrationResult toRegistrationResult() {
    return RegistrationResult(
      user: user?.toEntity() ??
          const UserEntity(id: '', email: '', firstName: '', lastName: ''),
      message: message ?? '',
    );
  }
}

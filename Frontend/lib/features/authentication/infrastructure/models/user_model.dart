import '../../domain/entities/user_entity.dart';

/// Parses the backend `SafeUser` object (`contracts/auth.openapi.yaml`).
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? role;
  final String? birthDate;
  final String status;
  final bool emailVerified;
  final bool onboardingCompleted;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role,
    this.birthDate,
    this.status = 'ACTIVE',
    this.emailVerified = false,
    this.onboardingCompleted = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      role: _apiRoleToApp(json['role'] as String?),
      birthDate: json['birthDate'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      emailVerified: json['emailVerified'] as bool? ?? false,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      birthDate: birthDate,
      status: status,
      emailVerified: emailVerified,
      onboardingCompleted: onboardingCompleted,
    );
  }

  /// Backend enums (TEACHER/STUDENT/ADMIN) → app convention (lowercase).
  static String? _apiRoleToApp(String? role) => role?.toLowerCase();

  /// App convention → backend enum. `null` means "omit the field".
  static String? appRoleToApi(String? role) => role?.toUpperCase();
}

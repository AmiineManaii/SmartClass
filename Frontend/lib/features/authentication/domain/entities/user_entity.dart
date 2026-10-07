/// Pure-Dart user entity (no Flutter dependency).
/// Mirrors the backend `SafeUser` schema (`contracts/auth.openapi.yaml`).
/// Roles use the app convention: lowercase `teacher` | `student` | `admin`.
class UserEntity {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? role;
  final String? birthDate;
  final String status;
  final bool emailVerified;
  final bool onboardingCompleted;

  const UserEntity({
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

  String get displayName => '$firstName $lastName'.trim();

  UserEntity copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? Function()? role,
    String? Function()? birthDate,
    String? status,
    bool? emailVerified,
    bool? onboardingCompleted,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role != null ? role() : this.role,
      birthDate: birthDate != null ? birthDate() : this.birthDate,
      status: status ?? this.status,
      emailVerified: emailVerified ?? this.emailVerified,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

/// People managed by the admin (pure Dart).
///
/// Students map SafeUser rows (`GET /api/v1/users?role=STUDENT`) with the
/// class membership resolved per class; teachers merge the directory with
/// the class assignments (`GET /api/v1/groups/:id/teachers`) so subject
/// and hours are real. `specialty` carries the assigned subject ('' when
/// unassigned); teachers have no department server-side.
enum PersonAssignState { selected, unselected, assigned, pending, warning }

class AdminStudent {
  final String id;
  final String name;
  final String email;
  final String badge;
  final String? initials;
  final bool verified;

  /// Null = not assigned to any class (mock stage: set in datasource).
  final String? assignedClassId;

  const AdminStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.badge,
    this.initials,
    this.verified = false,
    this.assignedClassId,
  });
}

class AdminTeacher {
  final String id;
  final String name;
  final String email;
  final String specialty;
  final String department;
  final String availabilityKey;
  final String availabilityArgs;
  final String subjectLabel;
  final String subjectValue;
  final PersonAssignState state;
  final bool initiallyAssigned;

  /// Initials derived from the name (avatar display).
  String? get initials {
    final parts =
        name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  /// Backend email verification flag (SafeUser.emailVerified).
  final bool verified;

  /// Backend teacher approval status ('PENDING', 'APPROVED', 'REJECTED').
  final String approvalStatus;

  const AdminTeacher({
    required this.id,
    required this.name,
    required this.email,
    required this.specialty,
    required this.department,
    required this.availabilityKey,
    this.availabilityArgs = '',
    required this.subjectLabel,
    required this.subjectValue,
    this.state = PersonAssignState.unselected,
    this.initiallyAssigned = false,
    this.verified = false,
    this.approvalStatus = 'APPROVED',
  });
}

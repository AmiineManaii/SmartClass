/// People managed by the admin (pure Dart).
///
/// Backend endpoints: none yet (users module planned).
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
  });
}

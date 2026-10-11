/// A student's membership in a class (groupe-classe).
///
/// Pure Dart — no Flutter dependency.
///
/// Source of truth (planned): `GET /api/v1/groups/memberships` (see
/// `contracts/README.md` → groups: planned). Until that contract lands,
/// [studentClassMembershipProvider] resolves to `null`, which the dashboard
/// treats as "no class joined" (fail-safe, no mock data).
class StudentClassMembership {
  final String id;
  final String name;
  final String? institution;

  const StudentClassMembership({
    required this.id,
    required this.name,
    this.institution,
  });
}

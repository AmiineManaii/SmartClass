/// A student's membership in a class (groupe-classe).
///
/// Pure Dart — no Flutter dependency.
///
/// Source of truth: `GET /api/v1/groups/mine` (see
/// `contracts/groups.openapi.yaml` → `listMyGroups`). When the endpoint
/// returns no STUDENT membership, [studentClassMembershipProvider]
/// resolves to `null`, which the dashboard treats as "no class joined"
/// (fail-safe, no mock data).
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

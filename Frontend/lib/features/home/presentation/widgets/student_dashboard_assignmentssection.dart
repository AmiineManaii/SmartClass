part of '../widgets/student_dashboard_view.dart';
class _AssignmentsSection extends StatelessWidget {
  final List<StudentAssignment> assignments;
  final VoidCallback onHistoryTap;
  final ValueChanged<String> onAssignmentAction;

  const _AssignmentsSection({
    required this.assignments,
    required this.onHistoryTap,
    required this.onAssignmentAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentAssignmentsSection(
          assignments: assignments,
          onHistoryTap: onHistoryTap,
          onAssignmentAction: onAssignmentAction,
        ),
      ],
    );
  }
}


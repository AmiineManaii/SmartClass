part of '../widgets/student_dashboard_view.dart';
class _EnrolledContent extends ConsumerWidget {
  final StudentClassMembership membership;
  final VoidCallback onLeaveClass;
  final VoidCallback onJoinLive;
  final VoidCallback onCourseSummaryTap;
  final VoidCallback onPracticeQuizTap;
  final VoidCallback onViewAllCourses;
  final ValueChanged<String> onCourseTap;
  final VoidCallback onHistoryTap;
  final ValueChanged<String> onAssignmentAction;

  const _EnrolledContent({
    required this.membership,
    required this.onLeaveClass,
    required this.onJoinLive,
    required this.onCourseSummaryTap,
    required this.onPracticeQuizTap,
    required this.onViewAllCourses,
    required this.onCourseTap,
    required this.onHistoryTap,
    required this.onAssignmentAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(studentTodayLiveProvider);
    final classes = ref.watch(dashboardClassesProvider);
    final assignments = ref.watch(studentAssignmentsProvider);
    final isDesktop = context.screenWidth >= 1024;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column (7/12 width)
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                live.when(
                  data: (session) =>
                      _LiveSection(session: session, onJoin: onJoinLive),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                StudentAiStudioCard(
                  onCourseSummaryTap: onCourseSummaryTap,
                  onPracticeQuizTap: onPracticeQuizTap,
                ),
                const SizedBox(height: 24),
                classes.when(
                  data: (list) => _RealClassesSection(
                    classes: list,
                    onViewAll: onViewAllCourses,
                    onClassTap: onCourseTap,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Rail Column (5/12 width)
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EnrolledClassCard(
                  membership: membership,
                  onLeaveClass: onLeaveClass,
                ),
                const SizedBox(height: 16),
                assignments.when(
                  data: (list) => _AssignmentsSection(
                    assignments: list,
                    onHistoryTap: onHistoryTap,
                    onAssignmentAction: onAssignmentAction,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                const _DailyScheduleCard(),
              ],
            ),
          ),
        ],
      );
    }

    // Mobile / Tablet layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EnrolledClassCard(membership: membership, onLeaveClass: onLeaveClass),
        const SizedBox(height: 16),
        live.when(
          data: (session) => _LiveSection(session: session, onJoin: onJoinLive),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        StudentAiStudioCard(
          onCourseSummaryTap: onCourseSummaryTap,
          onPracticeQuizTap: onPracticeQuizTap,
        ),
        const SizedBox(height: 24),
        classes.when(
          data: (list) => _RealClassesSection(
            classes: list,
            onViewAll: onViewAllCourses,
            onClassTap: onCourseTap,
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        assignments.when(
          data: (list) => _AssignmentsSection(
            assignments: list,
            onHistoryTap: onHistoryTap,
            onAssignmentAction: onAssignmentAction,
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}


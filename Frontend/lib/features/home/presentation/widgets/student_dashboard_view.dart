import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/student_dashboard_provider.dart';
import '../../domain/entities/student_assignment.dart';
import '../../domain/entities/student_course_progress.dart';
import '../../domain/entities/today_live_session.dart';
import 'no_class_notice.dart';
import 'student_ai_studio_card.dart';
import 'student_assignments_section.dart';
import 'student_courses_section.dart';
import 'student_greeting_header.dart';
import 'student_imminent_live_card.dart';

class StudentDashboardView extends ConsumerWidget {
  const StudentDashboardView({super.key});

  void _showNoNotifications(BuildContext context) {
    // Honest empty state: no notifications source exists yet
    // (notifications module planned). Never a fake counter.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('notifications_empty')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authStateProvider).valueOrNull;
    // Class-dependent content is gated behind real membership data.
    // No membership (or fetch failure) => administration notice,
    // never invented classes, courses, homework or live sessions.
    final membership = ref.watch(studentClassMembershipProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studentClassMembershipProvider);
            ref.invalidate(studentTodayLiveProvider);
            ref.invalidate(studentEnrolledCoursesProvider);
            ref.invalidate(studentAssignmentsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: context.screenWidth >= 600 ? 32 : 20,
              vertical: 8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopTitleRow(
                      onProfileTap: () => context.push('/profile'),
                      onNotificationsTap: () => _showNoNotifications(context),
                    ),
                    const SizedBox(height: 16),
                    StudentGreetingHeader(
                      user: user,
                      onNotificationsTap: () => _showNoNotifications(context),
                    ),
                    const SizedBox(height: 16),
                    membership.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const NoClassNotice(),
                      data: (membership) => membership == null
                          ? const NoClassNotice()
                          : _EnrolledContent(
                              onJoinLive: () =>
                                  context.push('/videoconference'),
                              onCourseSummaryTap: () =>
                                  context.push('/ai-revision'),
                              onPracticeQuizTap: () =>
                                  context.push('/ai-quiz'),
                              onViewAllCourses: () =>
                                  context.push('/courses'),
                              onCourseTap: (_) => context.push('/courses'),
                              onHistoryTap: () => context.push('/exams'),
                              onAssignmentAction: (assignmentId) {
                                if (assignmentId.contains('qcm')) {
                                  context.push('/exams');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.tr('deposit_action'),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full dashboard, rendered only with a real class membership.
class _EnrolledContent extends ConsumerWidget {
  final VoidCallback onJoinLive;
  final VoidCallback onCourseSummaryTap;
  final VoidCallback onPracticeQuizTap;
  final VoidCallback onViewAllCourses;
  final ValueChanged<String> onCourseTap;
  final VoidCallback onHistoryTap;
  final ValueChanged<String> onAssignmentAction;

  const _EnrolledContent({
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
    final courses = ref.watch(studentEnrolledCoursesProvider);
    final assignments = ref.watch(studentAssignmentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live widget appears ONLY with a real session today.
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
        courses.when(
          data: (list) => _CoursesSection(
            courses: list,
            onViewAll: onViewAllCourses,
            onCourseTap: onCourseTap,
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

class _LiveSection extends StatelessWidget {
  final TodayLiveSession? session;
  final VoidCallback onJoin;

  const _LiveSection({required this.session, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final live = session;
    if (live == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentImminentLiveCard(session: live, onJoin: onJoin),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _CoursesSection extends StatelessWidget {
  final List<StudentCourseProgress> courses;
  final VoidCallback onViewAll;
  final ValueChanged<String> onCourseTap;

  const _CoursesSection({
    required this.courses,
    required this.onViewAll,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentCoursesSection(
          courses: courses,
          onViewAll: onViewAll,
          onCourseTap: onCourseTap,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

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

class _TopTitleRow extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;

  const _TopTitleRow({
    required this.onProfileTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Image.asset(
                'assets/images/logo_emblem.png',
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: colorScheme.onPrimary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMARTCLASS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      context.tr('home'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: onNotificationsTap,
              tooltip: context.tr('notifications'),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHigh,
                  border: Border.all(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/student_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

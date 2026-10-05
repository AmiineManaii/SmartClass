import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/student_dashboard_provider.dart';
import 'student_ai_studio_card.dart';
import 'student_assignments_section.dart';
import 'student_courses_section.dart';
import 'student_greeting_header.dart';
import 'student_imminent_live_card.dart';
import 'student_motivation_cards.dart';

class StudentDashboardView extends ConsumerWidget {
  const StudentDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authStateProvider).value;
    final stats = ref.watch(studentMotivationStatsProvider);
    final liveSession = ref.watch(studentImminentLiveProvider);
    final courses = ref.watch(studentCoursesProgressProvider);
    final assignments = ref.watch(studentUpcomingAssignmentsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studentMotivationStatsProvider);
            ref.invalidate(studentImminentLiveProvider);
            ref.invalidate(studentCoursesProgressProvider);
            ref.invalidate(studentUpcomingAssignmentsProvider);
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
                      onNotificationsTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr(
                                'pending_count',
                                args: {'count': '2'},
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    StudentGreetingHeader(
                      user: user,
                      onNotificationsTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr(
                                'pending_count',
                                args: {'count': '2'},
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    StudentMotivationCards(stats: stats),
                    const SizedBox(height: 16),
                    StudentImminentLiveCard(
                      session: liveSession,
                      onJoin: () => context.push('/videoconference'),
                    ),
                    const SizedBox(height: 20),
                    StudentAiStudioCard(
                      onCourseSummaryTap: () => context.push('/ai-revision'),
                      onPracticeQuizTap: () => context.push('/ai-quiz'),
                    ),
                    const SizedBox(height: 24),
                    StudentCoursesSection(
                      courses: courses,
                      onViewAll: () => context.push('/courses'),
                      onCourseTap: (courseId) => context.push('/courses'),
                    ),
                    const SizedBox(height: 24),
                    StudentAssignmentsSection(
                      assignments: assignments,
                      onHistoryTap: () => context.push('/exams'),
                      onAssignmentAction: (assignmentId) {
                        if (assignmentId.contains('qcm')) {
                          context.push('/exams');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('deposit_action')),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
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
                        fontSize: 11,
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
                        fontSize: 16,
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

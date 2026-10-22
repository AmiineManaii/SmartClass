import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/student_dashboard_provider.dart';
import '../../domain/entities/student_assignment.dart';
import '../../domain/entities/student_class_membership.dart';
import '../../domain/entities/today_live_session.dart';
import 'no_class_notice.dart';
import '../../../../core/widgets/smart_loader.dart';
import 'student_ai_studio_card.dart';
import 'student_assignments_section.dart';
import 'student_greeting_header.dart';
import 'student_imminent_live_card.dart';

class StudentDashboardView extends ConsumerWidget {
  const StudentDashboardView({super.key});

  void _showNoNotifications(BuildContext context) {
    // Honest empty state: no notifications source exists yet
    // (notifications module planned). Never a fake counter.
    context.showInfoToast(
      context.tr('notifications_empty'),
      title: context.tr('notifications'),
    );
  }

  void _showJoinClassDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Rejoindre une classe'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Entrez le code d\'invitation partagé par votre enseignant ou administrateur.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    autofocus: true,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Code d\'invitation',
                      hintText: 'ex: SC-AB12CD',
                      prefixIcon: const Icon(Icons.vpn_key_rounded),
                      errorText: errorMessage,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final code = controller.text.trim();
                          if (code.isEmpty) {
                            setState(() {
                              errorMessage = 'Veuillez saisir un code';
                            });
                            return;
                          }
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          try {
                            await ref
                                .read(groupsRemoteDataSourceProvider)
                                .joinClass(code);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            ref.invalidate(myGroupsProvider);
                            ref.invalidate(studentClassMembershipProvider);
                            ref.invalidate(studentEnrolledCoursesProvider);
                            if (context.mounted) {
                              context.showSuccessToast(
                                'Vous avez rejoint la classe avec succès !',
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              errorMessage = e.toString().replaceFirst(
                                'ApiException: ',
                                '',
                              );
                            });
                          }
                        },
                  child: isLoading
                      ? const SmartLoader.small(
                          color: Colors.white,
                          customSize: 18,
                        )
                      : const Text('Rejoindre'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmLeaveClass(
    BuildContext context,
    WidgetRef ref,
    StudentClassMembership membership,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Quitter la classe'),
          content: Text(
            'Êtes-vous sûr de vouloir quitter la classe "${membership.name}" ? Vous ne pourrez plus accéder aux cours associés sans nouveau code d\'invitation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ref
                      .read(groupsRemoteDataSourceProvider)
                      .leaveClass(membership.id);
                  ref.invalidate(myGroupsProvider);
                  ref.invalidate(studentClassMembershipProvider);
                  ref.invalidate(studentEnrolledCoursesProvider);
                  if (context.mounted) {
                    context.showInfoToast('Vous avez quitté la classe.');
                  }
                } catch (e) {
                  if (context.mounted) {
                    context.showErrorToast(
                      e.toString().replaceFirst('ApiException: ', ''),
                    );
                  }
                }
              },
              child: const Text('Quitter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authStateProvider).valueOrNull;
    final membership = ref.watch(studentClassMembershipProvider);
    final isDesktop = context.screenWidth >= 1024;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myGroupsProvider);
            ref.invalidate(studentClassMembershipProvider);
            ref.invalidate(studentTodayLiveProvider);
            ref.invalidate(dashboardClassesProvider);
            ref.invalidate(studentAssignmentsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop
                  ? 36
                  : (context.screenWidth >= 600 ? 32 : 20),
              vertical: isDesktop ? 24 : 8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isDesktop) ...[
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
                    ] else ...[
                      _DesktopGreetingAndStatsHeader(
                        user: user,
                        onJoinTap: () => _showJoinClassDialog(context, ref),
                      ),
                      const SizedBox(height: 24),
                    ],
                    membership.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: SmartLoader.medium(
                            message: 'Chargement de votre classe...',
                          ),
                        ),
                      ),
                      error: (_, _) => NoClassNotice(
                        onJoinTap: () => _showJoinClassDialog(context, ref),
                      ),
                      data: (membership) => membership == null
                          ? NoClassNotice(
                              onJoinTap: () =>
                                  _showJoinClassDialog(context, ref),
                            )
                          : _EnrolledContent(
                              membership: membership,
                              onLeaveClass: () =>
                                  _confirmLeaveClass(context, ref, membership),
                              onJoinLive: () =>
                                  context.push('/videoconference'),
                              onCourseSummaryTap: () =>
                                  context.push('/ai-revision'),
                              onPracticeQuizTap: () => context.push('/ai-quiz'),
                              onViewAllCourses: () => context.push('/courses'),
                              onCourseTap: (id) => id.isEmpty
                                  ? context.push('/courses')
                                  : context.push('/groups/$id'),
                              onHistoryTap: () => context.push('/exams'),
                              onAssignmentAction: (assignmentId) {
                                if (assignmentId.contains('qcm')) {
                                  context.push('/exams');
                                } else {
                                  context.showInfoToast(
                                    context.tr('deposit_action'),
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

class _EnrolledClassCard extends StatelessWidget {
  final StudentClassMembership membership;
  final VoidCallback onLeaveClass;

  const _EnrolledClassCard({
    required this.membership,
    required this.onLeaveClass,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () =>
          context.push('/groups/${membership.id}', extra: membership.name),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.school_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    membership.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (membership.institution != null &&
                      membership.institution!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      membership.institution!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: colorScheme.error,
                size: 20,
              ),
              tooltip: 'Quitter la classe',
              onPressed: onLeaveClass,
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopGreetingAndStatsHeader extends ConsumerWidget {
  final AuthState? user;
  final VoidCallback onJoinTap;

  const _DesktopGreetingAndStatsHeader({
    required this.user,
    required this.onJoinTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : context.tr('student_greeting_default');

    // Real data — no mock. Zero counts while loading / on error are honest.
    final classes = ref.watch(dashboardClassesProvider).valueOrNull ?? const [];
    final memberships = classes
        .map((c) => (c['memberCount'] as num?)?.toInt() ?? 0)
        .fold<int>(0, (a, b) => a + b);
    final teachers = classes
        .map((c) => (c['teacherCount'] as num?)?.toInt() ?? 0)
        .fold<int>(0, (a, b) => a + b);
    final membership = ref.watch(studentClassMembershipProvider).valueOrNull;

    final subtitleParts = <String>[
      if (membership != null && membership.name.isNotEmpty) membership.name,
      if (membership?.institution != null &&
          membership!.institution!.isNotEmpty)
        membership.institution!,
    ];
    final subtitle = subtitleParts.isEmpty
        ? context.tr('no_class_title')
        : subtitleParts.join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Creative Hero Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, const Color(0xFFF1F5F9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0x0A0F172A),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const StudentAvatar(size: 64),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            context.tr(
                              'student_greeting',
                              args: {'name': displayName},
                            ),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.4,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('👋', style: TextStyle(fontSize: 22)),
                        if (membership != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  context.tr('role_student'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(
                      'Studio IA',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => context.push('/ai-assistant'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: onJoinTap,
                    icon: const Icon(Icons.vpn_key_rounded, size: 16),
                    label: const Text('Rejoindre une classe'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. Real stats cards (no fabricated engagement data)
        Row(
          children: [
            Expanded(
              child: _StatMetricCard(
                icon: Icons.menu_book_rounded,
                title: 'MES CLASSES',
                value: context.tr(
                  'dashboard_classes_count',
                  args: {'count': '${classes.length}'},
                ),
                subtext: subtitle,
                accentColor: const Color(0xFF2563EB),
                progress: classes.isEmpty ? 0 : 1,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatMetricCard(
                icon: Icons.people_alt_rounded,
                title: 'CAMARADES',
                value: context.tr(
                  'dashboard_members_count',
                  args: {'count': '$memberships'},
                ),
                subtext: context.tr('dashboard_real_data'),
                accentColor: const Color(0xFF6366F1),
                progress: memberships == 0 ? 0 : 1,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatMetricCard(
                icon: Icons.co_present_rounded,
                title: 'ENSEIGNANTS',
                value: context.tr(
                  'dashboard_teachers_count',
                  args: {'count': '$teachers'},
                ),
                subtext: context.tr('dashboard_real_data'),
                accentColor: const Color(0xFF0F9D78),
                progress: teachers == 0 ? 0 : 1,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatMetricCard(
                icon: Icons.auto_awesome_rounded,
                title: 'TUTEUR IA',
                value: context.tr('dashboard_tutor_ready'),
                subtext: context.tr('dashboard_tutor_sub'),
                accentColor: const Color(0xFF10B981),
                progress: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatMetricCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String value;
  final String subtext;
  final Color accentColor;
  final double progress;

  const _StatMetricCard({
    this.icon,
    required this.title,
    required this.value,
    required this.subtext,
    required this.accentColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : const Color(0x080F172A),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.7,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DailyScheduleCard extends ConsumerWidget {
  const _DailyScheduleCard();

  Color _kindColor(ColorScheme colorScheme, String? kind) {
    switch (kind) {
      case 'CM':
        return colorScheme.primary;
      case 'TD':
        return colorScheme.secondary;
      case 'TP':
        return colorScheme.tertiary;
      default:
        return colorScheme.primary;
    }
  }

  ({int h, int m}) _parseTime(String? value) {
    final parts = (value ?? '').split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return (h: h, m: m);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final async = ref.watch(studentDayTimetableProvider);
    final events = async.valueOrNull ?? const <Map<String, dynamic>>[];
    final now = TimeOfDay.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Planning du jour',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.tr(
                    'dashboard_sessions_count',
                    args: {'count': '${events.length}'},
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryFixed,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (async.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('dashboard_no_sessions'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...events.asMap().entries.expand((entry) {
              final i = entry.key;
              final e = entry.value;
              final start = _parseTime(e['start'] as String?);
              final end = _parseTime(e['end'] as String?);
              final startMinutes = start.h * 60 + start.m;
              final endMinutes = end.h * 60 + end.m;
              final nowMinutes = now.hour * 60 + now.minute;
              final isCurrent =
                  nowMinutes >= startMinutes && nowMinutes < endMinutes;
              final teacher =
                  (e['teacher'] is Map && (e['teacher'] as Map)['name'] != null)
                  ? '${(e['teacher'] as Map)['name']}'
                  : '';
              final room = e['room']?.toString() ?? '';
              final subtitle = [
                if (teacher.isNotEmpty) teacher,
                if (room.isNotEmpty) room,
                if (e['kind'] != null) '${e['kind']}',
              ].join(' • ');
              final slot = _ScheduleSlot(
                time: '${e['start'] ?? ''} - ${e['end'] ?? ''}',
                subject: '${e['title'] ?? ''}',
                location: isCurrent
                    ? '${context.tr('dashboard_live_now')} 🔴'
                    : subtitle,
                color: _kindColor(colorScheme, e['kind'] as String?),
                isCurrent: isCurrent,
              );
              return i == 0 ? [slot] : [const SizedBox(height: 10), slot];
            }),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.push('/videoconference'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Consulter l\'emploi du temps complet',
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: colorScheme.secondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSlot extends StatelessWidget {
  final String time;
  final String subject;
  final String location;
  final Color color;
  final bool isCurrent;

  const _ScheduleSlot({
    required this.time,
    required this.subject,
    required this.location,
    required this.color,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent
            ? color.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent ? color.withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subject,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: isCurrent ? color : colorScheme.onSurfaceVariant,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

/// Student's real classes (`GET /api/v1/groups/mine`) rendered as animated
/// 3D course cards. Title = class name, tags = department/level/status.
/// No mock data: an empty list shows the honest empty state.
class _RealClassesSection extends StatelessWidget {
  final List<Map<String, dynamic>> classes;
  final VoidCallback onViewAll;
  final ValueChanged<String> onClassTap;

  const _RealClassesSection({
    required this.classes,
    required this.onViewAll,
    required this.onClassTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(
                  context.tr('my_courses'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.tr(
                    'enrolled_count',
                    args: {'count': classes.length.toString()},
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('view_all'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colorScheme.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (classes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('no_courses'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (int i = 0; i < classes.length; i++) ...[
            _AnimatedClassCard(
              index: i,
              data: classes[i],
              onTap: () => onClassTap((classes[i]['id'] as String?) ?? ''),
            ),
            if (i < classes.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }
}

/// Course card with a staggered entrance animation and a 3D hover tilt.
class _AnimatedClassCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _AnimatedClassCard({
    required this.index,
    required this.data,
    required this.onTap,
  });

  @override
  State<_AnimatedClassCard> createState() => _AnimatedClassCardState();
}

class _AnimatedClassCardState extends State<_AnimatedClassCard>
    with SingleTickerProviderStateMixin {
  Offset _tilt = Offset.zero;
  bool _hovered = false;
  late final AnimationController _entry;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    Future<void>.delayed(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) _entry.forward();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _onHover(Offset localPosition, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final dx = ((localPosition.dx / size.width) - 0.5).clamp(-0.5, 0.5);
    final dy = ((localPosition.dy / size.height) - 0.5).clamp(-0.5, 0.5);
    setState(() => _tilt = Offset(dx, dy));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = (widget.data['name'] as String?)?.trim();
    final title = (name == null || name.isEmpty) ? '—' : name;
    final department = (widget.data['department'] as String?)?.trim();
    final level = (widget.data['level'] as String?)?.trim();
    final status = (widget.data['status'] as String?)?.trim() ?? 'PUBLISHED';
    final memberCount = (widget.data['memberCount'] as num?)?.toInt() ?? 0;
    final teacherCount = (widget.data['teacherCount'] as num?)?.toInt() ?? 0;
    final isPublished = status == 'PUBLISHED';

    final levelKey = switch (level) {
      'LICENCE' => 'level_licence',
      'MASTER' => 'level_master',
      'DOCTORAT' => 'level_doctorat',
      _ => null,
    };
    final levelLabel = levelKey != null ? context.tr(levelKey) : (level ?? '');

    final tags = <Widget>[
      if (department != null && department.isNotEmpty)
        _ClassTag(
          label: department,
          icon: Icons.account_balance_rounded,
          colorScheme: colorScheme,
        ),
      if (levelLabel.isNotEmpty)
        _ClassTag(
          label: levelLabel,
          icon: Icons.school_rounded,
          colorScheme: colorScheme,
        ),
      _ClassTag(
        label: context.tr(isPublished ? 'in_progress' : 'drafts'),
        icon: isPublished
            ? Icons.play_circle_outline_rounded
            : Icons.edit_note_rounded,
        colorScheme: colorScheme,
        accent: isPublished ? colorScheme.primary : colorScheme.tertiary,
      ),
      _ClassTag(
        label: context.tr(
          'courses_students_count',
          args: {'count': '$memberCount'},
        ),
        icon: Icons.people_alt_outlined,
        colorScheme: colorScheme,
      ),
      _ClassTag(
        label: context.tr(
          'courses_teachers_count',
          args: {'count': '$teacherCount'},
        ),
        icon: Icons.co_present_rounded,
        colorScheme: colorScheme,
      ),
    ];

    final tiltX = (_tilt.dy * -0.14);
    final tiltY = (_tilt.dx * 0.14);

    return FadeTransition(
      opacity: CurvedAnimation(parent: _entry, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic)),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _tilt = Offset.zero;
          }),
          onHover: (event) {
            final size = context.size;
            if (size != null) _onHover(event.localPosition, size);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            transformAlignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateX(tiltX)
              ..rotateY(tiltY)
              ..scaleByDouble(
                _hovered ? 1.012 : 1.0,
                _hovered ? 1.012 : 1.0,
                1.0,
                1.0,
              ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surfaceContainerLowest,
                        colorScheme.surfaceContainerLow,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _hovered
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(
                          alpha: _hovered ? 0.16 : 0.05,
                        ),
                        blurRadius: _hovered ? 24 : 10,
                        offset: Offset(0, _hovered ? 12 : 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: colorScheme.onPrimary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(spacing: 8, runSpacing: 8, children: tags),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme colorScheme;
  final Color? accent;

  const _ClassTag({
    required this.label,
    required this.icon,
    required this.colorScheme,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

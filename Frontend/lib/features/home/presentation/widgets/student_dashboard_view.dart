import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/student_dashboard_provider.dart';
import '../../domain/entities/student_assignment.dart';
import '../../domain/entities/student_class_membership.dart';
import '../../domain/entities/student_course_progress.dart';
import '../../domain/entities/today_live_session.dart';
import 'no_class_notice.dart';
import '../../../../core/widgets/smart_loader.dart';
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
                              errorMessage = e.toString().replaceFirst('ApiException: ', '');
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
            ref.invalidate(studentEnrolledCoursesProvider);
            ref.invalidate(studentAssignmentsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 36 : (context.screenWidth >= 600 ? 32 : 20),
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
                              onLeaveClass: () => _confirmLeaveClass(
                                context,
                                ref,
                                membership,
                              ),
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
    final courses = ref.watch(studentEnrolledCoursesProvider);
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
        _EnrolledClassCard(
          membership: membership,
          onLeaveClass: onLeaveClass,
        ),
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

class _DesktopGreetingAndStatsHeader extends StatelessWidget {
  final AuthState? user;
  final VoidCallback onJoinTap;

  const _DesktopGreetingAndStatsHeader({
    required this.user,
    required this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Ahmed Mohsen';

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
                            'Bonjour $displayName',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.4,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('👋', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF15803D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Synchronisé ENT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Licence 3 Informatique • Faculté des Sciences & Technologies Numériques',
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
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
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

        // 2. 4 Modern Motivation & Stats Cards
        Row(
          children: [
            Expanded(
              child: _StatMetricCard(
                emoji: '🔥',
                title: 'SÉRIE ACTIVE',
                value: '5 jours consécutifs',
                subtext: 'Objectif 7j • +1 aujourd\'hui',
                accentColor: const Color(0xFFF97316),
                progress: 5 / 7,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatMetricCard(
                icon: Icons.verified_rounded,
                title: 'OBJECTIF HEBDO',
                value: '85% atteint',
                subtext: '17 / 20 h complétées',
                accentColor: const Color(0xFF6366F1),
                progress: 0.85,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatMetricCard(
                icon: Icons.menu_book_rounded,
                title: 'MODULES INSCRITS',
                value: '4 cours actifs',
                subtext: '2 devoirs à rendre',
                accentColor: const Color(0xFF2563EB),
                progress: 0.60,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatMetricCard(
                icon: Icons.auto_awesome_rounded,
                title: 'TUTEUR IA',
                value: 'Prêt pour réviser ✨',
                subtext: 'SmartMentor actif 24/7',
                accentColor: const Color(0xFF10B981),
                progress: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatMetricCard extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final String title;
  final String value;
  final String subtext;
  final Color accentColor;
  final double progress;

  const _StatMetricCard({
    this.emoji,
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
                child: emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 18))
                    : Icon(icon, color: accentColor, size: 20),
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

class _DailyScheduleCard extends StatelessWidget {
  const _DailyScheduleCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  '3 séances',
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
          _ScheduleSlot(
            time: '08:30 - 10:30',
            subject: 'Algorithmique Avancée',
            location: 'Salle B104 • Amphi',
            color: colorScheme.primary,
            isCurrent: false,
          ),
          const SizedBox(height: 10),
          _ScheduleSlot(
            time: '14:00 - 16:00',
            subject: 'Mathématiques & Algèbre',
            location: 'Session Live Virtuelle 🔴',
            color: colorScheme.error,
            isCurrent: true,
          ),
          const SizedBox(height: 10),
          _ScheduleSlot(
            time: '16:30 - 18:00',
            subject: 'Atelier de Tutorat IA',
            location: 'Studio IA & Quiz',
            color: colorScheme.secondary,
            isCurrent: false,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.push('/exams'),
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
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
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

part of '../widgets/student_dashboard_view.dart';
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

    // Real data â€” no mock. Zero counts while loading / on error are honest.
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
        : subtitleParts.join(' â€¢ ');

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
                        const Text('ðŸ‘‹', style: TextStyle(fontSize: 22)),
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


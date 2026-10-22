import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_providers.dart';
import '../extensions/extensions.dart';
import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';
import 'web_controls_bar.dart';
import 'web_theme_toggle.dart';

/// Provider pour contrôler l'état rétracté / étendu de la barre latérale sur Desktop.
final webSidebarCollapsedProvider = StateProvider<bool>((ref) => false);

/// Navigation shell moderne pour Desktop (Largeur >= 1024px) avec barre latérale
/// rétractable (260px dépliée <-> 74px repliée), support complet des 2 thèmes
/// (Clair et Sombre) et des 2 langues (FR et EN).
class WebMainScaffold extends ConsumerWidget {
  final Widget body;
  final String? activePath;
  final String? role;

  const WebMainScaffold({
    super.key,
    required this.body,
    this.activePath,
    this.role,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final currentRole = role ?? user?.role ?? 'student';
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (currentRole == 'teacher' ? 'Professeur' : 'Étudiant');
    final email = user?.email?.trim() ?? '';
    final institution = user?.institution?.trim() ?? '';

    // Détection du chemin actif
    String currentRoute = activePath ?? '';
    if (currentRoute.isEmpty) {
      try {
        currentRoute = GoRouterState.of(context).matchedLocation;
      } catch (_) {
        currentRoute = '/home';
      }
    }

    final isTeacher = currentRole == 'teacher';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCollapsed = ref.watch(webSidebarCollapsedProvider);

    // Dynamic styling tokens based on theme
    final sidebarBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final sidebarBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);
    final topBarBg = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.95);
    final topBarBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : AppTheme.surface,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ========================================================
          // 1. SIDEBAR RÉTRACTABLE (260px <-> 74px) AVEC ANIMATION
          // ========================================================
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            width: isCollapsed ? 74 : 260,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(
                right: BorderSide(color: sidebarBorder, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : const Color(0x0A0F172A),
                  blurRadius: 18,
                  offset: const Offset(3, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header: Logo & Collapse Button
                // Top Header: Logo & Collapse Button
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCollapsed ? 12 : 16,
                    vertical: 14,
                  ),
                  child: isCollapsed
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () => ref
                                  .read(webSidebarCollapsedProvider.notifier)
                                  .state = false,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 38,
                                height: 38,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : const Color(0xFFC7D2FE),
                                  ),
                                ),
                                child: Image.asset(
                                  'assets/images/logo_emblem.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.school_rounded,
                                    color: AppTheme.primary,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : const Color(0xFFC7D2FE),
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/logo_emblem.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.school_rounded,
                                  color: AppTheme.primary,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SmartClass',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  Text(
                                    'EDTECH • AI ASSISTED',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Collapse button
                            IconButton(
                              icon: Icon(
                                Icons.keyboard_double_arrow_left_rounded,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                size: 20,
                              ),
                              tooltip: context.tr('collapse_sidebar'),
                              onPressed: () => ref
                                  .read(webSidebarCollapsedProvider.notifier)
                                  .state = true,
                            ),
                          ],
                        ),
                ),

                // Expand button in collapsed mode
                if (isCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: IconButton(
                      icon: Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        size: 20,
                      ),
                      tooltip: context.tr('expand_sidebar'),
                      onPressed: () => ref
                          .read(webSidebarCollapsedProvider.notifier)
                          .state = false,
                    ),
                  ),

                // Role Badge Capsule
                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFFE0E7FF),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isTeacher
                                ? Icons.co_present_rounded
                                : Icons.school_rounded,
                            color: isDark
                                ? const Color(0xFF83F8CD)
                                : const Color(0xFF2563EB),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isTeacher ? 'ESPACE ENSEIGNANT' : 'PORTAIL ÉTUDIANT',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E40AF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Center(
                    child: Tooltip(
                      message: context.tr(
                        isTeacher ? 'teacher_portal' : 'student_portal',
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isTeacher
                              ? Icons.co_present_rounded
                              : Icons.school_rounded,
                          color: isDark
                              ? const Color(0xFF83F8CD)
                              : const Color(0xFF2563EB),
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Navigation Links
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCollapsed ? 10 : 12,
                      vertical: 4,
                    ),
                    children: isTeacher
                        ? _buildTeacherNavItems(
                            context,
                            currentRoute,
                            isCollapsed,
                            isDark,
                          )
                        : _buildStudentNavItems(
                            context,
                            currentRoute,
                            isCollapsed,
                            isDark,
                          ),
                  ),
                ),

                // Bottom Active User Card & Controls
                Container(
                  margin: EdgeInsets.all(isCollapsed ? 8 : 12),
                  padding: EdgeInsets.all(isCollapsed ? 6 : 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.7)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User row
                      InkWell(
                        onTap: () => context.go('/profile'),
                        borderRadius: BorderRadius.circular(10),
                        child: isCollapsed
                            ? Center(
                                child: Tooltip(
                                  message: '$displayName\n${context.tr('nav_my_profile')}',
                                  child: CircleAvatar(
                                    radius: 17,
                                    backgroundColor: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFDBEAFE),
                                    child: Text(
                                      displayName.isNotEmpty
                                          ? displayName[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1D4ED8),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFDBEAFE),
                                    child: Text(
                                      displayName.isNotEmpty
                                          ? displayName[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1D4ED8),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          institution.isNotEmpty
                                              ? institution
                                              : (email.isNotEmpty
                                                  ? email
                                                  : (isTeacher
                                                      ? 'Professeur'
                                                      : 'L3 Informatique')),
                                          style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.logout_rounded,
                                      color: isDark
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFFDC2626),
                                      size: 18,
                                    ),
                                    tooltip: context.tr('logout'),
                                    onPressed: () => _confirmLogout(context, ref),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 8),
                      // Controls: Theme + Language Switcher
                      if (!isCollapsed)
                        Center(
                          child: WebControlsBar(isDarkForced: isDark),
                        )
                      else
                        Center(
                          child: WebThemeToggle(isDarkForced: isDark),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ========================================================
          // 2. WORKSPACE CENTRAL : TOP BAR + BODY
          // ========================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: topBarBg,
                    border: Border(
                      bottom: BorderSide(color: topBarBorder, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Institutional switcher / School badge (Dynamic based on user profile)
                      if (user?.institution != null && user!.institution!.trim().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_rounded,
                                size: 15,
                                color: isDark
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.institution!.trim(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],

                      // Search Bar
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: isTeacher
                                            ? 'Rechercher une classe, un devoir...'
                                            : 'Rechercher un cours, un tuteur, un devoir...',
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                          fontSize: 12,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '⌘K',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Notification Bell
                      IconButton(
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                              size: 22,
                            ),
                            Positioned(
                              top: -1,
                              right: -1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          context.showInfoToast(
                            context.tr('notifications_empty'),
                            title: context.tr('notifications'),
                          );
                        },
                      ),

                      const SizedBox(width: 10),

                      // Quick profile chip
                      InkWell(
                        onTap: () => context.go('/profile'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: isDark
                                    ? const Color(0xFF2563EB)
                                    : AppTheme.primary,
                                child: Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              if (institution.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                                        : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                                          : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.account_balance_rounded,
                                        size: 11,
                                        color: isDark
                                            ? const Color(0xFF93C5FD)
                                            : const Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 4),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 160),
                                        child: Text(
                                          institution,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? const Color(0xFF93C5FD)
                                                : const Color(0xFF1D4ED8),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(context.tr('logout')),
        content: Text(context.tr('logout_confirm_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  List<Widget> _buildStudentNavItems(
    BuildContext context,
    String currentRoute,
    bool isCollapsed,
    bool isDark,
  ) {
    return [
      _WebNavItem(
        icon: Icons.dashboard_rounded,
        label: context.tr('nav_dashboard'),
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute == '/home' || currentRoute == '/',
        onTap: () => context.go('/home'),
      ),
      _WebNavItem(
        icon: Icons.menu_book_rounded,
        label: context.tr('nav_my_courses'),
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute.startsWith('/courses'),
        onTap: () => context.go('/courses'),
      ),
      _WebNavItem(
        icon: Icons.auto_awesome_rounded,
        label: context.tr('nav_ai_studio'),
        isAiPill: true,
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute.startsWith('/ai-assistant') ||
            currentRoute.startsWith('/ai-revision') ||
            currentRoute.startsWith('/ai-quiz'),
        onTap: () => context.go('/ai-assistant'),
      ),
      _WebNavItem(
        icon: Icons.forum_rounded,
        label: context.tr('nav_community'),
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute.startsWith('/groups'),
        onTap: () => context.go('/groups'),
      ),
      _WebNavItem(
        icon: Icons.assignment_turned_in_rounded,
        label: context.tr('nav_exams_assignments'),
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute.startsWith('/exams'),
        onTap: () => context.go('/exams'),
      ),
      _WebNavItem(
        icon: Icons.videocam_rounded,
        label: context.tr('nav_videoconference'),
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute.startsWith('/videoconference'),
        onTap: () => context.go('/videoconference'),
      ),
      _WebNavItem(
        icon: Icons.person_rounded,
        label: context.tr('nav_my_profile'),
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute.startsWith('/profile'),
        onTap: () => context.go('/profile'),
      ),
    ];
  }

  List<Widget> _buildTeacherNavItems(
    BuildContext context,
    String currentRoute,
    bool isCollapsed,
    bool isDark,
  ) {
    return [
      _WebNavItem(
        icon: Icons.dashboard_rounded,
        label: context.tr('nav_dashboard'),
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute == '/home' || currentRoute == '/',
        onTap: () => context.go('/home'),
      ),
      _WebNavItem(
        icon: Icons.school_rounded,
        label: context.tr('nav_my_classes'),
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute.startsWith('/groups'),
        onTap: () => context.go('/groups'),
      ),
      _WebNavItem(
        icon: Icons.menu_book_rounded,
        label: context.tr('nav_courses_resources'),
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute.startsWith('/courses'),
        onTap: () => context.go('/courses'),
      ),
      _WebNavItem(
        icon: Icons.auto_awesome_rounded,
        label: context.tr('nav_ai_creator'),
        isAiPill: true,
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute.startsWith('/ai-assistant'),
        onTap: () => context.go('/ai-assistant'),
      ),
      _WebNavItem(
        icon: Icons.videocam_rounded,
        label: context.tr('nav_live_meetings'),
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute.startsWith('/videoconference'),
        onTap: () => context.go('/videoconference'),
      ),
      _WebNavItem(
        icon: Icons.assignment_turned_in_rounded,
        label: context.tr('nav_exams_grades'),
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute.startsWith('/exams'),
        onTap: () => context.go('/exams'),
      ),
      _WebNavItem(
        icon: Icons.person_rounded,
        label: context.tr('nav_my_profile'),
        isCollapsed: isCollapsed,
        isDark: isDark,
        isSelected: currentRoute.startsWith('/profile'),
        onTap: () => context.go('/profile'),
      ),
    ];
  }
}

class _WebNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isAiPill;
  final bool isCollapsed;
  final bool isDark;
  final VoidCallback onTap;

  const _WebNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.isAiPill = false,
    required this.isCollapsed,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_WebNavItem> createState() => _WebNavItemState();
}

class _WebNavItemState extends State<_WebNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isDark = widget.isDark;
    final isCollapsed = widget.isCollapsed;

    // Palette calculation based on state and dark mode
    Color itemBg;
    if (isSelected) {
      itemBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
    } else if (_isHovered) {
      itemBg = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFF1F5F9);
    } else {
      itemBg = Colors.transparent;
    }

    Color itemTextColor;
    if (isSelected) {
      itemTextColor = isDark ? Colors.white : const Color(0xFF1D4ED8);
    } else if (_isHovered) {
      itemTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    } else {
      itemTextColor = isDark
          ? const Color(0xFF94A3B8)
          : const Color(0xFF475569);
    }

    Color iconColor;
    if (isSelected) {
      iconColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
    } else if (_isHovered) {
      iconColor = isDark ? Colors.white : const Color(0xFF1E293B);
    } else {
      iconColor = isDark
          ? const Color(0xFF64748B)
          : const Color(0xFF64748B);
    }

    Widget content;
    if (isCollapsed) {
      content = Tooltip(
        message: widget.label,
        waitDuration: const Duration(milliseconds: 150),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: itemBg,
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(
                        color: isDark
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFBFDBFE),
                      )
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(widget.icon, size: 21, color: iconColor),
                  if (widget.isAiPill)
                    Positioned(
                      top: 6,
                      right: 10,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF83F8CD), Color(0xFF8197FF)],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(vertical: 2.5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: itemBg,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: isDark
                          ? const Color(0xFF2563EB).withValues(alpha: 0.6)
                          : const Color(0xFFDBEAFE),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: itemTextColor,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.isAiPill)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF83F8CD), Color(0xFF8197FF)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'IA ✨',
                      style: TextStyle(
                        color: Color(0xFF002116),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return content;
  }
}

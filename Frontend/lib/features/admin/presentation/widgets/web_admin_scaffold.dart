import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/web_controls_bar.dart';

class WebAdminScaffold extends ConsumerWidget {
  final String activePath;
  final Widget body;
  final String? breadcrumbCategory;
  final String? breadcrumbCurrent;

  const WebAdminScaffold({
    super.key,
    required this.activePath,
    required this.body,
    this.breadcrumbCategory,
    this.breadcrumbCurrent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Admin Portal';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==========================================
          // 1. SIDEBAR FIXE 260px (Stitch Design)
          // ==========================================
          SizedBox(
            width: 260,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.primaryContainer, // #2D3E8C
                boxShadow: [
                  BoxShadow(
                    color: Color(0x141D2338),
                    blurRadius: 20,
                    offset: Offset(4, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Brand Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo_emblem.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.school_rounded,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SmartClass',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'EDTECH • AI ASSISTED',
                                style: TextStyle(
                                  color: AppTheme.onPrimaryContainer,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Section Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: Text(
                      'ADMINISTRATION',
                      style: TextStyle(
                        color: AppTheme.onPrimaryContainer.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),

                  // Nav Links
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      children: [
                        _SidebarNavItem(
                          icon: Icons.dashboard_rounded,
                          label: 'Tableau de bord',
                          isSelected: activePath == 'tableau-de-bord',
                          onTap: () => context.go('/home'),
                        ),
                        _SidebarNavItem(
                          icon: Icons.school_rounded,
                          label: 'Classes',
                          isSelected: activePath == 'classes',
                          onTap: () => context.go('/admin/classes'),
                        ),
                        _SidebarNavItem(
                          icon: Icons.group_rounded,
                          label: 'Utilisateurs',
                          isSelected: activePath == 'utilisateurs',
                          onTap: () => context.go('/admin/users'),
                        ),
                        _SidebarNavItem(
                          icon: Icons.calendar_month_rounded,
                          label: 'Emplois du temps',
                          isSelected: activePath == 'emplois-du-temps',
                          onTap: () => context.go('/admin/planning'),
                        ),
                        _SidebarNavItem(
                          icon: Icons.shield_rounded,
                          label: 'Rapports de fraude',
                          isSelected: activePath == 'rapports-de-fraude',
                          onTap: () => context.go('/admin/frauds'),
                        ),
                        _SidebarNavItem(
                          icon: Icons.settings_rounded,
                          label: 'Paramètres',
                          isSelected: activePath == 'parametres',
                          onTap: () => context.go('/settings'),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Active Session Pill (Stitch Design)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Session Active',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Admin Global',
                                style: TextStyle(
                                  color: AppTheme.onPrimaryContainer,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.verified_user_rounded,
                          color: AppTheme.tertiaryFixed,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==========================================
          // 2. MAIN WORKSPACE (TOPBAR + CONTENT)
          // ==========================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.95),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.outlineVariant.withValues(alpha: 0.4),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: AppTheme.outline.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText:
                                            'Rechercher un cours, un étudiant ou un rapport...',
                                        hintStyle: TextStyle(
                                          color: AppTheme.outline.withValues(alpha: 0.7),
                                          fontSize: 13,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
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
                      const WebControlsBar(),
                      const SizedBox(width: 8),

                      // Notification Bell
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppTheme.onSurfaceVariant,
                              size: 24,
                            ),
                            onPressed: () {},
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.surface,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 14),

                      // Profile Info
                      Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: AppTheme.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Text(
                                'Superviseur',
                                style: TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.secondaryContainer,
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                              style: const TextStyle(
                                color: AppTheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content Area
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
}

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? Colors.white
        : (_isHovered ? AppTheme.primary.withValues(alpha: 0.6) : Colors.transparent);
    final fgColor = widget.isSelected ? AppTheme.primary : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x1A1D2338),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: fgColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          color: fgColor,
                          fontSize: 14,
                          fontWeight:
                              widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
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

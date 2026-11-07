// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  String _getRoleDisplayLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrateur Système';
      case 'teacher':
        return 'Enseignant Certifié';
      default:
        return context.tr('active_student_badge');
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFF4338CA);
      case 'teacher':
        return const Color(0xFF7E22CE);
      default:
        return const Color(0xFF15803D);
    }
  }

  Color _getRoleBgColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFE0E7FF);
      case 'teacher':
        return const Color(0xFFF3E8FF);
      default:
        return const Color(0xFFDCFCE7);
    }
  }

  // ===========================================================================
  // DYNAMIC TAB DISPATCHER
  // ===========================================================================

  Widget _buildActiveTabContent(Color cardBg, Color borderColor, bool isDark) {
    switch (_selectedMenuIndex) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('tab_personal_info'),
          child: _buildPersonalInfoCard(cardBg, borderColor, isDark),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey('tab_security_auth'),
          child: _buildSecurityAuthCard(cardBg, borderColor, isDark),
        );
      case 2:
        return KeyedSubtree(
          key: const ValueKey('tab_notifications'),
          child: _buildNotificationsCard(cardBg, borderColor, isDark),
        );
      case 3:
        return KeyedSubtree(
          key: const ValueKey('tab_appearance'),
          child: _buildAppearanceCard(cardBg, borderColor, isDark),
        );
      case 4:
        return KeyedSubtree(
          key: const ValueKey('tab_privacy_gdpr'),
          child: _buildPrivacyGdprCard(cardBg, borderColor, isDark),
        );
      case 5:
        return KeyedSubtree(
          key: const ValueKey('tab_sessions_devices'),
          child: _buildSessionsDevicesCard(cardBg, borderColor, isDark),
        );
      default:
        return KeyedSubtree(
          key: const ValueKey('tab_default'),
          child: _buildPersonalInfoCard(cardBg, borderColor, isDark),
        );
    }
  }

  // ===========================================================================
  // SECTION 0: BREADCRUMBS & HEADER
  // ===========================================================================

  Widget _buildBreadcrumbs(bool isDark) {
    final style = TextStyle(
      fontSize: 12,
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      fontWeight: FontWeight.w500,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.home_outlined,
            size: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(context.tr('nav_dashboard'), style: style),
          const SizedBox(width: 6),
          Text('/', style: style),
          const SizedBox(width: 6),
          Text(context.tr('nav_my_profile'), style: style),
          const SizedBox(width: 6),
          Text('/', style: style),
          const SizedBox(width: 6),
          Text(
            context.tr('account_settings_title'),
            style: style.copyWith(
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(bool isDark) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final role = authState?.role?.toLowerCase() ?? 'student';
    final isTeacher = role == 'teacher';
    final roleLabel = role == 'admin'
        ? 'Administrateur'
        : (role == 'teacher'
              ? 'Enseignant Certifié'
              : context.tr('active_student_badge'));
    final roleBg = role == 'admin'
        ? const Color(0xFFE0E7FF)
        : (role == 'teacher'
              ? const Color(0xFFF3E8FF)
              : const Color(0xFFDCFCE7));
    final roleFg = role == 'admin'
        ? const Color(0xFF3730A3)
        : (role == 'teacher'
              ? const Color(0xFF6B21A8)
              : const Color(0xFF15803D));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final titleAndBadge = Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              context.tr('account_settings_title'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: roleBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: roleFg,
                ),
              ),
            ),
          ],
        );

        final entBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
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
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.tr('ent_sync_status'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFF15803D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

        final description = Text(
          isTeacher
              ? 'Gérez votre identité académique, vos accès de sécurité et configurez vos flux de notifications pour votre espace enseignant.'
              : context.tr('account_settings_desc'),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.4,
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleAndBadge,
              const SizedBox(height: 8),
              entBadge,
              const SizedBox(height: 10),
              description,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleAndBadge,
                  const SizedBox(height: 6),
                  description,
                ],
              ),
            ),
            const SizedBox(width: 12),
            entBadge,
          ],
        );
      },
    );
  }

  // ===========================================================================
  // LEFT MENU (MENU DE CONFIGURATION)
  // ===========================================================================
}




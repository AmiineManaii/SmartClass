// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  Widget _buildLeftMenuColumn(Color cardBg, Color borderColor, bool isDark) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final role = authState?.role?.toLowerCase() ?? 'student';
    final isTeacher = role == 'teacher';
    final quotaText = role == 'admin'
        ? '45.2 / 250 Go'
        : (isTeacher ? '18.6 / 100 Go' : '2.4 / 20 Go');
    final quotaProgress = role == 'admin' ? 0.181 : (isTeacher ? 0.186 : 0.120);

    final menuItems = [
      (
        Icons.person_outline_rounded,
        context.tr('menu_personal_info'),
        null,
        false,
      ),
      (
        Icons.security_rounded,
        context.tr('menu_security_auth'),
        _twoFactorEnabled
            ? context.tr('two_factor_active_badge')
            : context.tr('two_factor_inactive_badge'),
        false,
      ),
      (
        Icons.notifications_none_rounded,
        context.tr('menu_notifications'),
        null,
        false,
      ),
      (Icons.palette_outlined, context.tr('menu_appearance'), null, false),
      (
        Icons.lock_outline_rounded,
        context.tr('menu_privacy_gdpr'),
        null,
        false,
      ),
      (Icons.devices_rounded, context.tr('menu_sessions_devices'), null, true),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('config_menu_title'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(menuItems.length, (index) {
            final item = menuItems[index];
            final isSelected = _selectedMenuIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: InkWell(
                onTap: () => updateState(() => _selectedMenuIndex = index),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFF1E293B))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.$1,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B)),
                          ),
                        ),
                      ),
                      if (item.$3 != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : (_twoFactorEnabled
                                      ? const Color(0xFFDCFCE7)
                                      : (isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0))),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.$3!,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (_twoFactorEnabled
                                        ? const Color(0xFF15803D)
                                        : (isDark
                                              ? Colors.white70
                                              : const Color(0xFF475569))),
                            ),
                          ),
                        ),
                      if (item.$4)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Storage quota box (Matches Image 1 exactly)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE0E7FF),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTeacher
                          ? 'Stockage Cours & Médias Cloud'
                          : context.tr('cloud_storage_title'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      quotaText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: quotaProgress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFCBD5E1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.cloud_done_rounded,
                      size: 13,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      context.tr('ent_cloud_synced'),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 0: INFORMATIONS PERSONNELLES & PROFIL
  // ===========================================================================
}




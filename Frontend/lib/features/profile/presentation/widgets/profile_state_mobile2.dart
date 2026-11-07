// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  Widget _buildMobileTabsSelector(
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    final tabs = [
      (Icons.person_rounded, context.tr('menu_personal_info'), null),
      (
        Icons.security_rounded,
        context.tr('menu_security_auth'),
        _twoFactorEnabled ? '2FA' : null,
      ),
      (Icons.notifications_rounded, context.tr('menu_notifications'), null),
      (Icons.palette_rounded, context.tr('menu_appearance'), null),
      (Icons.shield_rounded, context.tr('menu_privacy_gdpr'), null),
      (
        Icons.devices_rounded,
        context.tr('menu_sessions_devices'),
        '${_remoteSessions.length + 1}',
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isSelected = _selectedMenuIndex == index;

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 8,
              right: index == tabs.length - 1 ? 0 : 0,
            ),
            child: InkWell(
              onTap: () => updateState(() => _selectedMenuIndex = index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : const Color(0xFFE2E8F0)),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.02,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.$1,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab.$2,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF334155)),
                      ),
                    ),
                    if (tab.$3 != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : (tab.$3 == '2FA'
                                    ? const Color(0xFFDCFCE7)
                                    : (isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFDBEAFE))),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tab.$3!,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (tab.$3 == '2FA'
                                      ? const Color(0xFF15803D)
                                      : (isDark
                                            ? Colors.white
                                            : const Color(0xFF1D4ED8))),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}




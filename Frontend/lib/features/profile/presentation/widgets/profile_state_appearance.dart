// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  Widget _buildAppearanceCard(Color cardBg, Color borderColor, bool isDark) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);
    final typographyAsync = ref.watch(typographyConfigProvider);

    return Container(
      padding: EdgeInsets.all(context.screenWidth >= 1024 ? 24 : 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.desktop_windows_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('menu_appearance'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('appearance_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3 Visual Theme Preview Cards (Clicking instantly changes app theme)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              return isWide
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildThemePreviewCard(
                            title: context.tr('theme_light_title'),
                            subtitle: context.tr('theme_light_desc'),
                            isSelected: currentThemeMode == ThemeMode.light,
                            isDarkCard: false,
                            onTap: () {
                              ref.read(themeModeProvider.notifier).state =
                                  ThemeMode.light;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildThemePreviewCard(
                            title: context.tr('theme_dark_title'),
                            subtitle: context.tr('theme_dark_desc'),
                            isSelected: currentThemeMode == ThemeMode.dark,
                            isDarkCard: true,
                            onTap: () {
                              ref.read(themeModeProvider.notifier).state =
                                  ThemeMode.dark;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildThemePreviewCard(
                            title: context.tr('theme_system_title'),
                            subtitle: context.tr('theme_system_desc'),
                            isSelected: currentThemeMode == ThemeMode.system,
                            isSplitCard: true,
                            onTap: () {
                              ref.read(themeModeProvider.notifier).state =
                                  ThemeMode.system;
                            },
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildThemePreviewCard(
                          title: context.tr('theme_light_title'),
                          subtitle: context.tr('theme_light_desc'),
                          isSelected: currentThemeMode == ThemeMode.light,
                          isDarkCard: false,
                          onTap: () {
                            ref.read(themeModeProvider.notifier).state =
                                ThemeMode.light;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildThemePreviewCard(
                          title: context.tr('theme_dark_title'),
                          subtitle: context.tr('theme_dark_desc'),
                          isSelected: currentThemeMode == ThemeMode.dark,
                          isDarkCard: true,
                          onTap: () {
                            ref.read(themeModeProvider.notifier).state =
                                ThemeMode.dark;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildThemePreviewCard(
                          title: context.tr('theme_system_title'),
                          subtitle: context.tr('theme_system_desc'),
                          isSelected: currentThemeMode == ThemeMode.system,
                          isSplitCard: true,
                          onTap: () {
                            ref.read(themeModeProvider.notifier).state =
                                ThemeMode.system;
                          },
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),

          // Language Selector Cards (Clicking instantly changes app locale)
          Text(
            context.tr('language_title'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('language_desc'),
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLanguageOptionCard(
                  flag: '🇫🇷',
                  name: context.tr('lang_french'),
                  localeCode: 'fr',
                  isSelected: currentLocale.startsWith('fr'),
                  isDark: isDark,
                  onTap: () {
                    ref.read(localeProvider.notifier).state = 'fr';
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildLanguageOptionCard(
                  flag: '🇬🇧',
                  name: context.tr('lang_english'),
                  localeCode: 'en',
                  isSelected: currentLocale.startsWith('en'),
                  isDark: isDark,
                  onTap: () {
                    ref.read(localeProvider.notifier).state = 'en';
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, fontConstraints) {
              final isCompact = fontConstraints.maxWidth < 460;
              final zoomWidget = typographyAsync.when(
                data: (config) {
                  final scalePct = (config.textScaleFactor * 100).round();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Text(
                            'A-',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 28,
                          ),
                          onPressed: () {
                            final newScale = (config.textScaleFactor - 0.1)
                                .clamp(0.85, 1.4);
                            ref
                                .read(typographyConfigProvider.notifier)
                                .updateTextScale(newScale);
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$scalePct% ${scalePct == 100 ? "[Standard]" : ""}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Text(
                            'A+',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 28,
                          ),
                          onPressed: () {
                            final newScale = (config.textScaleFactor + 0.1)
                                .clamp(0.85, 1.4);
                            ref
                                .read(typographyConfigProvider.notifier)
                                .updateTextScale(newScale);
                          },
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              );

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.text_fields_rounded,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  context.tr('font_comfort_title'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr('font_comfort_desc'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(child: zoomWidget),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(
                            Icons.text_fields_rounded,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            size: 20,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('font_comfort_title'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.tr('font_comfort_desc'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          zoomWidget,
                        ],
                      ),
              );
            },
          ),
          const SizedBox(height: 12),

          // High Contrast Switch
          _buildNotificationSwitchRow(
            icon: Icons.contrast_rounded,
            title: context.tr('high_contrast_title'),
            subtitle: context.tr('high_contrast_desc'),
            value: _highContrast,
            isDark: isDark,
            onChanged: (val) {
              updateState(() => _highContrast = val);
              _showSuccessSnackBar(
                val ? 'Mode contraste élevé activé' : 'Mode contraste standard',
              );
            },
          ),
          const SizedBox(height: 10),

          // Reduce Animations Switch
          _buildNotificationSwitchRow(
            icon: Icons.slow_motion_video_rounded,
            title: context.tr('reduce_animations_title'),
            subtitle: context.tr('reduce_animations_desc'),
            value: _reduceAnimations,
            isDark: isDark,
            onChanged: (val) {
              updateState(() => _reduceAnimations = val);
              _showSuccessSnackBar(
                val ? 'Animations atténuées' : 'Animations standards activées',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOptionCard({
    required String flag,
    required String name,
    required String localeCode,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: 0.08)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFCBD5E1)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2563EB),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 4: CONFIDENTIALITÉ & RGPD
  // ===========================================================================
}




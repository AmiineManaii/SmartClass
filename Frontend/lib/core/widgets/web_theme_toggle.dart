import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../theme/app_theme.dart';

/// Sélecteur de thème élégant (Mode Clair ☀️ / Mode Sombre 🌙) pour les interfaces Web
/// avec indicateur coulissant (sliding pill) animé et rotation fluide des icônes.
class WebThemeToggle extends ConsumerWidget {
  final bool isDarkForced;

  const WebThemeToggle({
    super.key,
    this.isDarkForced = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = isDarkForced ||
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platformDark);

    final locale = ref.watch(localeProvider);
    final isFr = locale == 'fr';

    final containerBg = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : AppTheme.surfaceContainerLow;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : AppTheme.outlineVariant.withValues(alpha: 0.5);

    final activePillBg = isDark
        ? const Color(0xFF2A364F)
        : Colors.white;
    final activeIconColor = isDark
        ? Colors.amber.shade300
        : AppTheme.primary;
    final inactiveIconColor = isDark
        ? Colors.white54
        : AppTheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: SizedBox(
        width: 68,
        height: 32,
        child: Stack(
          children: [
            // Smooth sliding indicator pill
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 33,
                height: 32,
                decoration: BoxDecoration(
                  color: activePillBg,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.28 : 0.08,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            // Clickable option icons
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: isFr ? 'Mode Clair' : 'Light Mode',
                    waitDuration: const Duration(milliseconds: 300),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (isDark) {
                            ref.read(themeModeProvider.notifier).state =
                                ThemeMode.light;
                          }
                        },
                        child: Center(
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeInOut,
                            turns: !isDark ? 0 : 0.15,
                            child: Icon(
                              Icons.light_mode_rounded,
                              size: 16,
                              color:
                                  !isDark ? activeIconColor : inactiveIconColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Tooltip(
                    message: isFr ? 'Mode Sombre' : 'Dark Mode',
                    waitDuration: const Duration(milliseconds: 300),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (!isDark) {
                            ref.read(themeModeProvider.notifier).state =
                                ThemeMode.dark;
                          }
                        },
                        child: Center(
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeInOut,
                            turns: isDark ? 0 : -0.15,
                            child: Icon(
                              Icons.dark_mode_rounded,
                              size: 16,
                              color:
                                  isDark ? activeIconColor : inactiveIconColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

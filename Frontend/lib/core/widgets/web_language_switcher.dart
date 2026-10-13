import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../theme/app_theme.dart';

/// Sélecteur de langue bilingue (Français 🇫🇷 / Anglais 🇬🇧) pour les interfaces Web
/// avec indicateur coulissant (sliding pill) fluide et adaptation thème clair/sombre.
class WebLanguageSwitcher extends ConsumerWidget {
  final bool? isDark;

  const WebLanguageSwitcher({
    super.key,
    this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isFr = currentLocale == 'fr';

    final themeMode = ref.watch(themeModeProvider);
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final effectiveDark = isDark ??
        (themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system && platformDark));

    final containerBg = effectiveDark
        ? Colors.white.withValues(alpha: 0.10)
        : AppTheme.surfaceContainerLow;
    final borderColor = effectiveDark
        ? Colors.white.withValues(alpha: 0.18)
        : AppTheme.outlineVariant.withValues(alpha: 0.5);

    final activePillBg = effectiveDark
        ? const Color(0xFF2A364F)
        : Colors.white;
    final activeTextColor = effectiveDark ? Colors.white : AppTheme.primary;
    final inactiveTextColor =
        effectiveDark ? Colors.white60 : AppTheme.onSurfaceVariant;

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 4),
            child: Icon(
              Icons.language_rounded,
              size: 16,
              color: effectiveDark ? Colors.white70 : AppTheme.onSurfaceVariant,
            ),
          ),
          SizedBox(
            width: 72,
            height: 32,
            child: Stack(
              children: [
                // Sliding indicator pill
                AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  alignment: isFr ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    width: 35,
                    height: 32,
                    decoration: BoxDecoration(
                      color: activePillBg,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: effectiveDark ? 0.28 : 0.08,
                          ),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                // Interactive clickable labels
                Row(
                  children: [
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (!isFr) {
                              ref.read(localeProvider.notifier).state = 'fr';
                            }
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              style: TextStyle(
                                color: isFr ? activeTextColor : inactiveTextColor,
                                fontSize: 12,
                                fontWeight:
                                    isFr ? FontWeight.w800 : FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                              child: const Text('FR'),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (isFr) {
                              ref.read(localeProvider.notifier).state = 'en';
                            }
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              style: TextStyle(
                                color: !isFr ? activeTextColor : inactiveTextColor,
                                fontSize: 12,
                                fontWeight:
                                    !isFr ? FontWeight.w800 : FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                              child: const Text('EN'),
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
        ],
      ),
    );
  }
}

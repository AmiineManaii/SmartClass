import 'package:flutter/material.dart';

import 'web_language_switcher.dart';
import 'web_theme_toggle.dart';

/// Barre de contrôles unifiée pour le Web (Thème Clair/Sombre + Langue FR/EN).
class WebControlsBar extends StatelessWidget {
  final bool isDarkForced;

  const WebControlsBar({
    super.key,
    this.isDarkForced = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WebThemeToggle(isDarkForced: isDarkForced),
        const SizedBox(width: 8),
        WebLanguageSwitcher(isDark: isDarkForced ? true : null),
      ],
    );
  }
}

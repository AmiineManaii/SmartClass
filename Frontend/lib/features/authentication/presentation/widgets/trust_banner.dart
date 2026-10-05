import 'package:flutter/material.dart';

class TrustBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconBackground;
  final Color? iconColor;

  const TrustBanner({
    required this.icon,
    required this.text,
    this.iconBackground,
    this.iconColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow ?? colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackground ?? colorScheme.tertiaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor ?? colorScheme.onTertiaryFixed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

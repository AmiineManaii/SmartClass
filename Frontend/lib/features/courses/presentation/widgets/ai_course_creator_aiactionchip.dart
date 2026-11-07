part of '../pages/ai_course_creator_page.dart';
class _AiActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final bool filled;
  final VoidCallback onTap;

  const _AiActionChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: filled
          ? colorScheme.primaryFixed
          : colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: filled
                      ? colorScheme.onPrimaryFixed
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte d'erreur affichée inline quand la génération échoue

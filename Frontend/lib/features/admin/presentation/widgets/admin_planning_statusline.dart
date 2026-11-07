part of '../pages/admin_planning_page.dart';
class _StatusLine extends StatelessWidget {
  final String textKey;

  const _StatusLine({required this.textKey});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (IconData icon, Color color) = switch (textKey) {
      'admin_confirmed_open' => (Icons.circle_outlined, theme.warningColor),
      'admin_session_validated' => (
        Icons.check_circle_outline_rounded,
        colorScheme.tertiary,
      ),
      'admin_group_full' => (
        Icons.group_outlined,
        colorScheme.onSurfaceVariant,
      ),
      'admin_hybrid_on' => (Icons.videocam_outlined, colorScheme.secondary),
      _ => (Icons.info_outline, colorScheme.onSurfaceVariant),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            context.tr(textKey),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}


part of '../widgets/student_dashboard_view.dart';
class _ClassTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme colorScheme;
  final Color? accent;

  const _ClassTag({
    required this.label,
    required this.icon,
    required this.colorScheme,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


part of '../widgets/teacher_dashboard_view.dart';
class _QuickToolItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _QuickToolItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
  });
}


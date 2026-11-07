part of '../pages/ai_course_creator_page.dart';
class _SegmentPill extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentPill({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0xFF4F46E5).withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? (isDark
                      ? const Color(0xFF312E81).withValues(alpha: 0.35)
                      : const Color(0xFFEEF2FF))
                : (isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF4F46E5)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0)),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected
                      ? (isDark ? Colors.white : const Color(0xFF1E1B4B))
                      : (isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569)),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9.5,
                  color: selected
                      ? (isDark
                            ? const Color(0xFFA5B4FC)
                            : const Color(0xFF4F46E5))
                      : (isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8)),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

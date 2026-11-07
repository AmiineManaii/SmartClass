part of '../pages/course_section_builder_page.dart';
extension on _CourseSectionBuilderPageState {
  Widget _buildSectionNavChip({
    required BuildContext context,
    required int index,
    required CourseSectionEntry section,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isValidated = section.status == CourseSectionStatus.validated;
    final isGenerated = section.status == CourseSectionStatus.generated;

    Color bg;
    Color fg;
    Widget iconWidget;

    if (isCurrent) {
      bg = colorScheme.primary;
      fg = colorScheme.onPrimary;
      iconWidget =
          const SmartLoader.small(customSize: 12, color: Colors.white);
    } else if (isValidated) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      iconWidget = Icon(Icons.check_circle_rounded, size: 14, color: fg);
    } else if (isGenerated) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade800;
      iconWidget = Icon(Icons.edit_note_rounded, size: 14, color: fg);
    } else {
      bg = colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
      fg = colorScheme.onSurfaceVariant;
      iconWidget = Icon(Icons.hourglass_empty_rounded, size: 13, color: fg);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent
                ? colorScheme.primary
                : (isValidated
                    ? Colors.green.shade300
                    : colorScheme.outlineVariant.withValues(alpha: 0.4)),
            width: isCurrent ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 5),
            Text(
              'S${index + 1}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


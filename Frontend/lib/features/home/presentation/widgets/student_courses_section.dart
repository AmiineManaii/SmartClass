import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../infrastructure/datasources/mock_student_dashboard_datasource.dart';

class StudentCoursesSection extends StatelessWidget {
  final List<StudentCourseProgress> courses;
  final VoidCallback onViewAll;
  final ValueChanged<String>? onCourseTap;

  const StudentCoursesSection({
    required this.courses,
    required this.onViewAll,
    this.onCourseTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            // Left: Title + enrolled count
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(
                  context.tr('my_courses'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.tr('enrolled_count', args: {'count': '4'}),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            // Right: "Voir tout >"
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('view_all'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colorScheme.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Course cards list
        for (int i = 0; i < courses.length; i++) ...[
          _CourseProgressCard(
            course: courses[i],
            onTap: () => onCourseTap?.call(courses[i].id),
          ),
          if (i < courses.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  final StudentCourseProgress course;
  final VoidCallback onTap;

  const _CourseProgressCard({
    required this.course,
    required this.onTap,
  });

  IconData _getIconData(String name) {
    switch (name) {
      case 'terminal':
        return Icons.terminal_rounded;
      case 'database':
        return Icons.storage_rounded;
      case 'memory':
        return Icons.memory_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  (Color, Color) _getIconColors(ColorScheme colors, bool isDark, String iconName) {
    if (isDark) {
      switch (iconName) {
        case 'terminal':
          return (const Color(0xFF1E2850), const Color(0xFF9EAEFF));
        case 'database':
          return (const Color(0xFF222C5A), const Color(0xFF8197FF));
        case 'memory':
          return (const Color(0xFF262D4A), const Color(0xFFDEE1FF));
        default:
          return (const Color(0xFF1E2850), const Color(0xFF9EAEFF));
      }
    }
    switch (iconName) {
      case 'terminal':
        return (colors.primaryFixed, colors.primary);
      case 'database':
        return (colors.secondaryFixed, colors.secondary);
      case 'memory':
        return (colors.surfaceContainerHighest, colors.onSurface);
      default:
        return (colors.primaryFixed, colors.primary);
    }
  }

  (Color, Color) _getBadgeColors(ColorScheme colors, bool isDark, String tone) {
    if (tone == 'tertiary') {
      if (isDark) {
        return (const Color(0xFF13362A), const Color(0xFF5CD8AF));
      }
      return (const Color(0xFFE4F8F1), const Color(0xFF0F9D78));
    }
    return (colors.surfaceContainer, colors.onSurfaceVariant);
  }

  Color _getProgressColor(ColorScheme colors, bool isDark, String tone) {
    if (isDark) {
      switch (tone) {
        case 'primary':
          return const Color(0xFF7A8FFF);
        case 'secondary':
          return const Color(0xFF657DE8);
        case 'surfaceTint':
          return const Color(0xFF8D9DF2);
        default:
          return const Color(0xFF7A8FFF);
      }
    }
    switch (tone) {
      case 'primary':
        return colors.primary;
      case 'secondary':
        return colors.secondary;
      case 'surfaceTint':
        return colors.surfaceTint;
      default:
        return colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final (iconBg, iconFg) = _getIconColors(colorScheme, isDark, course.iconName);
    final (badgeBg, badgeFg) = _getBadgeColors(colorScheme, isDark, course.badgeTone);
    final progressColor = _getProgressColor(colorScheme, isDark, course.progressColorTone);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _getIconData(course.iconName),
                      size: 22,
                      color: iconFg,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          course.lastLesson,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      course.badgeText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: badgeFg,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('student_course_progress'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${course.progressPercent}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      height: 7,
                      width: double.infinity,
                      color: isDark ? const Color(0xFF202640) : colorScheme.surfaceContainer,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: course.progressPercent / 100.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: progressColor,
                            borderRadius: BorderRadius.circular(9999),
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
      ),
    );
  }
}

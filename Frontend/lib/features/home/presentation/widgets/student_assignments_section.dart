import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../infrastructure/datasources/mock_student_dashboard_datasource.dart';

class StudentAssignmentsSection extends StatelessWidget {
  final List<StudentAssignment> assignments;
  final VoidCallback onHistoryTap;
  final ValueChanged<String>? onAssignmentAction;

  const StudentAssignmentsSection({
    required this.assignments,
    required this.onHistoryTap,
    this.onAssignmentAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header — Stitch: Row(justify-between) with [Title + Badge] left, [Historique >] right
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            // Left: Title + pending badge
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  context.tr('upcoming_homework'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    context.tr(
                      'pending_count',
                      args: {'count': assignments.length.toString()},
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            // Right: "Historique >"
            InkWell(
              onTap: onHistoryTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('history'),
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
        // Assignments cards list
        for (int i = 0; i < assignments.length; i++) ...[
          _AssignmentCard(
            assignment: assignments[i],
            onAction: () => onAssignmentAction?.call(assignments[i].id),
          ),
          if (i < assignments.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final StudentAssignment assignment;
  final VoidCallback onAction;

  const _AssignmentCard({
    required this.assignment,
    required this.onAction,
  });

  IconData _getIconData(String name) {
    switch (name) {
      case 'assignment_late':
        return Icons.assignment_late_rounded;
      case 'code_blocks':
        return Icons.code_rounded;
      case 'functions':
        return Icons.functions_rounded;
      default:
        return Icons.assignment_rounded;
    }
  }

  (Color, Color) _getIconColors(ColorScheme colors, StudentAssignment item) {
    if (item.isUrgent) {
      return (colors.errorContainer, colors.onErrorContainer);
    }
    if (item.iconName == 'code_blocks') {
      return (colors.surfaceContainerHigh, colors.primary);
    }
    return (colors.surfaceContainerLow, colors.onSurfaceVariant);
  }

  Widget _buildSubtitle(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    if (assignment.hasAutoAiValidation) {
      final isDark = theme.brightness == Brightness.dark;
      final aiColor = isDark ? colorScheme.tertiaryFixedDim : colorScheme.onTertiaryFixedVariant;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 14,
            color: aiColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              context.tr('auto_ai_validation'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: aiColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (assignment.extraDetails != null) {
      return Text(
        assignment.extraDetails!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (assignment.questionsCount != null) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 2,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.format_list_numbered_rounded,
                size: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 3),
              Text(
                context.tr(
                  'questions_count',
                  args: {'count': assignment.questionsCount.toString()},
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Text(
            '·',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 3),
              Text(
                context.tr(
                  'est_time',
                  args: {'min': assignment.estDurationMinutes.toString()},
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (iconBg, iconFg) = _getIconColors(colorScheme, assignment);

    return Container(
      padding: const EdgeInsets.all(14),
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
          // Top Row: [Icon] on left, [Title/Subtitle + Deadline Badge] in Expanded
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
                  _getIconData(assignment.iconName),
                  size: 22,
                  color: iconFg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          assignment.title,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.25,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: assignment.isUrgent
                                ? colorScheme.errorContainer
                                : colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (assignment.isUrgent) ...[
                                Icon(
                                  Icons.alarm_rounded,
                                  size: 12,
                                  color: colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 3),
                              ],
                              Flexible(
                                child: Text(
                                  assignment.deadlineText,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: assignment.isUrgent
                                        ? colorScheme.onErrorContainer
                                        : colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildSubtitle(context, theme, colorScheme),
                  ],
                ),
              ),
            ],
          ),
          // Bottom Row (if action or weight note present)
          if (assignment.actionType != 'none') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    assignment.weightNote ?? assignment.submissionType ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontStyle: assignment.weightNote != null
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (assignment.actionType == 'start') ...[
                  ElevatedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(
                      context.tr('starts_action'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ] else if (assignment.actionType == 'deposit') ...[
                  ElevatedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(
                      context.tr('deposit_action'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainer,
                      foregroundColor: colorScheme.onSurface,
                      elevation: 0,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

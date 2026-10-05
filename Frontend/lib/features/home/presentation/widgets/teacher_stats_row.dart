import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../infrastructure/datasources/mock_teacher_dashboard_datasource.dart';
import 'teacher_icons.dart';

class TeacherStatsRow extends StatelessWidget {
  final List<TeacherStat> stats;

  const TeacherStatsRow({required this.stats, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          Expanded(child: _TeacherStatCard(stat: stats[i])),
          if (i < stats.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _TeacherStatCard extends StatelessWidget {
  final TeacherStat stat;

  const _TeacherStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (Color iconBg, Color iconColor, Color badgeBg, Color badgeColor) = switch (stat.tone) {
      TeacherStatTone.success => (
          colorScheme.surfaceContainerHigh,
          colorScheme.primary,
          colorScheme.tertiaryFixed.withValues(alpha: 0.4),
          colorScheme.tertiary,
        ),
      TeacherStatTone.secondary => (
          colorScheme.surfaceContainer,
          colorScheme.secondary,
          colorScheme.surfaceContainerHigh,
          colorScheme.secondary,
        ),
      TeacherStatTone.error => (
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
          colorScheme.errorContainer,
          colorScheme.error,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(teacherIconFromName(stat.icon), size: 18, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(stat.value, style: theme.textTheme.headlineSmall),
          Text(
            context.tr(stat.labelKey),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              context.tr(stat.badgeKey),
              style: theme.textTheme.labelSmall?.copyWith(color: badgeColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../infrastructure/datasources/mock_student_dashboard_datasource.dart';

class StudentMotivationCards extends StatelessWidget {
  final StudentMotivationStats stats;

  const StudentMotivationCards({required this.stats, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final card1 = _StatCard(
          leading: const Text(
            '🔥',
            style: TextStyle(fontSize: 20),
          ),
          caption: context.tr('active_streak'),
          value: context.tr(
            'streak_consecutive_days',
            args: {'count': stats.streakDays.toString()},
          ),
        );

        final card2 = _StatCard(
          leading: Icon(
            Icons.verified,
            size: 22,
            color: Theme.of(context).colorScheme.secondary,
          ),
          caption: context.tr('weekly_goal'),
          value: context.tr(
            'goal_reached',
            args: {'pct': stats.weeklyGoalPercent.toString()},
          ),
        );

        if (constraints.maxWidth < 280) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 10),
              card2,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 10),
            Expanded(child: card2),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final Widget leading;
  final String caption;
  final String value;

  const _StatCard({
    required this.leading,
    required this.caption,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: leading,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  caption.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.08,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

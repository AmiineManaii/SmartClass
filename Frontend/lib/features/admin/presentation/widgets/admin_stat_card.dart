import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/admin_overview.dart';

IconData adminIconFromName(String name) {
  switch (name) {
    case 'school':
      return Icons.school_rounded;
    case 'badge':
      return Icons.badge_outlined;
    case 'class':
      return Icons.class_outlined;
    case 'warning':
      return Icons.warning_rounded;
    case 'meeting_room':
      return Icons.meeting_room_outlined;
    case 'manage_accounts':
      return Icons.manage_accounts_outlined;
    case 'groups':
      return Icons.groups_outlined;
    case 'calendar_month':
      return Icons.calendar_month_outlined;
    case 'shield':
      return Icons.shield_outlined;
    case 'laptop':
      return Icons.laptop_chromebook_outlined;
    case 'functions':
      return Icons.functions_rounded;
    case 'psychology':
      return Icons.psychology_outlined;
    case 'lan':
      return Icons.lan_outlined;
    default:
      return Icons.dashboard_outlined;
  }
}

/// 2x2 stat card from the admin dashboard mockup.
class AdminStatCard extends StatelessWidget {
  final AdminStat stat;

  const AdminStatCard({required this.stat, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAlert = stat.tone == AdminStatTone.error;

    final (Color badgeBg, Color badgeFg) = switch (stat.tone) {
      AdminStatTone.error => (colorScheme.errorContainer, colorScheme.onErrorContainer),
      AdminStatTone.success => (colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
      AdminStatTone.warning => (colorScheme.tertiaryFixed, colorScheme.onTertiaryFixed),
      AdminStatTone.info => stat.id == 'students'
          ? (colorScheme.secondaryFixed, colorScheme.onSecondaryFixed)
          : (colorScheme.surfaceContainer, colorScheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: stat.highlighted ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerLowest,
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
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isAlert ? colorScheme.errorContainer : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  adminIconFromName(stat.icon),
                  size: 20,
                  color: isAlert ? colorScheme.error : colorScheme.primary,
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    context.tr(stat.badgeKey, args: stat.badgeArgs),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeFg,
                      fontWeight: isAlert ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stat.value,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: isAlert ? colorScheme.error : colorScheme.onSurface,
              height: 1.1,
            ),
          ),
          Text(
            context.tr(stat.labelKey),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

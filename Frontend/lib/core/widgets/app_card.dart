import 'package:flutter/material.dart';
import '../extensions/extensions.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final List<BoxShadow>? shadows;
  final BorderRadius? borderRadius;
  final Border? border;
  final bool isSelected;
  
  const AppCard({
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.shadows,
    this.borderRadius,
    this.border,
    this.isSelected = false,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);
    final effectiveColor = color ?? colorScheme.surface;
    final effectiveShadows = shadows ?? _getDefaultShadows(isDark, isSelected);
    final effectiveBorder = border ?? Border.all(
      color: isSelected 
          ? colorScheme.primary 
          : (isDark 
              ? colorScheme.outlineVariant.withValues(alpha: 0.2)
              : colorScheme.primary.withValues(alpha: 0.06)),
      width: isSelected ? 2 : 1,
    );
    
    final shape = RoundedRectangleBorder(
      borderRadius: effectiveBorderRadius,
      side: effectiveBorder.top,
    );

    final Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    final Widget card = Material(
      color: effectiveColor,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: effectiveBorderRadius,
              child: content,
            )
          : content,
    );

    if (effectiveShadows.isNotEmpty) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          boxShadow: effectiveShadows,
        ),
        child: card,
      );
    }

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: card,
      );
    }

    return card;
  }
  
  List<BoxShadow> _getDefaultShadows(bool isDark, bool isSelected) {
    if (isSelected) {
      return [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.08),
          offset: const Offset(0, 10),
          blurRadius: 25,
          spreadRadius: -5,
        ),
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.03),
          offset: const Offset(0, 4),
          blurRadius: 6,
          spreadRadius: -2,
        ),
      ];
    }
    
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.04),
        offset: const Offset(0, 2),
        blurRadius: 8,
      ),
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.02),
        offset: const Offset(0, 1),
        blurRadius: 2,
      ),
    ];
  }
}

class AppCardHeader extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  
  const AppCardHeader({
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleMedium!,
                  child: title,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class AppCardContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  
  const AppCardContent({
    required this.child,
    this.padding,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }
}

class AppCardActions extends StatelessWidget {
  final List<Widget> actions;
  final MainAxisAlignment alignment;
  final EdgeInsetsGeometry? padding;
  
  const AppCardActions({
    required this.actions,
    this.alignment = MainAxisAlignment.end,
    this.padding,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: actions
            .expand((widget) => [widget, const SizedBox(width: 8)])
            .take(actions.length * 2 - 1)
            .toList(),
      ),
    );
  }
}

class AppCourseCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? progress;
  final double? progressValue;
  final String? status;
  final Color? statusColor;
  final Widget? thumbnail;
  final VoidCallback? onTap;
  final List<Widget>? tags;
  
  const AppCourseCard({
    required this.title,
    this.subtitle,
    this.progress,
    this.progressValue,
    this.status,
    this.statusColor,
    this.thumbnail,
    this.onTap,
    this.tags,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumbnail != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: thumbnail!,
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tags != null && tags!.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags!,
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (progress != null || progressValue != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (progressValue != null) ...[
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progressValue,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (progress != null)
                        Text(
                          progress!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
                if (status != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (statusColor ?? colorScheme.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      status!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor ?? colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppGroupCard extends StatelessWidget {
  final String name;
  final String? level;
  final int memberCount;
  final String? role;
  final String? invitationCode;
  final VoidCallback? onTap;
  final VoidCallback? onInvite;
  
  const AppGroupCard({
    required this.name,
    this.level,
    required this.memberCount,
    this.role,
    this.invitationCode,
    this.onTap,
    this.onInvite,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.groups_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (role != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          role!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (level != null) ...[
                      Text(
                        level!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '$memberCount membres',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (invitationCode != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.vpn_key_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Code: $invitationCode',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onInvite != null)
            IconButton(
              icon: Icon(Icons.person_add_rounded, color: colorScheme.primary),
              onPressed: onInvite,
              tooltip: 'Inviter',
            ),
        ],
      ),
    );
  }
}

class AppExamCard extends StatelessWidget {
  final String title;
  final String? description;
  final DateTime? date;
  final Duration? duration;
  final String? status;
  final Color? statusColor;
  final int? questionCount;
  final int? score;
  final bool isSimulation;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  
  const AppExamCard({
    required this.title,
    this.description,
    this.date,
    this.duration,
    this.status,
    this.statusColor,
    this.questionCount,
    this.score,
    this.isSimulation = false,
    this.onTap,
    this.onStart,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isSimulation ? colorScheme.tertiary : colorScheme.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSimulation ? Icons.science_rounded : Icons.quiz_rounded,
                  color: isSimulation ? colorScheme.tertiary : colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null)
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (statusColor ?? colorScheme.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    status!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor ?? colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (date != null) ...[
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  date!.formatDate(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (duration != null) ...[
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${duration!.inMinutes} min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (questionCount != null) ...[
                Icon(
                  Icons.help_outline_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '$questionCount questions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (score != null) ...[
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$score%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          if (onStart != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onStart,
                child: Text(isSimulation ? 'Commencer la simulation' : 'Commencer l\'examen'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

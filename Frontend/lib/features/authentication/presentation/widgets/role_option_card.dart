import 'package:flutter/material.dart';

class RoleTag {
  final IconData icon;
  final String label;

  const RoleTag({required this.icon, required this.label});
}

class RoleOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<RoleTag> tags;
  final bool selected;
  final bool showRecommended;
  final String recommendedLabel;
  final VoidCallback? onTap;

  const RoleOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    this.tags = const [],
    this.selected = false,
    this.showRecommended = false,
    this.recommendedLabel = '',
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLowest ?? colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colorScheme.primaryContainer : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: selected ? 0.08 : 0.04),
                offset: const Offset(0, 2),
                blurRadius: selected ? 12 : 8,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? colorScheme.primaryFixed : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected ? colorScheme.primaryContainer : colorScheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(title, style: theme.textTheme.labelLarge),
                        ),
                        if (showRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryFixed,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              recommendedLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSecondaryFixed,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(tag.icon, size: 13, color: colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(tag.label, style: theme.textTheme.labelSmall),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: selected
                    ? Icon(Icons.check, color: colorScheme.onPrimary, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

part of '../pages/class_detail_page.dart';
class _TeacherCard extends StatelessWidget {
  const _TeacherCard({required this.entry, required this.isReferent});

  final _TeacherEntry entry;
  final bool isReferent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initials =
        (entry.firstName.isNotEmpty ? entry.firstName[0] : '') +
        (entry.lastName.isNotEmpty ? entry.lastName[0] : '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReferent
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: isReferent ? 1.2 : 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isReferent
                ? colorScheme.primary
                : colorScheme.secondaryContainer,
            child: Text(
              initials.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isReferent ? Colors.white : colorScheme.secondary,
              ),
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
                      child: Text(
                        '${entry.firstName} ${entry.lastName}'.trim(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isReferent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          'Référent',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.subjects
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.weeklyHours != null &&
                                    item.weeklyHours!.isNotEmpty
                                ? '${item.subject} · ${item.weeklyHours}'
                                : item.subject,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (entry.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.email,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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


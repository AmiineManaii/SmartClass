part of '../pages/admin_planning_page.dart';
class _PromoCard extends StatelessWidget {
  final AdminClassSummary? selectedClass;

  const _PromoCard({required this.selectedClass});

  static String _levelLabel(BuildContext context, ClassLevel? level) {
    switch (level) {
      case ClassLevel.master:
        return context.tr('admin_filter_master');
      case ClassLevel.doctorat:
        return context.tr('admin_filter_doctorat');
      case ClassLevel.licence:
      case null:
        return context.tr('admin_filter_licence');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_outlined,
                size: 16,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('admin_active_promo').toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.secondary,
                  letterSpacing: 0.06,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 14,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _levelLabel(context, selectedClass?.level),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedClass?.title ?? 'â€”',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _MetaChip(
                icon: Icons.groups_outlined,
                text:
                    '${selectedClass?.students ?? 0} ${context.tr('admin_stat_students')}',
              ),
              if ((selectedClass?.promoTag ?? '').isNotEmpty)
                _MetaChip(icon: null, text: selectedClass!.promoTag),
            ],
          ),
        ],
      ),
    );
  }
}


part of '../pages/admin_planning_page.dart';
class _ClassSelector extends StatelessWidget {
  final List<AdminClassSummary> classes;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const _ClassSelector({
    required this.classes,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = classes.where((c) => c.id == selectedId);
    final label = selected.isEmpty ? classes.first.title : selected.first.title;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          final picked = await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (sheetContext) {
              final sheetTheme = Theme.of(sheetContext);
              return SafeArea(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: classes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    title: Text(
                      classes[i].title,
                      style: sheetTheme.textTheme.bodyMedium,
                    ),
                    subtitle: Text(
                      classes[i].promoTag,
                      style: sheetTheme.textTheme.bodySmall,
                    ),
                    trailing: classes[i].id == selectedId
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(classes[i].id),
                  ),
                ),
              );
            },
          );
          if (picked != null) onSelected(picked);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.school_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


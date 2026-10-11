import 'package:flutter/material.dart';

/// Horizontally scrollable filter chips with optional counts.
class AdminFilterChips<T> extends StatelessWidget {
  final List<AdminFilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const AdminFilterChips({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            _Chip<T>(
              option: options[i],
              selected: options[i].value == selected,
              onTap: () => onSelected(options[i].value),
              colorScheme: colorScheme,
              theme: theme,
            ),
            if (i < options.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class AdminFilterOption<T> {
  final T value;
  final String label;
  final String? count;

  const AdminFilterOption({required this.value, required this.label, this.count});
}

class _Chip<T> extends StatelessWidget {
  final AdminFilterOption<T> option;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _Chip({
    required this.option,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colorScheme.primary : colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                option.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (option.count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.onPrimary.withValues(alpha: 0.25)
                        : colorScheme.secondaryFixed,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    option.count!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSecondaryFixed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

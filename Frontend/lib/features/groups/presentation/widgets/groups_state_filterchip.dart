part of '../pages/groups_page.dart';
extension on _GroupsPageState {
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _roleFilter == value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : theme.colorScheme.onSurfaceVariant,
      ),
      selectedColor: const Color(0xFF122675),
      backgroundColor: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF122675)
            : (isDark
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.2)
                : const Color(0xFFE2E8F0)),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      onSelected: (selected) {
        updateState(() {
          _roleFilter = value;
        });
      },
    );
  }

}

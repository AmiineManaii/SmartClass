part of '../pages/groups_page.dart';
extension on _GroupsPageState {
  Widget _buildSearchAndFilters(
    BuildContext context, {
    required bool isTeacherOrAdmin,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHigh
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une classe, mati├¿re ou niveau...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Role Filter segmented chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL', 'Tous les groupes'),
              const SizedBox(width: 8),
              if (isTeacherOrAdmin) ...[
                _buildFilterChip('TEACHER', 'Mes Enseignements'),
                const SizedBox(width: 8),
              ],
              _buildFilterChip('STUDENT', 'Inscriptions'),
            ],
          ),
        ),
      ],
    );
  }

}

part of '../pages/class_detail_page.dart';
class _StudentsTab extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final List<Map<String, dynamic>> members;
  final bool canManage;
  final ValueChanged<Map<String, dynamic>> onRemoveStudent;

  const _StudentsTab({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.members,
    required this.canManage,
    required this.onRemoveStudent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher un étudiant par nom ou email...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: members.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 48,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'Aucun étudiant ne correspond à "$searchQuery"'
                              : 'Aucun étudiant inscrit dans cette classe',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final firstName = member['firstName'] as String? ?? '';
                    final lastName = member['lastName'] as String? ?? '';
                    final email = member['email'] as String? ?? '';
                    final initials =
                        (firstName.isNotEmpty ? firstName[0] : '') +
                        (lastName.isNotEmpty ? lastName[0] : '');

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.2,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              initials.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$firstName $lastName'.trim().isEmpty
                                      ? 'Étudiant'
                                      : '$firstName $lastName'.trim(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (email.isNotEmpty)
                                  Text(
                                    email,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (canManage)
                            IconButton(
                              icon: const Icon(
                                Icons.person_remove_outlined,
                                size: 20,
                              ),
                              color: colorScheme.error,
                              tooltip: 'Retirer de la classe',
                              onPressed: () => onRemoveStudent(member),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}


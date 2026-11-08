part of '../pages/groups_page.dart';
extension on _GroupsPageState {
  Widget _buildSliverContent(
    BuildContext context, {
    required dynamic user,
    required bool isTeacherOrAdmin,
    required bool isStudent,
    required bool isAdmin,
    required bool isDesktop,
  }) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return groupsAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: SmartLoader.medium(message: 'Chargement des groupes...'),
        ),
      ),
      error: (error, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Impossible de charger vos groupes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString().replaceFirst('ApiException: ', ''),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(myGroupsProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(context, ref, isTeacherOrAdmin),
          );
        }

        // Apply filters
        final filtered = groups.where((group) {
          final name = (group['name'] as String? ?? '').toLowerCase();
          final level = (group['level'] as String? ?? group['academicYear'] as String? ?? '').toLowerCase();
          final myRole = (group['myRole'] as String? ?? '').toUpperCase();
          final subjects = ((group['mySubjects'] as List?) ?? [])
              .whereType<String>()
              .map((s) => s.toLowerCase())
              .toList();

          // Role filter check
          if (_roleFilter == 'TEACHER') {
            if (myRole != 'TEACHER' && myRole != 'REFERENT') return false;
          } else if (_roleFilter == 'STUDENT') {
            if (myRole == 'TEACHER' || myRole == 'REFERENT') return false;
          }

          // Search query check
          if (_searchQuery.isNotEmpty) {
            final matchName = name.contains(_searchQuery);
            final matchLevel = level.contains(_searchQuery);
            final matchSubject = subjects.any((s) => s.contains(_searchQuery));
            if (!matchName && !matchLevel && !matchSubject) return false;
          }

          return true;
        }).toList();

        if (filtered.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search_off_rounded,
                        size: 32,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun groupe trouvé',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aucune classe ne correspond à vos filtres actuels.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        updateState(() {
                          _searchController.clear();
                          _roleFilter = 'ALL';
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Réinitialiser la recherche'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: 12,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final group = filtered[index];
                final groupId = (group['id'] as String?) ?? '';
                final groupName = (group['name'] as String?) ?? '';
                final level = (group['level'] as String?) ??
                    (group['academicYear'] as String?);
                final memberCount =
                    (group['memberCount'] as num?)?.toInt() ?? 0;
                final myRole = group['myRole'] as String?;
                final roleLabel = myRole == 'TEACHER' || myRole == 'REFERENT'
                    ? 'Enseignant'
                    : 'Étudiant';
                final canInvite = myRole == 'TEACHER' ||
                    myRole == 'REFERENT' ||
                    isAdmin;
                final canLeave = myRole == 'STUDENT' || isStudent;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppGroupCard(
                    name: groupName,
                    level: level,
                    memberCount: memberCount,
                    role: roleLabel,
                    subjects: (group['mySubjects'] as List?)
                        ?.whereType<String>()
                        .toList(),
                    mySubject: ((group['mySubjects'] as List?) ?? const [])
                        .whereType<String>()
                        .firstOrNull,
                    onTap: () =>
                        context.push('/groups/$groupId', extra: groupName),
                    onInvite: canInvite
                        ? () => ClassInvitationSheet.show(
                              context,
                              classGroupId: groupId,
                              className: groupName,
                            )
                        : null,
                    onLeave: canLeave
                        ? () => _confirmLeaveGroup(
                              context,
                              ref,
                              groupId,
                              groupName,
                            )
                        : null,
                  ),
                );
              },
              childCount: filtered.length,
            ),
          ),
        );
      },
    );
  }

}

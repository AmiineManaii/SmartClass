import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../../home/application/providers/student_dashboard_provider.dart';
import '../widgets/class_invitation_sheet.dart';

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'ALL'; // 'ALL', 'TEACHER', 'STUDENT'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text.trim().toLowerCase();
      if (text != _searchQuery) {
        setState(() => _searchQuery = text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final role = user?.role?.toLowerCase() ?? 'student';
    final isTeacher = role == 'teacher';
    final isAdmin = role == 'admin';
    final isStudent = role == 'student';
    final isTeacherOrAdmin = isTeacher || isAdmin;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.screenWidth >= 1024;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myGroupsProvider);
            ref.invalidate(studentClassMembershipProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Hero Header Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 32 : 16,
                    16,
                    isDesktop ? 32 : 16,
                    12,
                  ),
                  child: _buildHeroBanner(
                    context,
                    isTeacher: isTeacher,
                    isAdmin: isAdmin,
                    isTeacherOrAdmin: isTeacherOrAdmin,
                  ),
                ),
              ),

              // 2. Search & Filter Controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                    vertical: 6,
                  ),
                  child: _buildSearchAndFilters(
                    context,
                    isTeacherOrAdmin: isTeacherOrAdmin,
                  ),
                ),
              ),

              // 3. Groups List / States
              _buildSliverContent(
                context,
                user: user,
                isTeacherOrAdmin: isTeacherOrAdmin,
                isStudent: isStudent,
                isAdmin: isAdmin,
                isDesktop: isDesktop,
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(
    BuildContext context, {
    required bool isTeacher,
    required bool isAdmin,
    required bool isTeacherOrAdmin,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF122675), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF122675).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4ADE80),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isTeacherOrAdmin
                                      ? 'GESTION DES PROMOTIONS & CLASSES'
                                      : 'ESPACE ÉTUDIANT & GROUPES',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isTeacher
                                ? context.tr('nav_my_classes')
                                : (isAdmin ? 'Classes & Promotions' : context.tr('my_groups')),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isTeacherOrAdmin
                      ? 'Gérez vos espaces de cours, animez vos promotions, partagez vos supports et invitez vos étudiants par code sécurisé.'
                      : 'Accédez à vos classes universitaires, retrouvez vos cours, vos camarades et participez aux projets communs.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (isTeacherOrAdmin)
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _showCreateGroupDialog(context, ref),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    color: Color(0xFF122675), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Nouvelle classe',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF122675),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Material(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _showJoinGroupDialog(context, ref),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.vpn_key_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Rejoindre avec code',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
              hintText: 'Rechercher une classe, matière ou niveau...',
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
        setState(() {
          _roleFilter = value;
        });
      },
    );
  }

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
                        setState(() {
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

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    bool isTeacherOrAdmin,
  ) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF122675).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 48,
                color: Color(0xFF122675),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('no_groups'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isTeacherOrAdmin
                  ? 'Créez votre première classe virtuelle ou partagez un code d\'invitation pour rassembler vos étudiants.'
                  : 'Rejoignez votre classe grâce au code fourni par votre enseignant pour accéder aux ressources de cours.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                if (isTeacherOrAdmin)
                  AppButton(
                    text: context.tr('create_group'),
                    onPressed: () => _showCreateGroupDialog(context, ref),
                    isFullWidth: false,
                  ),
                AppButton(
                  text: context.tr('join_group'),
                  onPressed: () => _showJoinGroupDialog(context, ref),
                  variant: isTeacherOrAdmin
                      ? AppButtonVariant.outlined
                      : AppButtonVariant.primary,
                  isFullWidth: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateGroupSheet(ref: ref),
    );
  }

  void _showJoinGroupDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(context.tr('join_group')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Entrez le code d\'invitation fourni par votre enseignant :',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Code d\'invitation',
                  hintText: 'ex: SC-AB12CD',
                  prefixIcon: const Icon(Icons.vpn_key_rounded),
                  errorText: errorMessage,
                ),
                textCapitalization: TextCapitalization.characters,
                autofocus: true,
                enabled: !isLoading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final code = controller.text.trim();
                      if (code.isEmpty) {
                        setState(() => errorMessage = 'Veuillez saisir un code');
                        return;
                      }
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      try {
                        await ref
                            .read(groupsRemoteDataSourceProvider)
                            .joinClass(code);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        ref.invalidate(myGroupsProvider);
                        ref.invalidate(studentClassMembershipProvider);
                        if (context.mounted) {
                          context.showSuccessToast(context.tr('join_group_success'));
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                          errorMessage =
                              e.toString().replaceFirst('ApiException: ', '');
                        });
                      }
                    },
              child: isLoading
                  ? const SmartLoader.small(
                      color: Colors.white,
                      customSize: 18,
                    )
                  : Text(context.tr('join_group')),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeaveGroup(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    String groupName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Quitter la classe'),
        content: Text(
          'Voulez-vous vraiment quitter la classe "$groupName" ? Vous perdrez l\'accès aux ressources associées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(groupsRemoteDataSourceProvider)
                    .leaveClass(groupId);
                ref.invalidate(myGroupsProvider);
                ref.invalidate(studentClassMembershipProvider);
                if (context.mounted) {
                  context.showInfoToast('Vous avez quitté la classe.');
                }
              } catch (e) {
                if (context.mounted) {
                  context.showErrorToast(
                    e.toString().replaceFirst('ApiException: ', ''),
                  );
                }
              }
            },
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}

class _CreateGroupSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _CreateGroupSheet({required this.ref});

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      final capacity = int.tryParse(_capacityController.text.trim());
      final description = _descriptionController.text.trim();

      await widget.ref.read(groupsRemoteDataSourceProvider).createVirtualClassroom(
            name: name,
            capacity: capacity,
            description: description.isEmpty ? null : description,
          );

      if (mounted) {
        Navigator.pop(context);
        widget.ref.invalidate(myGroupsProvider);
        context.showSuccessToast('Classe virtuelle créée avec succès !');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Créer une classe virtuelle',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la classe *',
                    hintText: 'ex: Algorithmique Avancée - TD 1',
                    prefixIcon: Icon(Icons.class_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _capacityController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Capacité maximale (optionnel)',
                    hintText: 'ex: 40',
                    prefixIcon: Icon(Icons.people_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isLoading,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    hintText: 'Notes pour les étudiants...',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: context.tr('cancel'),
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        variant: AppButtonVariant.outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: _isLoading ? 'Création...' : 'Créer',
                        onPressed: _isLoading ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
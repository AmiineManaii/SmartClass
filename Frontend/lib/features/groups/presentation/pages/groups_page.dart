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

class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final role = user?.role?.toLowerCase() ?? 'student';
    final isTeacher = role == 'teacher';
    final isAdmin = role == 'admin';
    final isStudent = role == 'student';
    final isTeacherOrAdmin = isTeacher || isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTeacher ? context.tr('nav_my_classes') : context.tr('my_groups')),
        actions: [
          if (isTeacherOrAdmin)
            IconButton(
              icon: const Icon(Icons.group_add_rounded),
              onPressed: () => _showCreateGroupDialog(context, ref),
              tooltip: context.tr('create_group'),
            ),
          IconButton(
            icon: const Icon(Icons.login_rounded),
            onPressed: () => _showJoinGroupDialog(context, ref),
            tooltip: context.tr('join_group'),
          ),
        ],
      ),
      body: _buildBody(context, ref, user, isTeacherOrAdmin, isStudent, isAdmin),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    bool isTeacherOrAdmin,
    bool isStudent,
    bool isAdmin,
  ) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myGroupsProvider);
        ref.invalidate(studentClassMembershipProvider);
      },
      child: groupsAsync.when(
        loading: () => const Center(
          child: SmartLoader.medium(message: 'Chargement des groupes...'),
        ),
        error: (error, _) => Center(
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
        data: (groups) {
          if (groups.isEmpty) {
            return _buildEmptyState(context, ref, isTeacherOrAdmin);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = groups[index];
              final groupId = (group['id'] as String?) ?? '';
              final groupName = (group['name'] as String?) ?? '';
              final level = (group['level'] as String?) ??
                  (group['academicYear'] as String?);
              final memberCount = (group['memberCount'] as num?)?.toInt() ?? 0;
              final myRole = group['myRole'] as String?;
              final roleLabel = myRole == 'TEACHER' || myRole == 'REFERENT'
                  ? 'Enseignant'
                  : 'Étudiant';
              final canInvite = myRole == 'TEACHER' ||
                  myRole == 'REFERENT' ||
                  isAdmin;
              final canLeave = myRole == 'STUDENT' || isStudent;

              return AppGroupCard(
                name: groupName,
                level: level,
                memberCount: memberCount,
                role: roleLabel,
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
              );
            },
          );
        },
      ),
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
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.groups_outlined,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('no_groups'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isTeacherOrAdmin
                  ? 'Créez votre première classe virtuelle ou partagez un code d\'invitation'
                  : 'Rejoignez votre classe grâce au code fourni par votre enseignant',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isTeacherOrAdmin) ...[
                  AppButton(
                    text: context.tr('create_group'),
                    onPressed: () => _showCreateGroupDialog(context, ref),
                    isFullWidth: false,
                  ),
                  const SizedBox(width: 12),
                ],
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../app/app_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    final authState = ref.read(authStateProvider).value;
    _firstNameController.text = authState?.displayName?.split(' ').first ?? '';
    _lastNameController.text = authState?.displayName?.split(' ').skip(1).join(' ') ?? '';
    _emailController.text = authState?.email ?? '';
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('my_profile')),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _isEditing = true),
            )
          else ...[
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: Text(context.tr('cancel')),
            ),
            TextButton(
              onPressed: _saveProfile,
              child: Text(context.tr('save')),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(context, user),
            const SizedBox(height: 24),
            _buildProfileForm(context),
            const SizedBox(height: 24),
            _buildAccountSection(context),
            const SizedBox(height: 24),
            _buildDangerZone(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader(BuildContext context, AuthState? user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  user?.displayName?.isNotEmpty == true
                      ? user!.displayName![0].toUpperCase()
                      : 'U',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_isEditing)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'Utilisateur',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(user?.role ?? 'student').withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              _getRoleDisplayName(user?.role ?? 'student'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: _getRoleColor(user?.role ?? 'student'),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 8),
            Text(
              user!.email!,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getRoleColor(String role) {
    switch (role) {
      case 'teacher':
        return Colors.blue;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }
  
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'teacher':
        return 'Enseignant';
      case 'admin':
        return 'Administrateur';
      default:
        return 'Étudiant';
    }
  }
  
  Widget _buildProfileForm(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations personnelles',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: context.tr('first_name'),
                    ),
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('required_field');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: context.tr('last_name'),
                    ),
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('required_field');
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: context.tr('email'),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr('required_field');
                }
                if (!value.isValidEmail) {
                  return context.tr('invalid_email');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: context.tr('phone'),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: context.tr('bio'),
                hintText: 'Parlez un peu de vous...',
                alignLabelWithHint: true,
              ),
              enabled: _isEditing,
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccountSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('account_settings'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.lock_rounded, color: colorScheme.onPrimaryContainer, size: 22),
            ),
            title: Text(context.tr('change_password')),
            subtitle: Text('Modifier votre mot de passe'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _showChangePasswordDialog,
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.security_rounded, color: colorScheme.onTertiaryContainer, size: 22),
            ),
            title: Text('Authentification à deux facteurs'),
            subtitle: Text('Ajouter une couche de sécurité'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.download_rounded, color: colorScheme.onSecondaryContainer, size: 22),
            ),
            title: Text(context.tr('export_data')),
            subtitle: Text('Télécharger vos données'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
        ],
      ),
    );
  }
  
  Widget _buildDangerZone(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zone de danger',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_forever_rounded, color: colorScheme.onErrorContainer, size: 22),
            ),
            title: Text(
              context.tr('delete_account'),
              style: TextStyle(color: colorScheme.error),
            ),
            subtitle: Text('Supprimer définitivement votre compte et toutes vos données'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    // PATCH /auth/profile supports firstName/lastName only — email is
    // immutable server-side and stays local until the users module lands.
    try {
      await ref.read(authStateProvider.notifier).updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          );
    } on Failure catch (failure) {
      if (!mounted) return;
      final l10n = failureL10n(failure);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(l10n.key, args: l10n.args))),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('profile_updated'))),
    );
  }
  
  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.tr('change_password')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  decoration: InputDecoration(
                    labelText: context.tr('current_password'),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                  obscureText: obscureCurrent,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newController,
                  decoration: InputDecoration(
                    labelText: context.tr('new_password'),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                  ),
                  obscureText: obscureNew,
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return context.tr('password_too_short');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmController,
                  decoration: InputDecoration(
                    labelText: context.tr('confirm_password'),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  obscureText: obscureConfirm,
                  validator: (value) {
                    if (value != newController.text) {
                      return context.tr('passwords_dont_match');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('password_changed'))),
                );
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_account')),
        content: Text(context.tr('delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).logout();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('logged_out'))),
              );
            },
            child: Text(context.tr('delete_account')),
          ),
        ],
      ),
    );
  }
}
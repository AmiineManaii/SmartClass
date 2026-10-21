import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../views/web_role_selection_view.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/role_option_card.dart';
import '../widgets/trust_banner.dart';

class RoleSelectionPage extends ConsumerStatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  late String _selectedRole;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final role = ref.read(authStateProvider).valueOrNull?.role;
    // ADMIN is never self-assignable (backend 403, seeded/provisioned only):
    // only student/teacher can be picked here. An existing ADMIN skips
    // this screen via the router guard (onboardingCompleted).
    _selectedRole = (role == 'teacher') ? 'teacher' : 'student';
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(authStateProvider.notifier).updateRole(_selectedRole);
    } on Failure catch (failure) {
      if (!mounted) return;
      final l10n = failureL10n(failure);
      context.showErrorToast(context.tr(l10n.key, args: l10n.args));
      setState(() => _saving = false);
      return;
    }
    if (mounted) context.go('/profile-setup');
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return const WebRoleSelectionView();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AuthScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTopBar(step: 2, onBack: () => context.pop()),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.secondaryFixed.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: colorScheme.onSecondaryFixed),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    context.tr('step_2_profile').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryFixed,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.06,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(context.tr('who_are_you'), style: theme.textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            context.tr('role_intro'),
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          RoleOptionCard(
            icon: Icons.school,
            title: context.tr('role_student'),
            description: context.tr('role_student_desc'),
            showRecommended: true,
            recommendedLabel: context.tr('recommended'),
            selected: _selectedRole == 'student',
            onTap: _saving ? null : () => setState(() => _selectedRole = 'student'),
            tags: [
              RoleTag(icon: Icons.menu_book_outlined, label: context.tr('tag_homework')),
              RoleTag(icon: Icons.psychology_outlined, label: context.tr('tag_ai_tutor')),
            ],
          ),
          const SizedBox(height: 16),
          RoleOptionCard(
            icon: Icons.co_present_outlined,
            title: context.tr('role_teacher'),
            description: context.tr('role_teacher_desc'),
            selected: _selectedRole == 'teacher',
            onTap: _saving ? null : () => setState(() => _selectedRole = 'teacher'),
            tags: [
              RoleTag(icon: Icons.assignment_turned_in_outlined, label: context.tr('tag_corrections')),
              RoleTag(icon: Icons.groups_outlined, label: context.tr('tag_classes')),
            ],
          ),
          const SizedBox(height: 24),
          TrustBanner(icon: Icons.verified_user_outlined, text: context.tr('trust_rgpd')),
          const SizedBox(height: 24),
          AppButton(
            text: context.tr('continue_action'),
            trailingIcon: Icons.arrow_forward,
            isLoading: _saving,
            onPressed: _saving ? null : _confirm,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('change_role_later'),
            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

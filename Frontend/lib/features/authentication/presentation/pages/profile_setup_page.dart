import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/providers/auth_options_provider.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/field_label.dart';
import '../widgets/interest_chip.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  String? _institution = 'Université Paris-Saclay';
  String? _level = 'Master 1 - Informatique & Data Science';
  final Set<String> _selectedInterests = {'maths', 'info', 'physics', 'ai'};

  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required String? current,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: options.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option == current;
              return ListTile(
                title: Text(option, style: theme.textTheme.bodyMedium),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(option),
              );
            },
          ),
        );
      },
    );
    if (selected != null) {
      onSelected(selected);
    }
  }

  Future<void> _validate() async {
    if ((_institution ?? '').isEmpty || (_level ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('required_field'))),
      );
      return;
    }
    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('interests_hint'))),
      );
      return;
    }
    // PATCH /auth/profile { onboardingCompleted: true } — the notifier
    // falls back to a local validation when offline.
    try {
      await ref.read(authStateProvider.notifier).completeProfile();
    } on Failure catch (failure) {
      if (!mounted) return;
      final l10n = failureL10n(failure);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(l10n.key, args: l10n.args))),
      );
      return;
    }
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final institutions = ref.watch(authInstitutionsProvider);
    final levels = ref.watch(authStudyLevelsProvider);
    final interests = ref.watch(authInterestsProvider);
    final labels = ref.watch(authInterestLabelsProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return AuthScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTopBar(step: 3, onBack: () => context.pop()),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✨', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    context.tr('step_3_final').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primaryContainer,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.06,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(context.tr('profile_setup_title'), style: theme.textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            context.tr('profile_setup_subtitle'),
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest ?? colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, size: 52, color: colorScheme.outline),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.15),
                              offset: const Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(Icons.photo_camera, size: 17, color: colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('avatar_optional'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const FieldLabel(labelKey: 'institution_label', trailingKey: 'required_badge', showTrailing: true),
          const SizedBox(height: 6),
          _PickerRow(
            icon: Icons.account_balance_outlined,
            value: _institution ?? '',
            onTap: () => _pickOption(
              title: context.tr('institution_label'),
              options: institutions,
              current: _institution,
              onSelected: (v) => setState(() => _institution = v),
            ),
          ),
          const SizedBox(height: 16),
          const FieldLabel(labelKey: 'level_label', trailingKey: 'required_badge', showTrailing: true),
          const SizedBox(height: 6),
          _PickerRow(
            icon: Icons.psychology_outlined,
            value: _level ?? '',
            onTap: () => _pickOption(
              title: context.tr('level_label'),
              options: levels,
              current: _level,
              onSelected: (v) => setState(() => _level = v),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_outlined, size: 18, color: colorScheme.primaryContainer),
                  const SizedBox(width: 6),
                  Text(context.tr('interests_label'), style: theme.textTheme.labelLarge),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryFixed,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  context.tr('selected_count', args: {'count': '${_selectedInterests.length}'}),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onTertiaryFixed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('interests_hint'),
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...interests.map((interest) {
                final label = labels[interest.labelKey]?[locale] ??
                    labels[interest.labelKey]?['fr'] ??
                    interest.id;
                return InterestChip(
                  emoji: interest.emoji,
                  label: label,
                  selected: _selectedInterests.contains(interest.id),
                  onTap: () => setState(() {
                    if (_selectedInterests.contains(interest.id)) {
                      _selectedInterests.remove(interest.id);
                    } else {
                      _selectedInterests.add(interest.id);
                    }
                  }),
                );
              }),
              InterestChip(
                emoji: '+',
                label: context.tr('other_interest'),
                selected: false,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppButton(
            text: context.tr('validate_profile'),
            trailingIcon: Icons.arrow_forward,
            onPressed: _validate,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, size: 16, color: colorScheme.outline),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.tr('profile_edit_later'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  const _PickerRow({required this.icon, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLowest ?? colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                offset: const Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.expand_more, size: 20, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

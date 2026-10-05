import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/field_label.dart';
import '../widgets/password_strength_bar.dart';
import '../widgets/social_auth_buttons.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('required_field'))),
        );
      }
      return;
    }

    await ref.read(authStateProvider.notifier).register(
          _emailController.text.trim(),
          _passwordController.text,
          'student',
        );

    if (mounted) {
      context.go('/role-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    return AuthScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTopBar(
            trailing: Icon(Icons.school_outlined, color: colorScheme.outlineVariant),
          ),
          const SizedBox(height: 8),
          Text(context.tr('create_account'), style: theme.textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            context.tr('welcome_subtitle'),
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FieldLabel(labelKey: 'full_name_label', trailingKey: 'required_badge', showTrailing: true),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _nameController,
                  hint: context.tr('full_name_hint'),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.tr('required_field');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const FieldLabel(
                  labelKey: 'email_label',
                  trailingKey: 'academic_format_hint',
                  showTrailing: true,
                ),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _emailController,
                  hint: context.tr('email_hint'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.mail_outline),
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
                FieldLabel(labelKey: 'password'),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _passwordController,
                  hint: context.tr('password_hint'),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('required_field');
                    }
                    if (value.length < 8) {
                      return context.tr('password_too_short');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                PasswordStrengthBar(password: _passwordController.text),
                const SizedBox(height: 16),
                FieldLabel(labelKey: 'confirm_password'),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _confirmController,
                  hint: context.tr('password_hint'),
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleRegister(),
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('required_field');
                    }
                    if (value != _passwordController.text) {
                      return context.tr('passwords_dont_match');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _acceptTerms,
                        onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          children: [
                            TextSpan(text: '${context.tr('accept_terms_prefix')} '),
                            TextSpan(
                              text: context.tr('terms_of_service'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primaryContainer,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: ' ${context.tr('and')} '),
                            TextSpan(
                              text: context.tr('privacy_policy'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primaryContainer,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: context.tr('signup_button'),
                  trailingIcon: Icons.arrow_forward,
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _handleRegister,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AuthDivider(labelKey: 'or_signup_with'),
          const SizedBox(height: 16),
          SocialAuthRow(onGoogle: () {}, onMicrosoft: () {}),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.tr('already_have_account'),
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              TextButton(
                onPressed: () => context.push('/login'),
                child: Text(
                  context.tr('sign_in'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
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

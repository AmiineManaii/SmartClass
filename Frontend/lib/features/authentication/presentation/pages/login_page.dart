import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/field_label.dart';
import '../widgets/social_auth_buttons.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showFailure(Failure failure) {
    final l10n = failureL10n(failure);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(l10n.key, args: l10n.args))),
    );
  }

  /// No OAuth endpoint exists yet (`contracts/README.md` → planned).
  void _showOAuthUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('feature_coming_soon'))),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authStateProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } on Failure catch (failure) {
      if (!mounted) return;
      if (failure.code == 'AUTH_EMAIL_NOT_VERIFIED') {
        _showFailure(failure);
        context.go('/verify-email');
        return;
      }
      _showFailure(failure);
      return;
    }

    if (!mounted) return;
    final result = ref.read(authStateProvider).value;
    if (result == null || !result.isAuthenticated) return;
    if (!result.emailVerified) {
      context.go('/verify-email');
    } else if (!result.onboardingCompleted) {
      context.go('/role-selection');
    } else {
      context.go('/home');
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
          const SizedBox(height: 12),
          const AuthBrandHeader(
            titleKey: 'welcome_title',
            subtitleKey: 'welcome_subtitle',
          ),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FieldLabel(labelKey: 'email_label'),
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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(context.tr('password'), style: theme.textTheme.labelMedium),
                    TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        context.tr('forgot_password'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _passwordController,
                  hint: context.tr('password_hint'),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
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
                const SizedBox(height: 24),
                AppButton(
                  text: context.tr('login_button'),
                  trailingIcon: Icons.arrow_forward,
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _handleLogin,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AuthDivider(labelKey: 'or_continue_with'),
          const SizedBox(height: 16),
          SocialAuthRow(
            onGoogle: _showOAuthUnavailable,
            onMicrosoft: _showOAuthUnavailable,
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.tr('dont_have_account'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/register'),
                child: Text(
                  context.tr('sign_up'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
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

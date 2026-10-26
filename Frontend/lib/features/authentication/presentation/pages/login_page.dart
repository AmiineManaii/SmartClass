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
import '../views/web_login_view.dart';
import '../../../../core/network/network_providers.dart';

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
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final tokens = ref.read(tokenStorageProvider);
    final savedEmail = await tokens.getSavedEmail();
    final isRemember = await tokens.isRememberMe();
    if (mounted) {
      setState(() {
        _rememberMe = isRemember;
        if (isRemember && savedEmail != null && savedEmail.isNotEmpty) {
          _emailController.text = savedEmail;
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showFailure(Failure failure) {
    final l10n = failureL10n(failure);
    context.showErrorToast(context.tr(l10n.key, args: l10n.args));
  }

  /// No OAuth endpoint exists yet (`contracts/README.md` → planned).
  void _showOAuthUnavailable() {
    context.showInfoToast(context.tr('feature_coming_soon'));
  }

  Future<void> _show2faChallengeModal(String tempToken) async {
    final codeController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.shield_rounded, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('two_factor_auth_label'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Entrez le code à 6 chiffres de votre application Authenticator ou un code de secours.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.text,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ),
                    decoration: InputDecoration(
                      hintText: '123456',
                      counterText: '',
                      errorText: errorMessage,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: Text(context.tr('cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final code = codeController.text.trim();
                        if (code.isEmpty) return;
                        setDlgState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        try {
                          await ref.read(authStateProvider.notifier).authenticate2fa(
                                tempToken: tempToken,
                                code: code,
                                rememberMe: _rememberMe,
                              );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        } on Failure catch (f) {
                          setDlgState(() {
                            isSubmitting = false;
                            final l10n = failureL10n(f);
                            errorMessage = context.tr(l10n.key, args: l10n.args);
                          });
                        } catch (e) {
                          setDlgState(() {
                            isSubmitting = false;
                            errorMessage = e.toString();
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(context.tr('two_factor_verify_btn')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authStateProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
            rememberMe: _rememberMe,
          );
    } on TwoFactorRequiredFailure catch (twoFactorFailure) {
      if (!mounted) return;
      await _show2faChallengeModal(twoFactorFailure.tempToken);
    } on Failure catch (failure) {
      if (!mounted) return;
      if (failure.code == 'AUTH_EMAIL_NOT_VERIFIED') {
        final email = _emailController.text.trim();
        try {
          await ref.read(authStateProvider.notifier).resendVerification(email: email);
        } catch (_) {}
        if (!mounted) return;
        context.showSuccessToast(context.tr('verification_sent'));
        context.go('/verify-email?email=${Uri.encodeComponent(email)}');
        return;
      }
      _showFailure(failure);
      return;
    }

    if (!mounted) return;
    final result = ref.read(authStateProvider).valueOrNull;
    if (result == null || !result.isAuthenticated) return;
    if (!result.emailVerified) {
      final email = result.email ?? _emailController.text.trim();
      context.go('/verify-email?email=${Uri.encodeComponent(email)}');
    } else if (!result.onboardingCompleted) {
      context.go('/role-selection');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return const WebLoginPage();
    }

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
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (v) => setState(
                              () => _rememberMe = v ?? false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            context.tr('remember_me_30_days'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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

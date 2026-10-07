import 'dart:async';

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
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/otp_boxes.dart';
import '../widgets/trust_banner.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController(text: 'thomas.laurent@universite.fr');
  final _formKey = GlobalKey<FormState>();
  String _otp = '482';
  int _secondsLeft = 42;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 42);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  String get _maskedEmail {
    final email = _emailController.text.trim();
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].length < 3) return email;
    return '${parts[0].substring(0, 6)}***@${parts[1]}';
  }

  String get _formattedTimer {
    final seconds = _secondsLeft.clamp(0, 5999).toString().padLeft(2, '0');
    return '00:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AuthScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTopBar(
            trailing: Icon(Icons.help_outline, color: colorScheme.outline),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryFixed,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_reset, size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    context.tr('security_recovery').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryFixed,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.06,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(context.tr('forgot_title'), style: theme.textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            context.tr('forgot_subtitle'),
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _StepCard(
            step: '1',
            stepActive: false,
            title: context.tr('institutional_email'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 15, color: colorScheme.tertiary),
                const SizedBox(width: 4),
                Text(
                  context.tr('verified'),
                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.tertiary),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Form(
                  key: _formKey,
                  child: AppTextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.mail_outline),
                    suffixIcon: Icon(Icons.verified, color: colorScheme.tertiary),
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
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: context.tr('resend_email'),
                  trailingIcon: Icons.send_outlined,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    try {
                      await ref.read(authStateProvider.notifier).forgotPassword(
                            email: _emailController.text.trim(),
                          );
                    } on Failure catch (failure) {
                      if (!context.mounted) return;
                      final l10n = failureL10n(failure);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(context.tr(l10n.key, args: l10n.args))),
                      );
                      return;
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('reset_email_sent'))),
                    );
                    _startCountdown();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _StepCard(
            step: '2',
            stepActive: true,
            title: context.tr('otp_title'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.secondaryFixed,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                context.tr('pending_badge'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryFixed,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      TextSpan(text: '${context.tr('otp_hint')} '),
                      TextSpan(
                        text: _maskedEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OtpBoxes(
                  initialValue: const ['4', '8', '2', ''],
                  onChanged: (value) => _otp = value,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.update, size: 16, color: colorScheme.secondary),
                        const SizedBox(width: 6),
                        Text(
                          '${context.tr('expires_in')} ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(_formattedTimer, style: theme.textTheme.bodySmall),
                      ],
                    ),
                    TextButton(
                      onPressed: _secondsLeft <= 0
                          ? () async {
                              if (!_formKey.currentState!.validate()) return;
                              try {
                                await ref
                                    .read(authStateProvider.notifier)
                                    .forgotPassword(
                                      email: _emailController.text.trim(),
                                    );
                              } on Failure catch (failure) {
                                if (!context.mounted) return;
                                final l10n = failureL10n(failure);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          context.tr(l10n.key, args: l10n.args))),
                                );
                                return;
                              }
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(context.tr('reset_email_sent'))),
                              );
                              _startCountdown();
                            }
                          : null,
                      child: Text(context.tr('resend_code')),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppButton(
                  text: context.tr('verify_code'),
                  trailingIcon: Icons.arrow_forward,
                  onPressed: () {
                    if (_otp.trim().length < 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.tr('required_field'))),
                      );
                      return;
                    }
                    // The code itself is verified by POST /auth/reset-password.
                    context.go(
                      '/reset-password',
                      extra: {
                        'email': _emailController.text.trim(),
                        'code': _otp.trim(),
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TrustBanner(
            icon: Icons.verified_user_outlined,
            text:
                '${context.tr('security_guaranteed_title')}\n${context.tr('security_guaranteed_desc')}',
            iconBackground: colorScheme.surfaceContainerHighest,
            iconColor: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.keyboard_backspace, size: 18),
              label: Text(context.tr('back_to_login')),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final bool stepActive;
  final String title;
  final Widget? trailing;
  final Widget child;

  const _StepCard({
    required this.step,
    required this.stepActive,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: stepActive ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: stepActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: theme.textTheme.labelLarge),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/password_rule_checklist.dart';
import '../widgets/password_security_meter.dart';

enum _ResetState { idle, updating, success }

/// New-password screen (forgot-password flow: forgot → reset → login).
/// Live strength meter + rule checklist, 3-state CTA.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureNew = true;
  _ResetState _state = _ResetState.idle;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  static int scoreOf(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[A-ZÀ-Þ]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }

  static List<bool> rulesOf(String password) => [
        password.length >= 8,
        RegExp(r'[0-9]').hasMatch(password),
        RegExp(r'[A-ZÀ-Þ]').hasMatch(password),
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
      ];

  bool get _matches =>
      _newController.text.isNotEmpty &&
      _newController.text == _confirmController.text;

  Map<String, String> _resetContext() {
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, String>) return extra;
    if (extra is Map) {
      return extra.map((key, value) => MapEntry('$key', '$value'));
    }
    return const {};
  }

  Future<void> _submit() async {
    if (_state != _ResetState.idle) return;
    final password = _newController.text;
    if (scoreOf(password) < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('required_field'))),
      );
      return;
    }
    if (!_matches) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('passwords_dont_match'))),
      );
      return;
    }
    final reset = _resetContext();
    final email = reset['email'] ?? '';
    final code = reset['code'] ?? '';
    if (email.isEmpty || code.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('session_expired'))),
      );
      context.go('/forgot-password');
      return;
    }
    setState(() => _state = _ResetState.updating);
    try {
      await ref.read(authStateProvider.notifier).resetPassword(
            email: email,
            code: code,
            newPassword: password,
          );
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _state = _ResetState.idle);
      final l10n = failureL10n(failure);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(l10n.key, args: l10n.args))),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _state = _ResetState.success);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final password = _newController.text;
    final score = scoreOf(password);
    final rules = rulesOf(password);

    return AuthScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTopBar(
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('reset_password_header'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: colorScheme.onPrimary, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 96,
              height: 88,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryFixed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.04),
                          offset: const Offset(0, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 36,
                      color: colorScheme.primary,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest ?? colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.12),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.verified_user,
                        size: 18,
                        color: colorScheme.tertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('new_password_title'),
            style: theme.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              context.tr('new_password_subtitle'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
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
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('new_password_label'),
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      context.tr('required_badge'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _newController,
                  hint: context.tr('password_hint'),
                  obscureText: _obscureNew,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: const Icon(Icons.key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                const SizedBox(height: 12),
                PasswordSecurityMeter(score: score),
                const SizedBox(height: 12),
                PasswordRuleChecklist(met: rules),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('confirm_password'),
                      style: theme.textTheme.labelLarge,
                    ),
                    if (_matches)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 14, color: colorScheme.tertiaryContainer),
                          const SizedBox(width: 2),
                          Text(
                            context.tr('passwords_match'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.tertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _confirmController,
                  hint: context.tr('password_hint'),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: _matches
                      ? Icon(Icons.task_alt, size: 22, color: colorScheme.tertiaryContainer)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest ?? colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.tips_and_updates_outlined,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('academic_advice_title'),
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('academic_advice_desc'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_state == _ResetState.success)
            FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.tertiaryContainer,
                foregroundColor: colorScheme.onTertiaryContainer,
                disabledBackgroundColor: colorScheme.tertiaryContainer,
                disabledForegroundColor: colorScheme.onTertiaryContainer,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: theme.textTheme.labelLarge,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 20),
                  const SizedBox(width: 8),
                  Flexible(child: Text(context.tr('password_updated'))),
                ],
              ),
            )
          else
            AppButton(
              text: _state == _ResetState.updating
                  ? context.tr('updating')
                  : context.tr('reset_password'),
              trailingIcon: _state == _ResetState.updating ? null : Icons.arrow_forward,
              isLoading: _state == _ResetState.updating,
              onPressed: _state == _ResetState.idle ? _submit : null,
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 16, color: colorScheme.outline),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.tr('e2e_footer'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('need_help'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: colorScheme.secondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/otp_display_boxes.dart';

/// Email verification with 6-digit OTP + custom numeric keypad.
/// Step of the registration flow: register → verify-email → role-selection.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  static const int _codeLength = 6;
  static const int _initialSeconds = 45;

  final List<String> _digits = List.filled(_codeLength, '');
  int _secondsLeft = _initialSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _initialSeconds);
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

  int get _filledCount => _digits.where((d) => d.isNotEmpty).length;
  bool get _isComplete => _filledCount == _codeLength;
  bool get _isExpired => _secondsLeft <= 0;

  String get _formattedTimer {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onDigit(String digit) {
    final index = _digits.indexWhere((d) => d.isEmpty);
    if (index == -1) return;
    setState(() => _digits[index] = digit);
  }

  void _onBackspace() {
    for (var i = _digits.length - 1; i >= 0; i--) {
      if (_digits[i].isNotEmpty) {
        setState(() => _digits[i] = '');
        return;
      }
    }
  }

  void _showFailure(Failure failure) {
    final l10n = failureL10n(failure);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(l10n.key, args: l10n.args))),
    );
  }

  Future<void> _verify() async {
    if (!_isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('required_field'))),
      );
      return;
    }
    final email = ref.read(authStateProvider).value?.email ?? '';
    try {
      await ref.read(authStateProvider.notifier).verifyEmail(
            email: email,
            code: _digits.join(),
          );
    } on Failure catch (failure) {
      if (mounted) _showFailure(failure);
      return;
    }
    if (mounted) context.go('/role-selection');
  }

  Future<void> _resend() async {
    final email = ref.read(authStateProvider).value?.email ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('required_field'))),
      );
      return;
    }
    try {
      await ref.read(authStateProvider.notifier).resendVerification(email: email);
    } on Failure catch (failure) {
      if (mounted) _showFailure(failure);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('verification_sent'))),
    );
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final email = ref.watch(authStateProvider).value?.email;
    final displayEmail = (email == null || email.isEmpty) ? 'etudiant@smartclass.edu' : email;

    return AuthScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTopBar(
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: colorScheme.onPrimary, size: 18),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: _HeroBadge()),
          const SizedBox(height: 24),
          Text(
            context.tr('verify_email_title'),
            style: theme.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('verify_email_subtitle'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow ?? colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.04),
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alternate_email, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      displayEmail,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(9999),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
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
              children: [
                OtpDisplayBoxes(digits: _digits),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isComplete
                            ? colorScheme.tertiary
                            : colorScheme.tertiaryFixed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _isComplete
                            ? context.tr('otp_complete')
                            : context.tr('otp_waiting_digit',
                                args: {'n': '${_filledCount + 1}'}),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  context.tr('nothing_received'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: _resend,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('resend_code'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isExpired
                            ? colorScheme.tertiaryFixed
                            : colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        _isExpired ? context.tr('countdown_available') : _formattedTimer,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _isExpired
                              ? colorScheme.onTertiaryFixed
                              : colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: Icon(
                Icons.sms_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              label: Text(
                context.tr('receive_sms'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            text: context.tr('verify_continue'),
            trailingIcon: Icons.arrow_forward,
            isLoading: ref.watch(authStateProvider).isLoading,
            onPressed: _verify,
          ),
          const SizedBox(height: 24),
          NumericKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 16, color: colorScheme.tertiary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.tr('ssl_footer'),
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

class _HeroBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 120,
      height: 104,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.04),
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread,
                size: 36,
                color: colorScheme.primary,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 8,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.12),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(Icons.verified, size: 20, color: colorScheme.onPrimary),
            ),
          ),
          Positioned(
            top: 0,
            left: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.tertiaryFixed.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, size: 14, color: colorScheme.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/web_controls_bar.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../widgets/web_auth_hero_section.dart';

/// Desktop split-screen view for Password Recovery (Forgot Password).
/// Supports step 1 (Email sending) and step 2 (OTP code input + resend countdown).
class WebForgotPasswordView extends ConsumerStatefulWidget {
  const WebForgotPasswordView({super.key});

  @override
  ConsumerState<WebForgotPasswordView> createState() =>
      _WebForgotPasswordViewState();
}

class _WebForgotPasswordViewState extends ConsumerState<WebForgotPasswordView>
    with SingleTickerProviderStateMixin {
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  static const int _otpLength = 6;
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;

  int _secondsLeft = 45;
  Timer? _timer;
  bool _isSendingEmail = false;
  bool _emailSent = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(_otpLength, (_) => TextEditingController());
    _otpFocusNodes = List.generate(_otpLength, (_) => FocusNode());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 45);
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

  String get _otpCode => _otpControllers.map((c) => c.text).join();
  bool get _isOtpComplete => _otpCode.length == _otpLength;

  String get _formattedTimer {
    final s = _secondsLeft.clamp(0, 999).toString().padLeft(2, '0');
    return '00:$s';
  }

  void _showFailure(Failure failure) {
    final l10n = failureL10n(failure);
    final translated = context.tr(l10n.key, args: l10n.args);
    final message =
        (translated == l10n.key || translated.isEmpty) ? failure.message : translated;

    context.showErrorToast(message);
  }

  Future<void> _handleSendEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isSendingEmail = true);

    try {
      await ref.read(authStateProvider.notifier).forgotPassword(
            email: _emailController.text.trim(),
          );
      if (mounted) {
        setState(() => _emailSent = true);
        _startCountdown();
        context.showSuccessToast(context.tr('reset_email_sent'));
        // Focus first OTP field
        if (_otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
      }
    } on Failure catch (failure) {
      if (mounted) _showFailure(failure);
    } catch (_) {
      if (mounted) {
        context.showErrorToast(context.tr('error_unexpected'));
      }
    } finally {
      if (mounted) setState(() => _isSendingEmail = false);
    }
  }

  void _handleVerifyOtp() {
    if (!_isOtpComplete) {
      context.showWarningToast(context.tr('required_field'));
      return;
    }

    context.go(
      '/reset-password',
      extra: {
        'email': _emailController.text.trim(),
        'code': _otpCode,
      },
    );
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final clean = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _otpLength; i++) {
        if (i < clean.length) {
          _otpControllers[i].text = clean[i];
        }
      }
      setState(() {});
      final next = clean.length.clamp(0, _otpLength - 1);
      _otpFocusNodes[next].requestFocus();
      if (_isOtpComplete) _handleVerifyOtp();
      return;
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
        if (_isOtpComplete) _handleVerifyOtp();
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // Left side: Widescreen Hero Section
          Expanded(
            flex: 6,
            child: WebAuthHeroSection(isDark: isDark),
          ),

          // Right side: Dedicated Forgot Password Card
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // Top control bar
                const Positioned(
                  top: 24,
                  right: 28,
                  child: WebControlsBar(),
                ),

                // Main card container
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2438)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : const Color(0xFF122675).withValues(alpha: 0.08),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF122675).withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Badge & Back link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF2FF),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.lock_reset_rounded,
                                              size: 14,
                                              color: Color(0xFF4338CA),
                                            ),
                                            SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'RÉCUPÉRATION',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF4338CA),
                                                  letterSpacing: 0.4,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => context.go('/login'),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.arrow_back_rounded,
                                              size: 14,
                                              color: Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              context.tr('back_to_login'),
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Title & Subtitle
                                Text(
                                  context.tr('forgot_title'),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  context.tr('forgot_subtitle'),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    height: 1.4,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // STEP 1: Email Card
                                _buildStepCard(
                                  stepNumber: '1',
                                  title: context.tr('institutional_email'),
                                  badge: _emailSent
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                size: 12,
                                                color: Color(0xFF0F9D78),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                context.tr('verified').toUpperCase(),
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0F9D78),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : null,
                                  isDark: isDark,
                                  child: Form(
                                    key: _emailFormKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _handleSendEmail(),
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'etudiant@universite.fr',
                                            prefixIcon: const Icon(
                                              Icons.mail_outline_rounded,
                                              size: 19,
                                              color: Color(0xFF2D3E8C),
                                            ),
                                            suffixIcon: _emailSent
                                                ? const Icon(
                                                    Icons.check_circle_rounded,
                                                    color: Color(0xFF0F9D78),
                                                    size: 20,
                                                  )
                                                : null,
                                            filled: true,
                                            fillColor: isDark
                                                ? const Color(0xFF191F33)
                                                : const Color(0xFFF8FAFC),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: colorScheme.outlineVariant
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: colorScheme.outlineVariant
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF122675),
                                                width: 1.8,
                                              ),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 12),
                                          ),
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) {
                                              return context.tr('required_field');
                                            }
                                            if (!val.trim().isValidEmail) {
                                              return context.tr('invalid_email');
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 44,
                                          child: FilledButton.icon(
                                            onPressed: _isSendingEmail
                                                ? null
                                                : _handleSendEmail,
                                            icon: _isSendingEmail
                                                ? const SmartLoader.small(
                                                    color: Colors.white,
                                                    customSize: 16,
                                                  )
                                                : Icon(
                                                    _emailSent
                                                        ? Icons.replay_rounded
                                                        : Icons.send_rounded,
                                                    size: 16,
                                                  ),
                                            label: Text(
                                              _emailSent
                                                  ? context.tr('resend_email')
                                                  : 'Envoyer le code de réinitialisation',
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: const Color(0xFF122675),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // STEP 2: Code Verification Card
                                _buildStepCard(
                                  stepNumber: '2',
                                  title: context.tr('otp_title'),
                                  badge: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _emailSent
                                          ? const Color(0xFFEEF2FF)
                                          : (isDark
                                              ? Colors.white.withValues(alpha: 0.05)
                                              : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _emailSent ? 'ACTIF' : 'EN ATTENTE',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _emailSent
                                            ? const Color(0xFF4338CA)
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  isDark: isDark,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _emailSent
                                            ? 'Un code à 6 chiffres a été envoyé à ${_emailController.text.trim()}'
                                            : 'Envoyez d\'abord l\'email à l\'étape 1 pour déverrouiller cette étape.',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          height: 1.35,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // 6 OTP Boxes
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: List.generate(_otpLength, (i) {
                                          return SizedBox(
                                            width: 50,
                                            height: 56,
                                            child: KeyboardListener(
                                              focusNode: FocusNode(),
                                              onKeyEvent: (event) {
                                                if (event is KeyDownEvent &&
                                                    event.logicalKey ==
                                                        LogicalKeyboardKey.backspace &&
                                                    _otpControllers[i].text.isEmpty &&
                                                    i > 0) {
                                                  _otpFocusNodes[i - 1].requestFocus();
                                                  _otpControllers[i - 1].clear();
                                                  setState(() {});
                                                }
                                              },
                                              child: TextField(
                                                controller: _otpControllers[i],
                                                focusNode: _otpFocusNodes[i],
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                maxLength: 1,
                                                enabled: _emailSent,
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF122675),
                                                ),
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                ],
                                                decoration: InputDecoration(
                                                  counterText: '',
                                                  filled: true,
                                                  fillColor: _otpFocusNodes[i].hasFocus
                                                      ? const Color(0xFFEEF2FF)
                                                      : (_otpControllers[i]
                                                              .text
                                                              .isNotEmpty
                                                          ? const Color(0xFFF8FAFC)
                                                          : (isDark
                                                              ? const Color(0xFF191F33)
                                                              : Colors.white)),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                    borderSide: BorderSide(
                                                      color: colorScheme.outlineVariant
                                                          .withValues(alpha: 0.6),
                                                    ),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                    borderSide: BorderSide(
                                                      color: _otpControllers[i]
                                                              .text
                                                              .isNotEmpty
                                                          ? const Color(0xFF2D3E8C)
                                                          : colorScheme.outlineVariant
                                                              .withValues(alpha: 0.6),
                                                      width: _otpControllers[i]
                                                              .text
                                                              .isNotEmpty
                                                          ? 1.5
                                                          : 1.0,
                                                    ),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFF122675),
                                                      width: 2.0,
                                                    ),
                                                  ),
                                                ),
                                                onChanged: (val) =>
                                                    _onOtpDigitChanged(i, val),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 14),

                                      // Timer Row
                                      if (_emailSent) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.schedule_rounded,
                                                  size: 15,
                                                  color: Color(0xFF2D3E8C),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${context.tr('expires_in')} $_formattedTimer',
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF2D3E8C),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TextButton(
                                              onPressed: _secondsLeft <= 0
                                                  ? _handleSendEmail
                                                  : null,
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize
                                                    .shrinkWrap,
                                              ),
                                              child: Text(
                                                context.tr('resend_code'),
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: _secondsLeft <= 0
                                                      ? const Color(0xFF122675)
                                                      : colorScheme.onSurfaceVariant
                                                          .withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Submit Verify Code button
                                      SizedBox(
                                        height: 48,
                                        child: FilledButton(
                                          onPressed: (_emailSent && _isOtpComplete)
                                              ? _handleVerifyOtp
                                              : null,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFF122675),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                context.tr('verify_code'),
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 17,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Trust note
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_user_outlined,
                                        size: 18,
                                        color: Color(0xFF0F9D78),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '${context.tr('security_guaranteed_title')} • ${context.tr('security_guaranteed_desc')}',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            height: 1.3,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required Widget? badge,
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191F33) : const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF122675),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNumber,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

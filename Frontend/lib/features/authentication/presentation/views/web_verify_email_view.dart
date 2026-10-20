import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/web_controls_bar.dart';
import '../widgets/web_auth_hero_section.dart';

/// Desktop split-screen view for Email Verification with OTP.
/// Includes auto-advancing keyboard input, paste support (Ctrl+V),
/// animated countdown timer, and smooth micro-interactions.
class WebVerifyEmailView extends ConsumerStatefulWidget {
  final String? email;

  const WebVerifyEmailView({super.key, this.email});

  @override
  ConsumerState<WebVerifyEmailView> createState() => _WebVerifyEmailViewState();
}

class _WebVerifyEmailViewState extends ConsumerState<WebVerifyEmailView>
    with SingleTickerProviderStateMixin {
  static const int _codeLength = 6;
  static const int _initialSeconds = 45;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  int _secondsLeft = _initialSeconds;
  Timer? _timer;
  bool _isLoading = false;
  bool _isResending = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _startCountdown();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
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

  String _getResolvedEmail() {
    if (widget.email != null && widget.email!.trim().isNotEmpty) {
      return widget.email!.trim();
    }
    final pending = ref.read(pendingEmailProvider);
    if (pending != null && pending.trim().isNotEmpty) {
      return pending.trim();
    }
    final authEmail = ref.read(authStateProvider).valueOrNull?.email;
    if (authEmail != null && authEmail.trim().isNotEmpty) {
      return authEmail.trim();
    }
    return 'etudiant@universite.fr';
  }

  String get _otpCode => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otpCode.length == _codeLength;

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      _handlePaste(value);
      return;
    }

    if (value.isNotEmpty) {
      if (index < _codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_isComplete) {
          _handleVerify();
        }
      }
    }
    setState(() {});
  }

  void _handlePaste(String text) {
    final cleanDigits = text.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.isEmpty) return;

    for (int i = 0; i < _codeLength; i++) {
      if (i < cleanDigits.length) {
        _controllers[i].text = cleanDigits[i];
      }
    }
    setState(() {});

    final targetIndex = cleanDigits.length.clamp(0, _codeLength - 1);
    _focusNodes[targetIndex].requestFocus();

    if (_isComplete) {
      _handleVerify();
    }
  }

  void _showFailure(Failure failure) {
    final l10n = failureL10n(failure);
    final translated = context.tr(l10n.key, args: l10n.args);
    final message =
        (translated == l10n.key || translated.isEmpty) ? failure.message : translated;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVerify() async {
    if (!_isComplete) return;
    final email = _getResolvedEmail();

    setState(() => _isLoading = true);

    try {
      await ref.read(authStateProvider.notifier).verifyEmail(
            email: email,
            code: _otpCode,
          );
      if (mounted) {
        context.go('/role-selection');
      }
    } on Failure catch (failure) {
      if (mounted) _showFailure(failure);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            content: Text(context.tr('error_unexpected')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_secondsLeft > 0 || _isResending) return;
    final email = _getResolvedEmail();

    setState(() => _isResending = true);
    try {
      await ref.read(authStateProvider.notifier).resendVerification(email: email);
      if (mounted) {
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F9D78),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(context.tr('code_resent')),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            content: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final email = _getResolvedEmail();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // Left side: Widescreen Animated Hero Section
          Expanded(
            flex: 6,
            child: WebAuthHeroSection(isDark: isDark),
          ),

          // Right side: Dedicated Verification Card
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // Top control bar (Theme & Language switches)
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
                          constraints: const BoxConstraints(maxWidth: 480),
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
                                // Step indicator & Badge
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
                                              Icons.verified_user_rounded,
                                              size: 14,
                                              color: Color(0xFF4338CA),
                                            ),
                                            SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'VÉRIFICATION',
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
                                    Text(
                                      'Étape 1 / 3',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Title & Subtitle
                                Text(
                                  context.tr('verify_email_title'),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr('verify_email_subtitle'),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    height: 1.4,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Email Chip with Edit button
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.4),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.alternate_email_rounded,
                                        size: 16,
                                        color: Color(0xFF2D3E8C),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          email,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2D3E8C),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => context.go('/register'),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            size: 15,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // 6 OTP Inputs Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(_codeLength, (index) {
                                    return SizedBox(
                                      width: 54,
                                      height: 60,
                                      child: KeyboardListener(
                                        focusNode: FocusNode(),
                                        onKeyEvent: (event) {
                                          if (event is KeyDownEvent &&
                                              event.logicalKey ==
                                                  LogicalKeyboardKey.backspace &&
                                              _controllers[index].text.isEmpty &&
                                              index > 0) {
                                            _focusNodes[index - 1].requestFocus();
                                            _controllers[index - 1].clear();
                                            setState(() {});
                                          }
                                        },
                                        child: TextField(
                                          controller: _controllers[index],
                                          focusNode: _focusNodes[index],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          maxLength: 1,
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
                                            fillColor: _focusNodes[index].hasFocus
                                                ? const Color(0xFFEEF2FF)
                                                : (_controllers[index].text.isNotEmpty
                                                    ? const Color(0xFFF8FAFC)
                                                    : colorScheme.surface),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: _controllers[index].text.isNotEmpty
                                                    ? const Color(0xFF2D3E8C)
                                                    : colorScheme.outlineVariant
                                                        .withValues(alpha: 0.6),
                                                width: _controllers[index].text.isNotEmpty
                                                    ? 1.5
                                                    : 1.0,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF122675),
                                                width: 2.0,
                                              ),
                                            ),
                                          ),
                                          onChanged: (val) =>
                                              _onDigitChanged(index, val),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 16),

                                // Helper status pill
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _isComplete
                                          ? const Color(0xFFECFDF5)
                                          : colorScheme.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isComplete
                                              ? Icons.check_circle_rounded
                                              : Icons.pending_rounded,
                                          size: 13,
                                          color: _isComplete
                                              ? const Color(0xFF0F9D78)
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            _isComplete
                                                ? context.tr('otp_complete')
                                                : 'Saisissez les 6 chiffres du code',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _isComplete
                                                ? const Color(0xFF0F9D78)
                                                : colorScheme.onSurfaceVariant,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Primary Submit Button
                                SizedBox(
                                  height: 50,
                                  child: FilledButton(
                                    onPressed: (_isComplete && !_isLoading)
                                        ? _handleVerify
                                        : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF122675),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                context.tr('validate_action'),
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Resend Timer row
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      context.tr('nothing_received'),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (_secondsLeft > 0)
                                      Text(
                                        'Renvoyer (${_secondsLeft}s)',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2D3E8C),
                                        ),
                                      )
                                    else
                                      TextButton(
                                        onPressed: _isResending ? null : _handleResend,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          context.tr('resend_code'),
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF122675),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Back to Login link
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () => context.go('/login'),
                                    icon: const Icon(Icons.arrow_back_rounded,
                                        size: 15, color: Color(0xFF64748B)),
                                    label: Text(
                                      context.tr('back_to_login'),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
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
}

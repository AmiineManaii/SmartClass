import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/web_controls_bar.dart';
import '../widgets/web_auth_hero_section.dart';

enum _WebResetState { idle, updating, success }

/// Desktop split-screen view for Reset Password.
/// Includes dynamic password strength meter, rule checklist with live animations,
/// matching indicator, and academic password guidelines.
class WebResetPasswordView extends ConsumerStatefulWidget {
  const WebResetPasswordView({super.key});

  @override
  ConsumerState<WebResetPasswordView> createState() =>
      _WebResetPasswordViewState();
}

class _WebResetPasswordViewState extends ConsumerState<WebResetPasswordView>
    with SingleTickerProviderStateMixin {
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  _WebResetState _state = _WebResetState.idle;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
    _animController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  static int _calculateScore(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[A-ZÀ-Þ]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }

  static List<bool> _checkRules(String password) => [
        password.length >= 8,
        RegExp(r'[0-9]').hasMatch(password),
        RegExp(r'[A-ZÀ-Þ]').hasMatch(password),
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
      ];

  bool get _matches =>
      _newController.text.isNotEmpty &&
      _newController.text == _confirmController.text;

  Map<String, String> _getResetContext() {
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, String>) return extra;
    if (extra is Map) {
      return extra.map((key, value) => MapEntry('$key', '$value'));
    }
    return const {};
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

  Future<void> _handleSubmit() async {
    if (_state != _WebResetState.idle) return;
    final password = _newController.text;

    if (_calculateScore(password) < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          content: Text(context.tr('required_field')),
        ),
      );
      return;
    }

    if (!_matches) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          content: Text(context.tr('passwords_dont_match')),
        ),
      );
      return;
    }

    final reset = _getResetContext();
    final email = reset['email'] ?? '';
    final code = reset['code'] ?? '';

    if (email.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          content: Text(context.tr('session_expired')),
        ),
      );
      context.go('/forgot-password');
      return;
    }

    setState(() => _state = _WebResetState.updating);

    try {
      await ref.read(authStateProvider.notifier).resetPassword(
            email: email,
            code: code,
            newPassword: password,
          );
      if (mounted) {
        setState(() => _state = _WebResetState.success);
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          context.go('/login');
        }
      }
    } on Failure catch (failure) {
      if (mounted) {
        setState(() => _state = _WebResetState.idle);
        _showFailure(failure);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _state = _WebResetState.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            content: Text(context.tr('error_unexpected')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final password = _newController.text;
    final score = _calculateScore(password);
    final rules = _checkRules(password);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // Left side: Widescreen Hero Section
          Expanded(
            flex: 6,
            child: WebAuthHeroSection(isDark: isDark),
          ),

          // Right side: Dedicated Reset Password Card
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
                                // Step pill & Back
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.shield_outlined,
                                              size: 14,
                                              color: Color(0xFF0F9D78),
                                            ),
                                            SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'SÉCURITÉ',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0F9D78),
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
                                  context.tr('new_password_title'),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  context.tr('new_password_subtitle'),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    height: 1.4,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // New Password Field
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      context.tr('new_password_label'),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      context.tr('required_badge'),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2D3E8C),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _newController,
                                  obscureText: _obscureNew,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '••••••••••••',
                                    prefixIcon: const Icon(
                                      Icons.key_rounded,
                                      size: 19,
                                      color: Color(0xFF2D3E8C),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNew
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 19,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscureNew = !_obscureNew),
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF191F33)
                                        : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: colorScheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: colorScheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF122675),
                                        width: 1.8,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Animated Strength Meter
                                _buildStrengthMeter(score, isDark),
                                const SizedBox(height: 14),

                                // Rules Checklist
                                _buildRulesChecklist(rules, isDark),
                                const SizedBox(height: 20),

                                // Confirm Password Field
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      context.tr('confirm_password'),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (_matches)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 13,
                                            color: Color(0xFF0F9D78),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            context.tr('passwords_match'),
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F9D78),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _confirmController,
                                  obscureText: _obscureConfirm,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (_) => setState(() {}),
                                  onFieldSubmitted: (_) => _handleSubmit(),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '••••••••••••',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 19,
                                      color: Color(0xFF2D3E8C),
                                    ),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_matches)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFF0F9D78),
                                            size: 19,
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            _obscureConfirm
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 19,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          onPressed: () => setState(
                                              () => _obscureConfirm = !_obscureConfirm),
                                        ),
                                      ],
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF191F33)
                                        : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: colorScheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: colorScheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF122675),
                                        width: 1.8,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Academic advice card
                                Container(
                                  padding: const EdgeInsets.all(14),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF2FF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.tips_and_updates_rounded,
                                          size: 18,
                                          color: Color(0xFF4338CA),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              context.tr('academic_advice_title'),
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              context.tr('academic_advice_desc'),
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11,
                                                height: 1.35,
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Submit Button
                                SizedBox(
                                  height: 50,
                                  child: FilledButton(
                                    onPressed: (_state == _WebResetState.idle &&
                                            score == 4 &&
                                            _matches)
                                        ? _handleSubmit
                                        : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          _state == _WebResetState.success
                                              ? const Color(0xFF0F9D78)
                                              : const Color(0xFF122675),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _state == _WebResetState.updating
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : (_state == _WebResetState.success
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle_rounded,
                                                    size: 20,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      context.tr('password_updated'),
                                                      style: const TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      context.tr('reset_password'),
                                                      style: const TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    size: 18,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              )),
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

  Widget _buildStrengthMeter(int score, bool isDark) {
    Color barColor;
    String label;

    switch (score) {
      case 1:
        barColor = const Color(0xFFEF4444);
        label = 'Très faible';
        break;
      case 2:
        barColor = const Color(0xFFF59E0B);
        label = 'Moyen';
        break;
      case 3:
        barColor = const Color(0xFF3B82F6);
        label = 'Bon';
        break;
      case 4:
        barColor = const Color(0xFF0F9D78);
        label = 'Excellent';
        break;
      default:
        barColor = isDark ? Colors.white24 : const Color(0xFFE2E8F0);
        label = 'Sécurité';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Force du mot de passe',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(4, (index) {
            final active = index < score;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 5,
                margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                decoration: BoxDecoration(
                  color: active
                      ? barColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRulesChecklist(List<bool> rules, bool isDark) {
    final ruleLabels = [
      'Au moins 8 caractères',
      'Au moins un chiffre (0-9)',
      'Au moins une lettre majuscule (A-Z)',
      'Au moins un caractère spécial (!@#\$...)',
    ];

    return Column(
      children: List.generate(ruleLabels.length, (i) {
        final met = rules[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: met ? const Color(0xFF0F9D78) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: met
                        ? const Color(0xFF0F9D78)
                        : (isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1)),
                    width: 1.5,
                  ),
                ),
                child: met
                    ? const Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ruleLabels[i],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: met ? FontWeight.w600 : FontWeight.w400,
                    color: met
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8)),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

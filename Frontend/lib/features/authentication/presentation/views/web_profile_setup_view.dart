import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/web_controls_bar.dart';
import '../../application/providers/auth_options_provider.dart';
import '../widgets/web_auth_hero_section.dart';

/// Desktop split-screen view for Profile Setup (Step 3).
/// Includes interactive avatar badge, institution input, study level dropdown,
/// specialty input, animated subject interest chips, and real profile completion.
class WebProfileSetupView extends ConsumerStatefulWidget {
  const WebProfileSetupView({super.key});

  @override
  ConsumerState<WebProfileSetupView> createState() => _WebProfileSetupViewState();
}

class _WebProfileSetupViewState extends ConsumerState<WebProfileSetupView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _institutionController = TextEditingController();
  final _specialtyController = TextEditingController();
  String? _level;
  bool _isLoading = false;

  final Set<String> _selectedInterests = {'IA & Data', 'Mathématiques'};

  static const List<String> _suggestedInterests = [
    'IA & Data',
    'Mathématiques',
    'Algorithmes',
    'Physique',
    'Développement Web',
    'Cybersécurité',
    'Sciences Éco',
  ];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _level = 'Licence 1';

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
    _institutionController.dispose();
    _specialtyController.dispose();
    super.dispose();
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
    final user = ref.read(authStateProvider).value;
    final needsStudyInfo = user?.role == 'student';

    if (_institutionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          content: Text(context.tr('required_field')),
        ),
      );
      return;
    }

    if (needsStudyInfo &&
        ((_level ?? '').isEmpty || _specialtyController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          content: Text(context.tr('required_field')),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authStateProvider.notifier).completeProfile();
      if (mounted) {
        context.go('/home');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final levels = ref.watch(authStudyLevelsProvider);
    final user = ref.watch(authStateProvider).value;
    final needsStudyInfo = user?.role == 'student';

    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // Left side: Hero Section
          Expanded(
            flex: 6,
            child: WebAuthHeroSection(isDark: isDark),
          ),

          // Right side: Dedicated Profile Setup Form
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
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 540),
                          child: Container(
                            padding: const EdgeInsets.all(36),
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
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Step pill
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
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
                                              Icons.auto_awesome,
                                              size: 14,
                                              color: Color(0xFF0F9D78),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'FINALISATION DU PROFIL',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F9D78),
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'Étape 3 / 3',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Title & Subtitle
                                  Text(
                                    context.tr('profile_setup_title'),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    context.tr('profile_setup_subtitle'),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      height: 1.4,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Avatar Card Preview
                                  Center(
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 88,
                                          height: 88,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF122675),
                                                Color(0xFF4056B9),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF122675)
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            userName.isNotEmpty
                                                ? userName[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 34,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: -4,
                                          child: Tooltip(
                                            message: context.tr('avatar_optional'),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F9D78),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isDark
                                                      ? const Color(0xFF1E2438)
                                                      : Colors.white,
                                                  width: 2.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF0F9D78)
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt_rounded,
                                                size: 15,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Text(
                                      context.tr('avatar_optional'),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Institution Field
                                  _buildFieldLabel(
                                    label: context.tr('institution_label'),
                                    isRequired: true,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _institutionController,
                                    textInputAction: needsStudyInfo
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Ex: Université Paris-Saclay, Esprit...',
                                      hintStyle: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.account_balance_outlined,
                                        size: 20,
                                        color: Color(0xFF2D3E8C),
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? const Color(0xFF191F33)
                                          : const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: colorScheme.outlineVariant
                                              .withValues(alpha: 0.6),
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

                                  // If Student: Study Level & Specialty
                                  if (needsStudyInfo) ...[
                                    const SizedBox(height: 18),
                                    _buildFieldLabel(
                                      label: "Niveau d'études",
                                      isRequired: true,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      initialValue: _level,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      dropdownColor: isDark
                                          ? const Color(0xFF1E2438)
                                          : Colors.white,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.school_outlined,
                                          size: 20,
                                          color: Color(0xFF2D3E8C),
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xFF191F33)
                                            : const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: colorScheme.outlineVariant
                                                .withValues(alpha: 0.6),
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
                                      items: levels.map((lvl) {
                                        return DropdownMenuItem<String>(
                                          value: lvl,
                                          child: Text(lvl),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _level = val);
                                      },
                                    ),

                                    const SizedBox(height: 18),
                                    _buildFieldLabel(
                                      label: "Spécialité / Filière",
                                      isRequired: true,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _specialtyController,
                                      textInputAction: TextInputAction.done,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Ex: Informatique, Mathématiques, Droit...',
                                        hintStyle: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          color: colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.psychology_outlined,
                                          size: 20,
                                          color: Color(0xFF2D3E8C),
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xFF191F33)
                                            : const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: colorScheme.outlineVariant
                                                .withValues(alpha: 0.6),
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
                                    _buildFieldLabel(
                                      label: "Centres d'intérêt académiques",
                                      isRequired: false,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _suggestedInterests.map((interest) {
                                        final isSelected =
                                            _selectedInterests.contains(interest);
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedInterests.remove(interest);
                                              } else {
                                                _selectedInterests.add(interest);
                                              }
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFFEEF2FF)
                                                  : (isDark
                                                      ? Colors.white.withValues(alpha: 0.05)
                                                      : const Color(0xFFF1F5F9)),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF122675)
                                                    : Colors.transparent,
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isSelected) ...[
                                                  const Icon(
                                                    Icons.check_rounded,
                                                    size: 13,
                                                    color: Color(0xFF122675),
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                                Text(
                                                  interest,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                    color: isSelected
                                                        ? const Color(0xFF122675)
                                                        : (isDark
                                                            ? const Color(0xFFCBD5E1)
                                                            : const Color(0xFF475569)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 28),

                                  // Primary Button
                                  SizedBox(
                                    height: 50,
                                    child: FilledButton(
                                      onPressed: _isLoading ? null : _handleSubmit,
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  context.tr('validate_profile'),
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.rocket_launch_rounded,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Trust note
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 15,
                                        color: Color(0xFF0F9D78),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          context.tr('profile_edit_later'),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
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

  Widget _buildFieldLabel({
    required String label,
    required bool isRequired,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (isRequired)
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
    );
  }
}

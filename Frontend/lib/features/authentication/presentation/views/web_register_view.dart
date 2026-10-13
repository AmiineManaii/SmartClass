import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/web_auth_hero_section.dart';
import '../../../../core/widgets/web_controls_bar.dart';

typedef WebRegisterView = WebRegisterPage;

class WebRegisterPage extends ConsumerStatefulWidget {
  const WebRegisterPage({super.key});

  @override
  ConsumerState<WebRegisterPage> createState() => _WebRegisterPageState();
}

class _WebRegisterPageState extends ConsumerState<WebRegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _acceptTerms = true;
  String _selectedRole = 'student'; // 'student' | 'teacher' | 'admin'
  bool _isLoading = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double strength = 0.0;
    if (password.length >= 8) strength += 0.35;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) strength += 0.15;
    return strength.clamp(0.0, 1.0);
  }

  void _showFailure(Failure failure) {
    final l10n = failureL10n(failure);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.error,
        content: Text(context.tr(l10n.key, args: l10n.args)),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final isFr = ref.read(localeProvider) == 'fr';
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          content: Text(
            isFr
                ? 'Veuillez accepter les conditions d\'utilisation.'
                : 'Please accept the terms of service.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();
      final parts = name.split(RegExp(r'\s+'));
      final firstName = parts.isNotEmpty ? parts.first : 'User';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      await ref.read(authStateProvider.notifier).register(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            role: _selectedRole,
          );

      if (mounted) {
        context.go('/verify-email?email=${Uri.encodeComponent(email)}');
      }
    } on Failure catch (failure) {
      if (!mounted) return;
      _showFailure(failure);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          content: Text(
            isFr
                ? 'Une erreur est survenue lors de l\'inscription.'
                : 'An error occurred during registration.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isFr = currentLocale == 'fr';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final passwordStrength =
        _calculatePasswordStrength(_passwordController.text);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0F1D)
          : AppTheme.surfaceContainerLowest,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==========================================
          // 1. LEFT STAGE (50%): Showcase & Trust
          // ==========================================
          Expanded(
            child: WebAuthHeroSection(isDark: isDark),
          ),

          // ==========================================
          // 2. RIGHT FORM STAGE (50%): Registration Form
          // ==========================================
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 44,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Right Header with WebControlsBar (Theme + Lang) & Sign-In Link
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 14,
                          runSpacing: 10,
                          children: [
                            const WebControlsBar(),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  isFr
                                      ? 'Vous avez déjà un compte ? '
                                      : 'Already have an account? ',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : AppTheme.onSurfaceVariant,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => context.go('/login'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? const Color(0xFF1E293B)
                                        : AppTheme.surfaceContainerLow,
                                    foregroundColor:
                                        isDark ? Colors.white : AppTheme.primary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    isFr ? 'Se connecter' : 'Sign in',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Form Block
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Security Pill
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : AppTheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_rounded,
                                        color: isDark
                                            ? const Color(0xFF38BDF8)
                                            : AppTheme.primary,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isFr
                                            ? 'Inscription Sécurisée'
                                            : 'Secure Registration',
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF38BDF8)
                                              : AppTheme.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isFr
                                    ? 'Créer un compte SmartClass'
                                    : 'Create a SmartClass Account',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.onSurface,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isFr
                                    ? 'Remplissez le formulaire ci-dessous avec vos informations universitaires.'
                                    : 'Fill out the form below with your university credentials.',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppTheme.onSurfaceVariant,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Role Quick-Selector Animated Segmented Tabs
                              _buildRoleSegmentedTabs(isDark, isFr),

                              const SizedBox(height: 14),

                              // Two-Column Grid Row 1: Full Name & Email
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nom complet
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isFr ? 'Nom complet' : 'Full name',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.onSurface,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _nameController,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.onSurface,
                                            fontSize: 13,
                                          ),
                                          decoration: _inputDecoration(
                                            hintText: isFr
                                                ? 'ex: Salma Mansouri'
                                                : 'e.g. Salma Mansouri',
                                            prefixIcon:
                                                Icons.person_outline_rounded,
                                            isDark: isDark,
                                          ),
                                          validator: (v) => (v == null ||
                                                  v.trim().isEmpty)
                                              ? (isFr
                                                  ? 'Veuillez saisir votre nom'
                                                  : 'Please enter your name')
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Email institutionnelle
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isFr
                                              ? 'Email académique (.edu)'
                                              : 'Academic email (.edu)',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.onSurface,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.onSurface,
                                            fontSize: 13,
                                          ),
                                          decoration: _inputDecoration(
                                            hintText:
                                                'salma@smartclass.edu',
                                            prefixIcon:
                                                Icons.alternate_email_rounded,
                                            isDark: isDark,
                                          ),
                                          validator: (v) {
                                            if (v == null ||
                                                v.trim().isEmpty) {
                                              return isFr
                                                  ? 'Email requis'
                                                  : 'Email required';
                                            }
                                            if (!v.contains('@')) {
                                              return isFr
                                                  ? 'Format invalide'
                                                  : 'Invalid format';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Two-Column Grid Row 2: Password & Confirm Password
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Mot de passe
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isFr
                                              ? 'Mot de passe (8+ car.)'
                                              : 'Password (8+ chars)',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.onSurface,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          onChanged: (v) => setState(() {}),
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.onSurface,
                                            fontSize: 13,
                                          ),
                                          decoration: _inputDecoration(
                                            hintText: '••••••••',
                                            prefixIcon:
                                                Icons.lock_outline_rounded,
                                            isDark: isDark,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons
                                                        .visibility_outlined
                                                    : Icons
                                                        .visibility_off_outlined,
                                                color: isDark
                                                    ? const Color(0xFF94A3B8)
                                                    : AppTheme.outline,
                                                size: 18,
                                              ),
                                              onPressed: () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                            ),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return isFr
                                                  ? 'Mot de passe requis'
                                                  : 'Password required';
                                            }
                                            if (v.length < 8) {
                                              return isFr
                                                  ? 'Min 8 caractères'
                                                  : 'Min 8 chars';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Confirmer mot de passe
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isFr
                                              ? 'Confirmer mot de passe'
                                              : 'Confirm password',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.onSurface,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller:
                                              _confirmPasswordController,
                                          obscureText: _obscurePassword,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.onSurface,
                                            fontSize: 13,
                                          ),
                                          decoration: _inputDecoration(
                                            hintText: '••••••••',
                                            prefixIcon:
                                                Icons.lock_outline_rounded,
                                            isDark: isDark,
                                          ),
                                          validator: (v) {
                                            if (v !=
                                                _passwordController.text) {
                                              return isFr
                                                  ? 'Mots de passe non identiques'
                                                  : 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Password Strength Bar
                              if (_passwordController.text.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: passwordStrength,
                                          minHeight: 4,
                                          backgroundColor: isDark
                                              ? const Color(0xFF334155)
                                              : AppTheme.surfaceContainer,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            passwordStrength < 0.4
                                                ? AppTheme.error
                                                : passwordStrength < 0.75
                                                    ? Colors.amber
                                                    : AppTheme.tertiaryFixed,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      passwordStrength < 0.4
                                          ? (isFr ? 'Faible' : 'Weak')
                                          : passwordStrength < 0.75
                                              ? (isFr ? 'Moyen' : 'Medium')
                                              : (isFr
                                                  ? 'Robuste'
                                                  : 'Strong'),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: passwordStrength < 0.4
                                            ? AppTheme.error
                                            : passwordStrength < 0.75
                                                ? Colors.amber.shade700
                                                : AppTheme.tertiaryFixed,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 10),

                              // Terms & Conditions Checkbox
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _acceptTerms,
                                      activeColor:
                                          AppTheme.primaryContainer,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      onChanged: (v) => setState(
                                        () => _acceptTerms = v ?? true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isFr
                                          ? 'J\'accepte les Conditions Générales d\'Utilisation et la Charte d\'Intégrité.'
                                          : 'I accept the Terms of Service and Academic Integrity Charter.',
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : AppTheme.onSurfaceVariant,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Submit Button
                              SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? const Color(0xFF2563EB)
                                        : AppTheme.primaryContainer,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              isFr
                                                  ? 'Créer mon compte'
                                                  : 'Create my account',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // SSO Block
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : AppTheme.surfaceContainer,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    isFr
                                        ? 'OU S\'INSCRIRE AVEC VOS IDENTIFIANTS ENT'
                                        : 'OR REGISTER WITH YOUR INSTITUTIONAL SSO',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : AppTheme.surfaceContainer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSsoButton(
                                    icon: Icons.g_mobiledata_rounded,
                                    iconColor: Colors.blue,
                                    label: 'Google Workspace',
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildSsoButton(
                                    icon: Icons.window_rounded,
                                    iconColor: Colors.deepOrange,
                                    label: 'Microsoft 365',
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Security Footnote
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 12,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                isFr
                                    ? 'Inscription et authentification sécurisées par protocole TLS 1.3 & HSTS'
                                    : 'Registration and authentication secured via TLS 1.3 & HSTS',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  fontSize: 10.5,
                                ),
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
        ],
      ),
    );
  }

  Widget _buildRoleSegmentedTabs(bool isDark, bool isFr) {
    final roles = [
      {'role': 'student', 'label': isFr ? 'Étudiant' : 'Student'},
      {'role': 'teacher', 'label': isFr ? 'Enseignant' : 'Teacher'},
      {'role': 'admin', 'label': isFr ? 'Administrateur' : 'Administrator'},
    ];

    final activeIndex = roles.indexWhere((r) => r['role'] == _selectedRole);
    final validIndex = activeIndex >= 0 ? activeIndex : 0;

    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : AppTheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / roles.length;
          return Stack(
            children: [
              // Smooth sliding indicator pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                left: validIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2563EB) : Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFF2563EB).withValues(alpha: 0.40)
                            : const Color(0x141D2338),
                        blurRadius: isDark ? 8 : 6,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              // Interactive role labels
              Row(
                children: roles.map((item) {
                  final role = item['role']!;
                  final title = item['label']!;
                  final isSelected = _selectedRole == role;

                  return Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _selectedRole = role),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            style: TextStyle(
                              color: isSelected
                                  ? (isDark ? Colors.white : AppTheme.primary)
                                  : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppTheme.onSurfaceVariant),
                              fontSize: 12.5,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSsoButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    bool isDark = false,
  }) {
    final isFr = ref.watch(localeProvider) == 'fr';
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFr
                    ? 'Connexion SSO institutionnelle en cours d\'intégration.'
                    : 'Institutional SSO login integration in progress.',
              ),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          backgroundColor: isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 17),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.onSurface,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool isDark = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        fontSize: 12.5,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        size: 18,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryContainer,
          width: 1.5,
        ),
      ),
    );
  }
}

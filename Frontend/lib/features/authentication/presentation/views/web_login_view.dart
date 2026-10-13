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

typedef WebLoginView = WebLoginPage;

class WebLoginPage extends ConsumerStatefulWidget {
  const WebLoginPage({super.key});

  @override
  ConsumerState<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends ConsumerState<WebLoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  String _selectedRole = 'student'; // 'student' | 'teacher' | 'admin'
  bool _isLoading = false;

  late AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final isFr = ref.read(localeProvider) == 'fr';
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      await ref.read(authStateProvider.notifier).login(
            email,
            password,
          );

      if (mounted) {
        final auth = ref.read(authStateProvider).valueOrNull;
        if (auth != null && auth.isAuthenticated) {
          if (auth.onboardingCompleted) {
            context.go('/home');
          } else {
            context.go('/role-selection');
          }
        }
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
                ? 'Une erreur inattendue est survenue.'
                : 'An unexpected error occurred.',
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

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0F1D)
          : AppTheme.surfaceContainerLowest,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==========================================
          // 1. LEFT STAGE (50%): Premium Showcase
          // ==========================================
          Expanded(
            child: WebAuthHeroSection(isDark: isDark),
          ),

          // ==========================================
          // 2. RIGHT FORM STAGE (50%): Clean Academic Portal
          // ==========================================
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 44,
                    vertical: 22,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Right Header Bar with WebControlsBar (Theme + Lang) & Sign-Up Link
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
                                      ? 'Vous n\'avez pas de compte ? '
                                      : 'Don\'t have an account? ',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : AppTheme.onSurfaceVariant,
                                    fontSize: 12.5,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/register'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    isFr
                                        ? 'Demander un accès'
                                        : 'Request access',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Main Form Block
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
                                            ? 'Espace Sécurisé'
                                            : 'Secure Portal',
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
                                    ? 'Connexion à votre espace'
                                    : 'Sign in to your space',
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
                                    ? 'Saisissez vos identifiants académiques pour accéder à vos cours et examens.'
                                    : 'Enter your academic credentials to access your courses and exams.',
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

                              // Email Field
                              Text(
                                isFr
                                    ? 'Adresse email institutionnelle'
                                    : 'Institutional email address',
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
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.onSurface,
                                  fontSize: 13,
                                ),
                                decoration: _inputDecoration(
                                  hintText: 'salma.mansouri@smartclass.edu',
                                  prefixIcon: Icons.alternate_email_rounded,
                                  isDark: isDark,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return isFr
                                        ? 'Veuillez saisir votre email'
                                        : 'Please enter your email';
                                  }
                                  if (!v.contains('@')) {
                                    return isFr
                                        ? 'Format d\'email invalide'
                                        : 'Invalid email format';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              // Password Field & Forgot Password Link
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    isFr ? 'Mot de passe' : 'Password',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : AppTheme.onSurface,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.go('/forgot-password'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      isFr
                                          ? 'Mot de passe oublié ?'
                                          : 'Forgot password?',
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF38BDF8)
                                            : const Color(0xFF2563EB),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.onSurface,
                                  fontSize: 13,
                                ),
                                decoration: _inputDecoration(
                                  hintText: '••••••••••••',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isDark: isDark,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : AppTheme.outline,
                                      size: 19,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePassword =
                                          !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? (isFr
                                        ? 'Veuillez saisir votre mot de passe'
                                        : 'Please enter your password')
                                    : null,
                              ),

                              const SizedBox(height: 10),

                              // Remember Me Checkbox
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor:
                                          AppTheme.primaryContainer,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      onChanged: (v) => setState(
                                        () => _rememberMe = v ?? true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isFr
                                        ? 'Se souvenir de moi pendant 30 jours'
                                        : 'Remember me for 30 days',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : AppTheme.onSurfaceVariant,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Primary Submit Button
                              SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _handleLogin,
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
                                                  ? 'Se connecter'
                                                  : 'Sign in',
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

                        // SSO & Federation Block
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
                                        ? 'OU CONTINUER AVEC VOS IDENTIFIANTS ENT'
                                        : 'OR CONTINUE WITH INSTITUTIONAL SSO',
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
                                    label: 'Google Workspace for Education',
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildSsoButton(
                                    icon: Icons.window_rounded,
                                    iconColor: Colors.deepOrange,
                                    label: 'Microsoft 365 Éducation / Azure AD',
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Security Protocol Footnote
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
                                    ? 'Connexion sécurisée par protocole TLS 1.3 & HSTS'
                                    : 'Secure login via TLS 1.3 & HSTS protocols',
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
                    ? 'Authentification fédérée SSO en cours d\'intégration.'
                    : 'Federated SSO authentication in progress.',
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

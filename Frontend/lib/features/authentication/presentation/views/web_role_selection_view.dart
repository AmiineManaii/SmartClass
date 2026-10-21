import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/web_controls_bar.dart';
import '../../../../core/widgets/smart_loader.dart';

/// Full-canvas desktop view for Role Selection ("Bienvenue ! Qui êtes-vous ?"),
/// faithful to the Stitch design specifications.
///
/// Features:
/// - Top navigation with SmartClass branding, Help Center, FAQ, Support, and User avatar.
/// - Step capsule badge ("ÉTAPE 1 SUR 3 • Personnalisation de votre espace d'apprentissage").
/// - Segmented 3-pill progress bar.
/// - Big centered headline & academic description.
/// - 3 detailed role cards in a responsive row:
///   1. Étudiant (Apprenant, graduation icon, 4 checklist items, immediate access).
///   2. Enseignant (Pédagogique, presenter icon, 4 checklist items, cohort management).
///   3. Administrateur (Direction, security shield, 4 checklist items, accreditation required).
/// - Bottom disclaimer banner with Retour and Continuer buttons.
/// - Footer with copyright and legal links.
class WebRoleSelectionView extends ConsumerStatefulWidget {
  const WebRoleSelectionView({super.key});

  @override
  ConsumerState<WebRoleSelectionView> createState() =>
      _WebRoleSelectionViewState();
}

class _WebRoleSelectionViewState extends ConsumerState<WebRoleSelectionView>
    with SingleTickerProviderStateMixin {
  late String _selectedRole;
  bool _saving = false;
  String? _hoveredRole;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final role = ref.read(authStateProvider).valueOrNull?.role;
    if (role == 'teacher') {
      _selectedRole = 'teacher';
    } else if (role == 'admin') {
      _selectedRole = 'admin';
    } else {
      _selectedRole = 'student';
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
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
    super.dispose();
  }

  void _showFailure(Failure failure) {
    final l10n = failureL10n(failure);
    final translated = context.tr(l10n.key, args: l10n.args);
    final message =
        (translated == l10n.key || translated.isEmpty) ? failure.message : translated;

    context.showErrorToast(message);
  }

  void _showAdminAccreditationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2438) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFF2D3E8C),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Accréditation requise',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Les comptes de Direction et d\'Administration sont strictement provisionnés par l\'administrateur référent de votre établissement ou via synchronisation ENT/LDAP.\n\nPour continuer votre découverte de SmartClass, nous vous invitons à sélectionner le profil Enseignant ou Étudiant.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF454651),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _selectedRole = 'student');
              _handleConfirm();
            },
            child: const Text('Choisir Étudiant'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2D3E8C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _selectedRole = 'teacher');
              _handleConfirm();
            },
            child: const Text('Choisir Enseignant'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirm() async {
    if (_saving) return;

    if (_selectedRole == 'admin') {
      _showAdminAccreditationDialog();
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(authStateProvider.notifier).updateRole(_selectedRole);
      if (mounted) {
        context.go('/profile-setup');
      }
    } on Failure catch (failure) {
      if (mounted) _showFailure(failure);
    } catch (_) {
      if (mounted) {
        context.showErrorToast(context.tr('error_unexpected'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F1422) : const Color(0xFFFAF8FF);
    final navBgColor = isDark ? const Color(0xFF1E2438) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── 1. Top Navbar matching Stitch ──
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: navBgColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                // Brand logo + text
                Image.asset(
                  'assets/images/logo_emblem.png',
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const Icon(
                    Icons.school_rounded,
                    size: 30,
                    color: Color(0xFF2D3E8C),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'SmartClass',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : const Color(0xFF2D3E8C),
                  ),
                ),

                const Spacer(),

                // Nav links
                _buildNavLink('Help Center', () {}),
                const SizedBox(width: 24),
                _buildNavLink('FAQ', () {}),
                const SizedBox(width: 24),
                _buildNavLink('Support', () {}),
                const SizedBox(width: 24),

                // User avatar icon circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF122675),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 16),
                const WebControlsBar(),
              ],
            ),
          ),

          // ── 2. Scrollable Body Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Step Capsule Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E284A)
                                  : const Color(0xFFEBEDFF),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4338CA),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'ÉTAPE 1 SUR 3',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D3E8C),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF818CF8)
                                        : const Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Personnalisation de votre espace d\'apprentissage',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF454651),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 3 Horizontal Progress Bars
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 34,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D3E8C),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 22,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : const Color(0xFFDEE1FF),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 22,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : const Color(0xFFDEE1FF),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Big Title
                          Text(
                            'Bienvenue ! Qui êtes-vous ?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: isDark ? Colors.white : const Color(0xFF151B2F),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Subtitle
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: Text(
                              'Sélectionnez votre profil académique pour que SmartClass configure vos outils pédagogiques et vos accès institutionnels adaptés.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.5,
                                height: 1.45,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF454651),
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // ── 3 Role Cards Row ──
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 920;
                              if (isNarrow) {
                                return Column(
                                  children: [
                                    _buildStudentCard(isDark),
                                    const SizedBox(height: 20),
                                    _buildTeacherCard(isDark),
                                    const SizedBox(height: 20),
                                    _buildAdminCard(isDark),
                                  ],
                                );
                              }

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: _buildStudentCard(isDark)),
                                    const SizedBox(width: 22),
                                    Expanded(child: _buildTeacherCard(isDark)),
                                    const SizedBox(width: 22),
                                    Expanded(child: _buildAdminCard(isDark)),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // ── 4. Bottom Info Banner & Action Row ──
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2438)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A)
                                      .withValues(alpha: isDark ? 0.25 : 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Info icon in light blue circle
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF232D4B)
                                        : const Color(0xFFEEF2FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: Color(0xFF2D3E8C),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Notice text
                                Expanded(
                                  child: Text(
                                    'Vous pourrez ajuster vos préférences ou associer d’autres rôles plus tard avec l’accord de votre établissement scolaire.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      height: 1.4,
                                      color: isDark
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF454651),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),

                                // Retour button
                                TextButton(
                                  onPressed: () => context.go('/login'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 12),
                                  ),
                                  child: Text(
                                    'Retour',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Continuer button
                                SizedBox(
                                  height: 44,
                                  child: FilledButton(
                                    onPressed: _saving ? null : _handleConfirm,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF2D3E8C),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _saving
                                        ? const SmartLoader.small(
                                            color: Colors.white,
                                            customSize: 18,
                                          )
                                        : const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Continuer',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 17,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),

                          // ── 5. Footer matching Stitch ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '© 2025 SmartClass Inc. All rights reserved.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              Row(
                                children: [
                                  _buildFooterLink('Privacy Policy'),
                                  const SizedBox(width: 20),
                                  _buildFooterLink('Terms of Service'),
                                  const SizedBox(width: 20),
                                  _buildFooterLink('Contact'),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 1: ÉTUDIANT
  // ---------------------------------------------------------------------------
  Widget _buildStudentCard(bool isDark) {
    const roleId = 'student';
    final isSelected = _selectedRole == roleId;
    final isHovered = _hoveredRole == roleId;

    return _buildBaseRoleCard(
      roleId: roleId,
      isSelected: isSelected,
      isHovered: isHovered,
      isDark: isDark,
      badgeText: 'Espace Apprenant',
      badgeIcon: Icons.verified_user_rounded,
      badgeSelectedBg: const Color(0xFF2D3E8C),
      badgeSelectedFg: Colors.white,
      roleIcon: Icons.school_rounded,
      title: 'Étudiant',
      subtitle: 'ACCÈS INDIVIDUEL & PROMOTION',
      description:
          'Apprenez plus vite avec l’assistance d’une IA pédagogique bienveillante et continue.',
      bulletPoints: const [
        'Accès illimité aux cours interactifs & supports multimédias',
        'Tuteur IA interactif 24/7 & explications pas-à-pas',
        'Entraînements, QCM générés & fiches de révision instantanées',
        'Espaces de promotion collaboratifs et salons d’échange',
      ],
      footerLeftIcon: Icons.bolt_rounded,
      footerLeftIconColor: const Color(0xFF0F9D78),
      footerLeftText: 'Prise en main immédiate',
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 2: ENSEIGNANT
  // ---------------------------------------------------------------------------
  Widget _buildTeacherCard(bool isDark) {
    const roleId = 'teacher';
    final isSelected = _selectedRole == roleId;
    final isHovered = _hoveredRole == roleId;

    return _buildBaseRoleCard(
      roleId: roleId,
      isSelected: isSelected,
      isHovered: isHovered,
      isDark: isDark,
      badgeText: 'Espace Pédagogique',
      badgeIcon: Icons.menu_book_rounded,
      badgeSelectedBg: const Color(0xFF2D3E8C),
      badgeSelectedFg: Colors.white,
      roleIcon: Icons.co_present_rounded,
      title: 'Enseignant',
      subtitle: 'PROFESSEUR & FORMATEUR',
      description:
          'Concevez, animez et supervisez vos enseignements avec la puissance de l\'IA.',
      bulletPoints: const [
        'Générateur de cours, QCM et examens assisté par IA',
        'Organisation et animation de classes en direct WebRTC',
        'Analyses de progression, assiduité et alertes d’apprentissage',
        'Correction automatisée avec retours individualisés',
      ],
      footerLeftIcon: Icons.groups_outlined,
      footerLeftIconColor: const Color(0xFF2D3E8C),
      footerLeftText: 'Gestion de cohorte',
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 3: ADMINISTRATEUR
  // ---------------------------------------------------------------------------
  Widget _buildAdminCard(bool isDark) {
    const roleId = 'admin';
    final isSelected = _selectedRole == roleId;
    final isHovered = _hoveredRole == roleId;

    return _buildBaseRoleCard(
      roleId: roleId,
      isSelected: isSelected,
      isHovered: isHovered,
      isDark: isDark,
      badgeText: 'Direction & Supervision',
      badgeIcon: Icons.shield_outlined,
      badgeSelectedBg: const Color(0xFF2D3E8C),
      badgeSelectedFg: Colors.white,
      roleIcon: Icons.admin_panel_settings_rounded,
      title: 'Administrateur',
      subtitle: 'DIRECTION & RÉFÉRENT ENT',
      description:
          'Gérez l\'établissement, la sécurité des épreuves et l\'ensemble des utilisateurs.',
      bulletPoints: const [
        'Gestion centralisée des comptes étudiants et enseignants',
        'Création de classes, affectations et gestion des emplois du temps',
        'Surveillance anti-fraude aux examens & télémétrie certifiée',
        'Synchronisation ENT / LDAP et conformité RGPD intégrée',
      ],
      footerLeftIcon: Icons.badge_outlined,
      footerLeftIconColor: const Color(0xFF2D3E8C),
      footerLeftText: 'Accréditation requise',
    );
  }

  // ---------------------------------------------------------------------------
  // BASE ROLE CARD BUILDER
  // ---------------------------------------------------------------------------
  Widget _buildBaseRoleCard({
    required String roleId,
    required bool isSelected,
    required bool isHovered,
    required bool isDark,
    required String badgeText,
    required IconData badgeIcon,
    required Color badgeSelectedBg,
    required Color badgeSelectedFg,
    required IconData roleIcon,
    required String title,
    required String subtitle,
    required String description,
    required List<String> bulletPoints,
    required IconData footerLeftIcon,
    required Color footerLeftIconColor,
    required String footerLeftText,
  }) {
    final activeBorderColor =
        isDark ? const Color(0xFF6366F1) : const Color(0xFF2D3E8C);
    final defaultBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE2E8F0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredRole = roleId),
      onExit: (_) => setState(() => _hoveredRole = null),
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = roleId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, isHovered ? -3 : 0, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2438) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? activeBorderColor
                  : (isHovered
                      ? activeBorderColor.withValues(alpha: 0.5)
                      : defaultBorderColor),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF2D3E8C).withValues(
                    alpha: isDark ? 0.35 : 0.12,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              else if (isHovered)
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(
                    alpha: isDark ? 0.25 : 0.08,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                )
              else
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(
                    alpha: isDark ? 0.18 : 0.04,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Category Badge on left, Checkmark / Radio on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? badgeSelectedBg
                          : (isDark
                              ? const Color(0xFF263050)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          badgeIcon,
                          size: 13,
                          color: isSelected
                              ? badgeSelectedFg
                              : (isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          badgeText,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                              ? badgeSelectedFg
                              : (isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Circle Indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFF2D3E8C)
                          : (isDark
                              ? const Color(0xFF2A3350)
                              : const Color(0xFFF1F5F9)),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Role Identity Row: Icon square + Title & Subtitle
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF232D4B)
                          : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        roleIcon,
                        size: 26,
                        color: const Color(0xFF2D3E8C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF151B2F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Color(0xFF2D3E8C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Description paragraph
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.4,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF454651),
                ),
              ),
              const SizedBox(height: 18),

              // 4 Bullet Checklist items
              Column(
                children: bulletPoints.map((point) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF232D4B)
                                : const Color(0xFFEEF2FF),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: Color(0xFF2D3E8C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            point,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              height: 1.35,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),
              const SizedBox(height: 8),

              // Hairline separator
              Divider(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF1F5F9),
                height: 1,
              ),
              const SizedBox(height: 14),

              // Footer row: Meta text on left, Status / CTA on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          footerLeftIcon,
                          size: 15,
                          color: footerLeftIconColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            footerLeftText,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSelected ? 'Activé' : 'Choisir ce rôle',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF2D3E8C)
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavLink(String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF454651),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {},
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../../../core/widgets/web_controls_bar.dart';

/// Full-canvas desktop view for Profile Setup & Academic Configuration (Step 2/3),
/// faithfully aligned with the Stitch design specifications.
///
/// Features:
/// - Top navigation bar: SmartClass branding, workflow pill tabs (Profil, Établissement, Configuration Classes, Finalisation),
///   Support & Aide, and user profile badge.
/// - Floating Step Header Card: Step 2 badge, "Finalisation du profil académique", and 66% progress bar with milestones (Compte, Profil IA, Préférences).
/// - Main Content Card:
///   - Left Column: Learner profile avatar preview with camera badge, interactive drag-and-drop photo upload with FilePicker,
///     Webcam & Supprimer buttons, and face verification validation banner.
///   - Right Column: Academic pathway fields (Université, UFR/Département, Niveau d'études, Promotion 2025-2026),
///     interactive subjects of excellence multi-selection chips, and automatic ENT synchronization callout.
/// - Bottom actions row: "Passer cette étape »", "← Retour", and "Enregistrer et continuer →" with SmartLoader.
/// - Security notice (AES-256 & GDPR) and footer.
class WebProfileSetupView extends ConsumerStatefulWidget {
  const WebProfileSetupView({super.key});

  @override
  ConsumerState<WebProfileSetupView> createState() =>
      _WebProfileSetupViewState();
}

class _WebProfileSetupViewState extends ConsumerState<WebProfileSetupView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _institutionController;
  late TextEditingController _facultyController;
  late TextEditingController _promotionController;
  String _selectedLevel = 'Licence 3 (L3) / Bachelor';
  bool _isLoading = false;

  Uint8List? _avatarBytes;
  String? _avatarFileName;
  bool _faceVerified = true;

  late String _activeWorkflowTab;

  final Set<String> _selectedInterests = {
    'Algorithmique & Structures de données',
    'Intelligence Artificielle',
    'Développement Web & Mobile',
    'Bases de Données & SQL',
  };

  static const List<String> _suggestedInterests = [
    'Algorithmique & Structures de données',
    'Intelligence Artificielle',
    'Développement Web & Mobile',
    'Mathématiques Appliquées',
    'Bases de Données & SQL',
    'Réseaux & Sécurité',
    'Systèmes Distribués',
    'Physique Quantique',
    'Machine Learning',
    'Cybersécurité & Cryptographie',
  ];

  static const List<String> _studyLevels = [
    'Licence 1 (L1)',
    'Licence 2 (L2)',
    'Licence 3 (L3) / Bachelor',
    'Master 1 (M1)',
    'Master 2 (M2)',
    'Doctorat / PhD',
    'Cycle d\'Ingénieur',
    'Autre',
  ];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    final user = ref.read(authStateProvider).valueOrNull;
    final isTeacher = user?.role == 'teacher';
    _activeWorkflowTab = isTeacher ? 'Profil Enseignant' : 'Profil Étudiant';

    _institutionController = TextEditingController(
      text: 'Université Mohammed V de Rabat - Faculté des Sciences',
    );
    _facultyController = TextEditingController(
      text: 'Faculté d\'Informatique & Technologies Numériques (FSI)',
    );
    _promotionController = TextEditingController(
      text: 'Promotion 2025 - 2026',
    );

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
    _institutionController.dispose();
    _facultyController.dispose();
    _promotionController.dispose();
    super.dispose();
  }

  void _showFailure(Failure failure) {
    final l10n = failureL10n(failure);
    final translated = context.tr(l10n.key, args: l10n.args);
    final message =
        (translated == l10n.key || translated.isEmpty) ? failure.message : translated;

    context.showErrorToast(message);
  }

  Future<void> _pickImage() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            _avatarBytes = bytes;
            _avatarFileName = file.name;
            _faceVerified = true;
          });
        }
      }
    } catch (_) {
      // Graceful fallback
    }
  }

  void _removeImage() {
    setState(() {
      _avatarBytes = null;
      _avatarFileName = null;
      _faceVerified = false;
    });
  }

  void _openWebcamMock() {
    context.showSuccessToast(
      'Module caméra activé. Cadrage et détection faciale validés avec succès.',
    );
    setState(() {
      _faceVerified = true;
    });
  }

  Future<void> _handleSubmit() async {
    if (_institutionController.text.trim().isEmpty) {
      context.showWarningToast(context.tr('required_field'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authStateProvider.notifier).completeProfile(
            institution: _institutionController.text.trim(),
            faculty: _facultyController.text.trim(),
            major: _selectedLevel,
          );
      if (mounted) {
        context.go('/home');
      }
    } on Failure catch (failure) {
      if (mounted) _showFailure(failure);
    } catch (_) {
      if (mounted) {
        context.showErrorToast(context.tr('error_unexpected'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authStateProvider).valueOrNull;

    final bgColor = isDark ? const Color(0xFF0F1422) : const Color(0xFFFAF8FF);
    final navBgColor = isDark ? const Color(0xFF1E2438) : Colors.white;
    final cardBgColor = isDark ? const Color(0xFF1E2438) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE2E8F0);
    final primaryNavy = const Color(0xFF2D3E8C);

    final roleLabel = user?.role == 'teacher'
        ? 'Onboarding Enseignant'
        : 'Onboarding Étudiant';

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── 1. Top Navbar matching Stitch ──
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: navBgColor,
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Brand logo + text + Bienvenue
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        color: isDark ? Colors.white : primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF252E48)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Bienvenue',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Workflow Pill Tabs (Middle)
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildWorkflowPill(
                          title: _activeWorkflowTab,
                          isActive: true,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _buildWorkflowPill(
                          title: 'Établissement',
                          isActive: false,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _buildWorkflowPill(
                          title: 'Configuration Classes',
                          isActive: false,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _buildWorkflowPill(
                          title: 'Finalisation',
                          isActive: false,
                          isDark: isDark,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Support & Aide, User Badge, Controls (Right)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Support & Aide',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF454651),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // User Badge (Mon Profil / En cours)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252E48)
                        : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFC7D2FE),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D3E8C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mon Profil',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF151B2F),
                            ),
                          ),
                          const Text(
                            'En cours',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F9D78),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),
                const WebControlsBar(),
              ],
            ),
          ],
        ),
      ),

          // ── 2. Scrollable Body Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Sub-header Progress Banner (White elevated card) ──
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 18),
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A)
                                      .withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Step Circle Badge
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: primaryNavy,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryNavy.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '2',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ÉTAPE 2 SUR 3 • $roleLabel',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF4056B9),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Finalisation du profil académique',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                          color: isDark ? Colors.white : const Color(0xFF151B2F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Spacer(),

                                // Progress tracker column
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Progression globale',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '66%',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: primaryNavy,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 250,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: 0.66,
                                          minHeight: 6,
                                          backgroundColor: isDark
                                              ? const Color(0xFF252E48)
                                              : const Color(0xFFE2E8F0),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            primaryNavy,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 13,
                                          color: Color(0xFF0F9D78),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Compte',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F9D78),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          'Profil IA',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: primaryNavy,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          'Préférences',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Main Content Card (Two-column layout) ──
                          Container(
                            padding: const EdgeInsets.all(36),
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A)
                                      .withValues(alpha: 0.05),
                                  blurRadius: 28,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Card Top Header: Badge, Title & LMD Certified Container
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Pill capsule badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 5),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF252E48)
                                                    : const Color(0xFFEEF2FF),
                                                borderRadius:
                                                    BorderRadius.circular(9999),
                                                border: Border.all(
                                                  color: isDark
                                                      ? const Color(0xFF4056B9)
                                                      : const Color(0xFFC7D2FE),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.psychology_rounded,
                                                    size: 15,
                                                    color: primaryNavy,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Modèle d\'Apprentissage Personnalisé',
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: primaryNavy,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Configuration de votre profil',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 26,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.5,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF151B2F),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Complétez vos informations académiques afin que notre IA personnalise vos synthèses de cours, tuteurs virtuels et recommandations de modules.',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14,
                                                height: 1.45,
                                                color: isDark
                                                    ? const Color(0xFFCBD5E1)
                                                    : const Color(0xFF454651),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      // Right Top: Identité Certifiée container
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF252E48)
                                              : const Color(0xFFF0F4FF),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.1)
                                                : const Color(0xFFDBEAFE),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.verified_user_outlined,
                                              size: 26,
                                              color: primaryNavy,
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Identité Certifiée',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(0xFF151B2F),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Conforme protocole LMD',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark
                                                        ? const Color(0xFF94A3B8)
                                                        : const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 32),

                                  // Two Columns
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isWide = constraints.maxWidth > 780;
                                      if (isWide) {
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Left Column (~38%)
                                            Expanded(
                                              flex: 38,
                                              child: _buildLeftColumn(
                                                  isDark: isDark,
                                                  primaryNavy: primaryNavy),
                                            ),
                                            const SizedBox(width: 36),
                                            // Right Column (~62%)
                                            Expanded(
                                              flex: 62,
                                              child: _buildRightColumn(
                                                  isDark: isDark,
                                                  primaryNavy: primaryNavy),
                                            ),
                                          ],
                                        );
                                      } else {
                                        return Column(
                                          children: [
                                            _buildLeftColumn(
                                                isDark: isDark,
                                                primaryNavy: primaryNavy),
                                            const SizedBox(height: 32),
                                            _buildRightColumn(
                                                isDark: isDark,
                                                primaryNavy: primaryNavy),
                                          ],
                                        );
                                      }
                                    },
                                  ),

                                  const SizedBox(height: 36),
                                  Divider(color: borderColor, height: 1),
                                  const SizedBox(height: 24),

                                  // Bottom Actions Row
                                  Row(
                                    children: [
                                      // Passer cette étape
                                      TextButton(
                                        onPressed: () {
                                          context.go('/home');
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                          textStyle: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        child: const Text('Passer cette étape »'),
                                      ),

                                      const Spacer(),

                                      // Retour
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          if (context.canPop()) {
                                            context.pop();
                                          } else {
                                            context.go('/role-selection');
                                          }
                                        },
                                        icon: const Icon(
                                            Icons.arrow_back_rounded,
                                            size: 16),
                                        label: const Text('Retour'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isDark
                                              ? Colors.white
                                              : const Color(0xFF151B2F),
                                          side: BorderSide(color: borderColor),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 14),
                                          textStyle: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 14),

                                      // Enregistrer et continuer
                                      FilledButton(
                                        onPressed:
                                            _isLoading ? null : _handleSubmit,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: primaryNavy,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 14),
                                          elevation: 2,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: SmartLoader.small(
                                                    color: Colors.white),
                                              )
                                            : const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Enregistrer et continuer',
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                      Icons.arrow_forward_rounded,
                                                      size: 16),
                                                ],
                                              ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Security Bar ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Chiffrement AES-256 • Vos données d\'inscription sont strictement protégées et conformes au RGPD académique européen. • Modifiable à tout moment dans vos Paramètres.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.5,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // ── Footer ──
                          Divider(color: borderColor, height: 1),
                          const SizedBox(height: 20),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 10,
                            children: [
                              Text(
                                '© 2025 SmartClass Inc. Tous droits réservés. Plateforme éducative sécurisée.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildFooterLink('Centre d\'Assistance', () {}),
                                  const SizedBox(width: 14),
                                  const Text('•',
                                      style: TextStyle(color: Color(0xFF94A3B8))),
                                  const SizedBox(width: 14),
                                  _buildFooterLink('Confidentialité', () {}),
                                  const SizedBox(width: 14),
                                  const Text('•',
                                      style: TextStyle(color: Color(0xFF94A3B8))),
                                  const SizedBox(width: 14),
                                  _buildFooterLink(
                                      'Conditions d\'Utilisation', () {}),
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

  // ─────────────────────────────────────────────────────────
  // LEFT COLUMN: Avatar Preview & Drag-and-Drop Photo Upload
  // ─────────────────────────────────────────────────────────
  Widget _buildLeftColumn({
    required bool isDark,
    required Color primaryNavy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Row(
          children: [
            Icon(Icons.camera_alt_outlined, size: 18, color: primaryNavy),
            const SizedBox(width: 8),
            Text(
              'Photo de profil apprenant',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF151B2F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Utilisée pour le trombinoscope interactif et la validation des épreuves supervisées.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            height: 1.4,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 20),

        // Big Circular Avatar Preview
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF252E48)
                      : const Color(0xFFEEF2FF),
                  border: Border.all(
                    color: primaryNavy.withValues(alpha: 0.2),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _avatarBytes != null
                      ? Image.memory(
                          _avatarBytes!,
                          fit: BoxFit.cover,
                          width: 128,
                          height: 128,
                        )
                      : Image.asset(
                          'assets/images/student_avatar.png',
                          fit: BoxFit.cover,
                          width: 128,
                          height: 128,
                          errorBuilder: (ctx, err, stack) => Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 64,
                              color: primaryNavy.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: primaryNavy,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E2438) : Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryNavy.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Drag & Drop Upload Zone
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151B2F) : const Color(0xFFFAF8FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF4056B9).withValues(alpha: 0.4)
                    : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252E48)
                        : const Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    color: primaryNavy,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF151B2F),
                    ),
                    children: [
                      const TextSpan(text: 'Glissez votre photo ici ou '),
                      TextSpan(
                        text: 'Parcourir',
                        style: TextStyle(
                          color: primaryNavy,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _avatarFileName != null
                      ? 'Fichier sélectionné : $_avatarFileName'
                      : 'Format JPG, PNG ou WebP. Max 5 Mo. Recommandé : photo de face nette pour l\'identification sécurisée aux épreuves.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Action Buttons Row: Webcam & Supprimer
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openWebcamMock,
                icon: Icon(Icons.videocam_outlined,
                    size: 16, color: primaryNavy),
                label: Text(
                  'Webcam',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryNavy,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF4056B9).withValues(alpha: 0.5)
                        : const Color(0xFFCBD5E1),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: Color(0xFFDC2626)),
                label: const Text(
                  'Supprimer',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF3B1F2B)
                      : const Color(0xFFFEF2F2),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF7F1D1D)
                        : const Color(0xFFFCA5A5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Face Detection Validation Box
        if (_faceVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132E27) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF0F9D78)
                    : const Color(0xFFA7F3D0),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Détection du visage validée : éclairage et cadrage optimaux pour le badge d\'examen.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: isDark
                          ? const Color(0xFF65DBB2)
                          : const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // RIGHT COLUMN: Academic Form Fields & Subject Chips
  // ─────────────────────────────────────────────────────────
  Widget _buildRightColumn({
    required bool isDark,
    required Color primaryNavy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title Row
        Row(
          children: [
            Icon(Icons.school_outlined, size: 20, color: primaryNavy),
            const SizedBox(width: 8),
            Text(
              'Parcours académique',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF151B2F),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF252E48)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'REQUIS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Field 1: Université / Établissement d'enseignement supérieur
        _buildFieldLabel(
          label: 'Université / Établissement d\'enseignement supérieur',
          isDark: isDark,
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _institutionController,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF151B2F),
          ),
          decoration: _buildInputDecoration(
            hintText: 'ex: Université Mohammed V de Rabat - Faculté des Sciences',
            prefixIcon: Icons.account_balance_outlined,
            suffixIcon: Icons.keyboard_arrow_down_rounded,
            isDark: isDark,
            primaryNavy: primaryNavy,
          ),
        ),

        const SizedBox(height: 16),

        // Field 2: UFR / Département ou Faculté
        _buildFieldLabel(
          label: 'UFR / Département ou Faculté',
          isDark: isDark,
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _facultyController,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF151B2F),
          ),
          decoration: _buildInputDecoration(
            hintText: 'ex: Faculté d\'Informatique & Technologies Numériques (FSI)',
            prefixIcon: Icons.account_tree_outlined,
            isDark: isDark,
            primaryNavy: primaryNavy,
          ),
        ),

        const SizedBox(height: 16),

        // Dual Row: Niveau d'études actuel & Année universitaire / Promotion
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Niveau d'études
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(
                    label: 'Niveau d\'études actuel',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLevel,
                    isExpanded: true,
                    dropdownColor: isDark
                        ? const Color(0xFF1E2438)
                        : Colors.white,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF151B2F),
                    ),
                    decoration: _buildInputDecoration(
                      hintText: 'Sélectionnez',
                      prefixIcon: Icons.workspace_premium_outlined,
                      isDark: isDark,
                      primaryNavy: primaryNavy,
                    ),
                    items: _studyLevels.map((lvl) {
                      return DropdownMenuItem<String>(
                        value: lvl,
                        child: Text(
                          lvl,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLevel = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Right: Année universitaire / Promotion
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(
                    label: 'Année universitaire / Promotion',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _promotionController,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF151B2F),
                    ),
                    decoration: _buildInputDecoration(
                      hintText: 'ex: Promotion 2025 - 2026',
                      prefixIcon: Icons.calendar_today_outlined,
                      isDark: isDark,
                      primaryNavy: primaryNavy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Section: Spécialités & Matières d'excellence
        Row(
          children: [
            Icon(Icons.hub_outlined, size: 16, color: primaryNavy),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Spécialités & Matières d\'excellence',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF151B2F),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Sélectionnez au moins 3 matières',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Permet de calibrer le niveau de difficulté des exercices auto-générés et les synthèses hebdomadaires.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),

        // Interactive Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedInterests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
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
              borderRadius: BorderRadius.circular(9999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryNavy
                      : (isDark
                          ? const Color(0xFF252E48)
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: isSelected
                        ? primaryNavy
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE2E8F0)),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryNavy.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_rounded : Icons.add_rounded,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      interest,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF151B2F)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 22),

        // ENT Synchronization Callout Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF15203A) : const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF4056B9).withValues(alpha: 0.4)
                  : const Color(0xFFDBEAFE),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: primaryNavy,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Synchronisation ENT automatique',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'En validant votre établissement, vos cours officiels, syllabus et plannings d\'examens seront synchronisés avec votre messagerie universitaire dès la finalisation.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        height: 1.45,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Helper Widgets
  // ─────────────────────────────────────────────────────────
  Widget _buildFieldLabel({
    required String label,
    required bool isDark,
  }) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF151B2F),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    required bool isDark,
    required Color primaryNavy,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF151B2F) : Colors.white,
      prefixIcon: Icon(prefixIcon, size: 18, color: primaryNavy),
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon,
              size: 20,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B))
          : null,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFCBD5E1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryNavy, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.8),
      ),
    );
  }

  Widget _buildWorkflowPill({
    required String title,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2D3E8C)
              : (isDark ? const Color(0xFF1E2438) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

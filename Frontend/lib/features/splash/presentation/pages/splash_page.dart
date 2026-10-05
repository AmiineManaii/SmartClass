import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/localization/app_localizations.dart';

/// Un écran de démarrage (Splash Screen) prestigieux, sobre et professionnel,
/// directement inspiré du nouveau logo SmartClass (Livre ouvert + Réseau IA + Étoile dorée).
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  // Contrôleurs d'animation
  late AnimationController _ambientController;
  late AnimationController _sequenceController;
  late AnimationController _exitController;

  // Animations échelonnées de révélation
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _starGleam;
  late Animation<double> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _taglineFade;
  late Animation<double> _progressValue;

  bool _isNavigatingAway = false;
  int _statusIndex = 0;

  @override
  void initState() {
    super.initState();

    // 1. Respiration douce et flottement subtil (ambiance continue)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    // 2. Séquence principale de révélation sobre et fluide (2.2 secondes)
    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // 3. Transition de sortie vers l'écran d'accueil/login
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // ── Échelonnement des animations du logo ──
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.05, 0.48, curve: Curves.easeOutCubic),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _starGleam = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.40, 0.70, curve: Curves.easeOutBack),
      ),
    );

    _titleSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.35, 0.60, curve: Curves.easeOut),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.50, 0.75, curve: Curves.easeOut),
      ),
    );

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.15, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    // Mise à jour de l'indicateur d'état textuel
    _sequenceController.addListener(() {
      final v = _progressValue.value;
      final newIndex = v < 0.4
          ? 0
          : v < 0.75
              ? 1
              : 2;
      if (newIndex != _statusIndex && mounted) {
        setState(() => _statusIndex = newIndex);
      }
    });

    // Navigation automatique
    _sequenceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completeAndNavigate();
      }
    });

    _sequenceController.forward();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _sequenceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _completeAndNavigate() {
    if (_isNavigatingAway || !mounted) return;
    _isNavigatingAway = true;

    _exitController.forward().then((_) {
      if (!mounted) return;
      ref.read(hasSeenSplashProvider.notifier).state = true;
      final auth = ref.read(authStateProvider).value;
      final isLoggedIn = auth?.isAuthenticated ?? false;
      final completed = auth?.onboardingCompleted ?? false;

      if (!isLoggedIn) {
        context.go('/login');
      } else if (!completed) {
        context.go('/role-selection');
      } else {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    // Couleurs nobles inspirées du logo
    final bgColor = isDark ? const Color(0xFF090E17) : const Color(0xFFF8FAFC);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0C2B4E);
    const navyDeep = Color(0xFF0C2B4E);
    const accentTeal = Color(0xFF127494);
    const starGold = Color(0xFFDF9F35);

    final statusMessages = [
      context.tr('splash_loading_1'),
      context.tr('splash_loading_2'),
      context.tr('splash_loading_3'),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: _completeAndNavigate,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _ambientController,
            _sequenceController,
            _exitController,
          ]),
          builder: (context, child) {
            final exitProgress = _exitController.value;
            final exitScale = 1.0 + (exitProgress * 0.08);
            final exitOpacity = 1.0 - exitProgress;
            final ambientVal = _ambientController.value;
            final floatOffset = math.sin(ambientVal * math.pi) * 6.0;

            return Transform.scale(
              scale: exitScale,
              child: Opacity(
                opacity: exitOpacity.clamp(0.0, 1.0),
                child: Stack(
                  children: [
                    // 1. Fond épuré avec lueur douce centrée
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.15),
                            radius: 1.0,
                            colors: [
                              isDark
                                  ? const Color(0xFF132238)
                                  : const Color(0xFFE6EEF5),
                              bgColor,
                            ],
                            stops: const [0.0, 0.85],
                          ),
                        ),
                      ),
                    ),

                    // 2. Bouton "Passer" sobre
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 16,
                      right: 20,
                      child: FadeTransition(
                        opacity: _taglineFade,
                        child: TextButton(
                          onPressed: _completeAndNavigate,
                          style: TextButton.styleFrom(
                            foregroundColor: primaryTextColor.withValues(alpha: 0.6),
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.tr('skip'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryTextColor.withValues(alpha: 0.65),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: primaryTextColor.withValues(alpha: 0.65),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. Cœur visuel : Logo + Typographie
                    Center(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ── Le Nouveau Logo Animé ──
                              Transform.translate(
                                offset: Offset(0, -floatOffset),
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: Opacity(
                                    opacity: _logoFade.value,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Ombre portée sous le logo
                                        Positioned(
                                          bottom: -8,
                                          child: Container(
                                            width: 110,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF0C2B4E).withValues(
                                                    alpha: isDark ? 0.45 : 0.12 + (ambientVal * 0.05),
                                                  ),
                                                  blurRadius: 28,
                                                  spreadRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Image officielle du logo transparent
                                        SizedBox(
                                          width: 140,
                                          height: 140,
                                          child: Image.asset(
                                            'assets/images/logo_emblem.png',
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              Icons.school_rounded,
                                              size: 72,
                                              color: navyDeep,
                                            ),
                                          ),
                                        ),

                                        // Étincelle dorée scintillante sur l'étoile
                                        Positioned(
                                          top: 8,
                                          right: 28,
                                          child: Transform.scale(
                                            scale: _starGleam.value,
                                            child: Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: starGold.withValues(
                                                      alpha: 0.6 * _starGleam.value,
                                                    ),
                                                    blurRadius: 16,
                                                    spreadRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.auto_awesome,
                                                  size: 14,
                                                  color: starGold.withValues(alpha: 0.9),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // ── Titre "SmartClass" ──
                              Transform.translate(
                                offset: Offset(0, _titleSlide.value),
                                child: Opacity(
                                  opacity: _titleFade.value,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Smart',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 34,
                                            fontWeight: FontWeight.w800,
                                            color: primaryTextColor,
                                            letterSpacing: -0.6,
                                          ),
                                        ),
                                        const Text(
                                          'Class',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 34,
                                            fontWeight: FontWeight.w800,
                                            color: accentTeal,
                                            letterSpacing: -0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // ── Tagline sobre et professionnelle ──
                              Opacity(
                                opacity: _taglineFade.value,
                                child: Text(
                                  context.tr('splash_tagline'),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                    color: primaryTextColor.withValues(alpha: 0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 44),

                              // ── Barre de progression élégante ──
                              Opacity(
                                opacity: _titleFade.value,
                                child: SizedBox(
                                  width: (size.width * 0.55).clamp(180.0, 240.0),
                                  child: Column(
                                    children: [
                                      // Rail fin
                                      Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : Colors.black.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          width: (size.width * 0.55).clamp(180.0, 240.0) *
                                              _progressValue.value,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(2),
                                            gradient: const LinearGradient(
                                              colors: [
                                                accentTeal,
                                                Color(0xFF0C2B4E),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Message d'état discret
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 250),
                                        child: Text(
                                          statusMessages[_statusIndex.clamp(
                                              0, statusMessages.length - 1)],
                                          key: ValueKey<String>(
                                            statusMessages[_statusIndex.clamp(
                                                0, statusMessages.length - 1)],
                                          ),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: primaryTextColor.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 4. Mention en bas
                    Positioned(
                      bottom: MediaQuery.paddingOf(context).bottom + 16,
                      left: 0,
                      right: 0,
                      child: FadeTransition(
                        opacity: _taglineFade,
                        child: Center(
                          child: Text(
                            "SmartClass Platform • v1.0",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              color: primaryTextColor.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

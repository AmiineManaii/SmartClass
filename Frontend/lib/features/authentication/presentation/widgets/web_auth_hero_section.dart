import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_theme.dart';

/// Données d'une diapositive motivante et vivante pour le volet Hero étudiant.
class _HeroSlideData {
  final IconData badgeIcon;
  final String badgeTextFr;
  final String badgeTextEn;
  final String titleFr;
  final String titleEn;
  final String subtitleFr;
  final String subtitleEn;

  final IconData cardIcon;
  final String cardTitleFr;
  final String cardTitleEn;
  final String cardSubtitleFr;
  final String cardSubtitleEn;
  final String cardPillFr;
  final String cardPillEn;

  final String stat1Value;
  final String stat1LabelFr;
  final String stat1LabelEn;
  final String stat1Trend;

  final String stat2Value;
  final String stat2LabelFr;
  final String stat2LabelEn;
  final String stat2SpeedFr;
  final String stat2SpeedEn;

  final String footerUserFr;
  final String footerUserEn;
  final String footerStatusFr;
  final String footerStatusEn;

  final String quoteFr;
  final String quoteEn;
  final String authorFr;
  final String authorEn;

  const _HeroSlideData({
    required this.badgeIcon,
    required this.badgeTextFr,
    required this.badgeTextEn,
    required this.titleFr,
    required this.titleEn,
    required this.subtitleFr,
    required this.subtitleEn,
    required this.cardIcon,
    required this.cardTitleFr,
    required this.cardTitleEn,
    required this.cardSubtitleFr,
    required this.cardSubtitleEn,
    required this.cardPillFr,
    required this.cardPillEn,
    required this.stat1Value,
    required this.stat1LabelFr,
    required this.stat1LabelEn,
    required this.stat1Trend,
    required this.stat2Value,
    required this.stat2LabelFr,
    required this.stat2LabelEn,
    required this.stat2SpeedFr,
    required this.stat2SpeedEn,
    required this.footerUserFr,
    required this.footerUserEn,
    required this.footerStatusFr,
    required this.footerStatusEn,
    required this.quoteFr,
    required this.quoteEn,
    required this.authorFr,
    required this.authorEn,
  });
}

/// Volet de présentation Hero animé pour les pages Web de Connexion / Inscription.
/// Comprend un arrière-plan vivant (ondes aurorales & orbes mouvants) et
/// un carrousel automatique de diapositives motivantes conçues spécialement pour les étudiants.
class WebAuthHeroSection extends ConsumerStatefulWidget {
  final bool isDark;

  const WebAuthHeroSection({
    super.key,
    required this.isDark,
  });

  @override
  ConsumerState<WebAuthHeroSection> createState() => _WebAuthHeroSectionState();
}

class _WebAuthHeroSectionState extends ConsumerState<WebAuthHeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ambientController;
  Timer? _carouselTimer;
  int _currentSlideIndex = 0;
  bool _slideForward = true;

  static const List<_HeroSlideData> _slides = [
    // Slide 1: Plateforme Intelligente & Réussite
    _HeroSlideData(
      badgeIcon: Icons.verified_rounded,
      badgeTextFr: 'Environnement Numérique de Travail 4.0',
      badgeTextEn: 'Digital Learning Environment 4.0',
      titleFr: 'Plateforme intelligente &\ncollaborative d\'apprentissage',
      titleEn: 'Intelligent & Collaborative\nLearning Platform',
      subtitleFr:
          'Connectez étudiants, enseignants et administration au sein d\'un écosystème académique unifié propulsé par l\'IA pédagogique.',
      subtitleEn:
          'Connect students, faculty, and administration within a unified academic ecosystem powered by educational AI.',
      cardIcon: Icons.analytics_rounded,
      cardTitleFr: 'Suivi de Cohorte en Direct',
      cardTitleEn: 'Live Cohort Tracking',
      cardSubtitleFr: 'Session active • Amphi Ada Lovelace',
      cardSubtitleEn: 'Active session • Ada Lovelace Hall',
      cardPillFr: '98.8% Intégrité IA',
      cardPillEn: '98.8% AI Integrity',
      stat1Value: '1,250',
      stat1LabelFr: 'Étudiants connectés',
      stat1LabelEn: 'Connected Students',
      stat1Trend: '+14% vs. semaine',
      stat2Value: '842',
      stat2LabelFr: 'Évaluations corrigées',
      stat2LabelEn: 'Graded Evaluations',
      stat2SpeedFr: '4.2 sec / copie',
      stat2SpeedEn: '4.2 sec / paper',
      footerUserFr: 'Salma & Prof. Amine • En session',
      footerUserEn: 'Salma & Prof. Amine • In session',
      footerStatusFr: 'Proctoring Actif',
      footerStatusEn: 'Proctoring Active',
      quoteFr:
          '« SmartClass a réduit de 70% le temps de notation et éliminé le plagiat lors des soutenances numériques. »',
      quoteEn:
          '“SmartClass reduced grading time by 70% and eliminated plagiarism during digital thesis defenses.”',
      authorFr: '— Direction Pédagogique • Faculté d\'Informatique',
      authorEn: '— Academic Board • Faculty of Computer Science',
    ),

    // Slide 2: Motivation Étudiante & Tuteur IA (Directement pour les étudiants!)
    _HeroSlideData(
      badgeIcon: Icons.auto_awesome_rounded,
      badgeTextFr: 'Tutorat Intelligent 24/7 • Révisions IA',
      badgeTextEn: '24/7 AI Tutoring • Smart Revision',
      titleFr: 'Chaque étudiant a le potentiel\nd\'exceller et de réussir',
      titleEn: 'Every student has the power\nto excel and succeed at the top',
      subtitleFr:
          'Un copilote d\'apprentissage adaptatif qui personnalise vos synthèses, clarifie vos questions et propulse vos notes vers les sommets.',
      subtitleEn:
          'An adaptive AI study copilot that personalizes your summaries, clarifies questions, and drives your grades to the top.',
      cardIcon: Icons.psychology_rounded,
      cardTitleFr: 'Parcours d\'Apprentissage Adaptatif',
      cardTitleEn: 'Adaptive Learning Path',
      cardSubtitleFr: 'Quiz interactifs & synthèses sur-mesure',
      cardSubtitleEn: 'Interactive quizzes & tailored recaps',
      cardPillFr: '96.4% Taux de Réussite',
      cardPillEn: '96.4% Success Rate',
      stat1Value: '+3.8 pts',
      stat1LabelFr: 'Moyenne de Promotion',
      stat1LabelEn: 'Cohort Average Boost',
      stat1Trend: 'Progression continue',
      stat2Value: '< 1.2s',
      stat2LabelFr: 'Temps de Réponse IA',
      stat2LabelEn: 'AI Response Time',
      stat2SpeedFr: 'Assistance instantanée',
      stat2SpeedEn: 'Instant guidance',
      footerUserFr: 'Yassine & 480 étudiants • Révision active',
      footerUserEn: 'Yassine & 480 students • Active revision',
      footerStatusFr: 'Copilote IA Prêt',
      footerStatusEn: 'AI Copilot Ready',
      quoteFr:
          '« Les fiches de révision instantanées et les quiz guidés par l\'IA m\'ont permis de décrocher ma mention Très Bien sans stress ! »',
      quoteEn:
          '“Instant revision flashcards and AI quizzes helped me achieve Highest Honors with total confidence!”',
      authorFr: '— Yassine B. • Étudiant en Master Génie Logiciel',
      authorEn: '— Yassine B. • Master Software Engineering Student',
    ),

    // Slide 3: Campus Collaboratif & Avenir
    _HeroSlideData(
      badgeIcon: Icons.groups_rounded,
      badgeTextFr: 'Campus Connecté & Esprit d\'Équipe',
      badgeTextEn: 'Connected Campus & Team Spirit',
      titleFr: 'Apprenez, partagez et bâtissez\nvotre avenir ensemble',
      titleEn: 'Learn together, share,\nand build your future career',
      subtitleFr:
          'Collaborez en direct sur vos projets, échangez avec vos professeurs et développez des compétences concrètes pour votre future carrière.',
      subtitleEn:
          'Collaborate live on team projects, connect with your professors, and build real-world skills for your future career.',
      cardIcon: Icons.hub_rounded,
      cardTitleFr: 'Espaces Projets & Laboratoires',
      cardTitleEn: 'Project Hubs & Virtual Labs',
      cardSubtitleFr: 'Ateliers collaboratifs & amphis virtuels',
      cardSubtitleEn: 'Interactive workshops & virtual lecture halls',
      cardPillFr: '100% Certifié ISO',
      cardPillEn: '100% ISO Certified',
      stat1Value: '48',
      stat1LabelFr: 'Enseignants-Chercheurs',
      stat1LabelEn: 'Faculty Mentors',
      stat1Trend: 'Disponibles 7j/7',
      stat2Value: '18',
      stat2LabelFr: 'Classes Collaboratives',
      stat2LabelEn: 'Virtual Classrooms',
      stat2SpeedFr: 'Travaux dirigés interactifs',
      stat2SpeedEn: 'Live team sessions',
      footerUserFr: 'Sarah & Délégués • Espace de travail',
      footerUserEn: 'Sarah & Class Reps • Workspace',
      footerStatusFr: 'Écosystème Sécurisé',
      footerStatusEn: 'Secure Ecosystem',
      quoteFr:
          '« SmartClass réinvente nos études : un espace vivant, stimulant et profondément motivant où chaque effort est récompensé. »',
      quoteEn:
          '“SmartClass reimagines university life: a vibrant, motivating space where every effort is recognized and celebrated.”',
      authorFr: '— Sarah Benali • Déléguée de Promotion 2026',
      authorEn: '— Sarah Benali • Student Body Representative 2026',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Animation continue douce pour les orbes et lueurs
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7500),
    )..repeat();

    _resetTimer();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _nextSlide() {
    setState(() {
      _slideForward = true;
      _currentSlideIndex = (_currentSlideIndex + 1) % _slides.length;
    });
    _resetTimer();
  }

  void _prevSlide() {
    setState(() {
      _slideForward = false;
      _currentSlideIndex =
          (_currentSlideIndex - 1 + _slides.length) % _slides.length;
    });
    _resetTimer();
  }

  void _goToSlide(int index) {
    if (index == _currentSlideIndex) return;
    setState(() {
      _slideForward = index > _currentSlideIndex;
      _currentSlideIndex = index;
    });
    _resetTimer();
  }

  void _resetTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(milliseconds: 5500), (_) {
      if (mounted) {
        _nextSlide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isFr = currentLocale == 'fr';
    final slide = _slides[_currentSlideIndex];

    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, _) {
        final theta = _ambientController.value * 2 * math.pi;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                -1.0 + 0.18 * math.cos(theta),
                -1.0 + 0.18 * math.sin(theta),
              ),
              end: Alignment(
                1.0 - 0.18 * math.cos(theta),
                1.0 - 0.18 * math.sin(theta),
              ),
              colors: widget.isDark
                  ? const [
                      Color(0xFF060D1E),
                      Color(0xFF0E1A38),
                      Color(0xFF060B16),
                    ]
                  : const [
                      Color(0xFF0F2266),
                      Color(0xFF1F378D),
                      Color(0xFF0C194F),
                    ],
            ),
          ),
          child: Stack(
            children: [
              // ── 1. Arrière-plan animé avec orbes vivants, ondes aurorales et poussière d'étoiles ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _LivingHeroPainter(
                    animationValue: _ambientController.value,
                    isDark: widget.isDark,
                  ),
                ),
              ),

              // ── 2. Contenu principal avec défilement sécurisé ──
              Positioned.fill(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 44,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête de marque permanent
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.16),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/images/logo_emblem.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(
                                        Icons.school_rounded,
                                        color: AppTheme.primary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SmartClass',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      Text(
                                        'EDTECH • AI ASSISTED',
                                        style: TextStyle(
                                          color: AppTheme.onPrimaryContainer,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  isFr ? 'SaaS Éducation & IA' : 'SaaS Education & AI',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Carrousel de diapositives avec swipe animé cinématique
                          ClipRect(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.grab,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onHorizontalDragEnd: (details) {
                                  final velocity = details.primaryVelocity ?? 0;
                                  if (velocity < -120) {
                                    _nextSlide();
                                  } else if (velocity > 120) {
                                    _prevSlide();
                                  }
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 650),
                                  switchInCurve: Curves.easeInOutCubic,
                                  switchOutCurve: Curves.easeInOutCubic,
                                  layoutBuilder: (currentChild, previousChildren) {
                                    return Stack(
                                      alignment: Alignment.topLeft,
                                      children: [
                                        ...previousChildren,
                                        ?currentChild,
                                      ],
                                    );
                                  },
                                  transitionBuilder: (child, animation) {
                                    final isIncoming = (child.key as ValueKey<int>?)?.value ==
                                        _currentSlideIndex;
                                    final beginOffset = isIncoming
                                        ? (_slideForward
                                            ? const Offset(1.0, 0.0)
                                            : const Offset(-1.0, 0.0))
                                        : (_slideForward
                                            ? const Offset(-1.0, 0.0)
                                            : const Offset(1.0, 0.0));

                                    final slideAnim = Tween<Offset>(
                                      begin: beginOffset,
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOutCubic,
                                    ));

                                    final scaleAnim = Tween<double>(
                                      begin: 0.94,
                                      end: 1.0,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOutCubic,
                                    ));

                                    return SlideTransition(
                                      position: slideAnim,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: ScaleTransition(
                                          scale: scaleAnim,
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: KeyedSubtree(
                                    key: ValueKey<int>(_currentSlideIndex),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Badge de diapositive
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(18),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  slide.badgeIcon,
                                                  color: AppTheme.tertiaryFixed,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  isFr
                                                      ? slide.badgeTextFr
                                                      : slide.badgeTextEn,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // Titre animé
                                          Text(
                                            isFr ? slide.titleFr : slide.titleEn,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 27,
                                              fontWeight: FontWeight.w800,
                                              height: 1.22,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 10),

                                          // Sous-titre
                                          Text(
                                            isFr
                                                ? slide.subtitleFr
                                                : slide.subtitleEn,
                                            style: const TextStyle(
                                              color: AppTheme.onPrimaryContainer,
                                              fontSize: 13,
                                              height: 1.45,
                                            ),
                                          ),

                                          const SizedBox(height: 20),

                                          // Carte Métrique Vivante
                                          Container(
                                            padding: const EdgeInsets.all(18),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: widget.isDark ? 0.09 : 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: widget.isDark ? 0.20 : 0.26,
                                                ),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.20),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 32,
                                                            height: 32,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: AppTheme
                                                                  .secondary
                                                                  .withValues(
                                                                      alpha: 0.4),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(8),
                                                            ),
                                                            child: Icon(
                                                              slide.cardIcon,
                                                              color: AppTheme
                                                                  .tertiaryFixed,
                                                              size: 18,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  isFr
                                                                      ? slide
                                                                          .cardTitleFr
                                                                      : slide
                                                                          .cardTitleEn,
                                                                  style:
                                                                      const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        12.5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  isFr
                                                                      ? slide
                                                                          .cardSubtitleFr
                                                                      : slide
                                                                          .cardSubtitleEn,
                                                                  style:
                                                                      const TextStyle(
                                                                    color: AppTheme
                                                                        .onPrimaryContainer,
                                                                    fontSize:
                                                                        10.5,
                                                                  ),
                                                                ),
                                                                ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme
                                                            .tertiaryContainer,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: Text(
                                                        isFr
                                                            ? slide.cardPillFr
                                                            : slide.cardPillEn,
                                                        style: const TextStyle(
                                                          color: AppTheme
                                                              .tertiaryFixed,
                                                          fontSize: 9.5,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),

                                                // Statistiques
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                                10),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withValues(
                                                                  alpha: 0.08),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              isFr
                                                                  ? slide
                                                                      .stat1LabelFr
                                                                  : slide
                                                                      .stat1LabelEn,
                                                              style:
                                                                  const TextStyle(
                                                                color: AppTheme
                                                                    .onPrimaryContainer,
                                                                fontSize: 10.5,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 4),
                                                            Text(
                                                              slide.stat1Value,
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 2),
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .trending_up_rounded,
                                                                  color: AppTheme
                                                                      .tertiaryFixed,
                                                                  size: 13,
                                                                ),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  slide.stat1Trend,
                                                                  style:
                                                                      const TextStyle(
                                                                    color: AppTheme
                                                                        .tertiaryFixed,
                                                                    fontSize:
                                                                        9.5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                                10),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withValues(
                                                                  alpha: 0.08),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              isFr
                                                                  ? slide
                                                                      .stat2LabelFr
                                                                  : slide
                                                                      .stat2LabelEn,
                                                              style:
                                                                  const TextStyle(
                                                                color: AppTheme
                                                                    .onPrimaryContainer,
                                                                fontSize: 10.5,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 4),
                                                            Text(
                                                              slide.stat2Value,
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 2),
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .bolt_rounded,
                                                                  color: AppTheme
                                                                      .secondaryContainer,
                                                                  size: 13,
                                                                ),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Expanded(
                                                                  child: Text(
                                                                    isFr
                                                                        ? slide
                                                                            .stat2SpeedFr
                                                                        : slide
                                                                            .stat2SpeedEn,
                                                                    maxLines: 1,
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style:
                                                                        const TextStyle(
                                                                      color: AppTheme
                                                                          .secondaryContainer,
                                                                      fontSize:
                                                                          9.5,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),

                                                // Ligne de statut bas de carte
                                                Wrap(
                                                  alignment: WrapAlignment
                                                      .spaceBetween,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: [
                                                    Text(
                                                      isFr
                                                          ? slide.footerUserFr
                                                          : slide.footerUserEn,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .verified_user_rounded,
                                                          color: AppTheme
                                                              .tertiaryFixed,
                                                          size: 13,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          isFr
                                                              ? slide
                                                                  .footerStatusFr
                                                              : slide
                                                                  .footerStatusEn,
                                                          style:
                                                              const TextStyle(
                                                            color: AppTheme
                                                                .tertiaryFixed,
                                                            fontSize: 10.5,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(height: 14),

                                          // Carte Témoignage Académique / Étudiant
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.05),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.format_quote_rounded,
                                                  color: AppTheme.tertiaryFixed,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        isFr
                                                            ? slide.quoteFr
                                                            : slide.quoteEn,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11.5,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          height: 1.35,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        isFr
                                                            ? slide.authorFr
                                                            : slide.authorEn,
                                                        style: const TextStyle(
                                                          color: AppTheme
                                                              .onPrimaryContainer,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
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

                          const SizedBox(height: 16),

                          // Contrôles Interactifs du Carrousel (Pills & Flèches de navigation)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: List.generate(_slides.length, (idx) {
                                  final isSelected = idx == _currentSlideIndex;
                                  return MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () => _goToSlide(idx),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 350),
                                        curve: Curves.easeOutCubic,
                                        margin: const EdgeInsets.only(right: 8),
                                        width: isSelected ? 32 : 10,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.tertiaryFixed
                                              : Colors.white
                                                  .withValues(alpha: 0.28),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme
                                                        .tertiaryFixed
                                                        .withValues(alpha: 0.65),
                                                    blurRadius: 10,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),

                              Row(
                                children: [
                                  Tooltip(
                                    message: isFr
                                        ? 'Diapositive précédente'
                                        : 'Previous slide',
                                    child: IconButton(
                                      onPressed: _prevSlide,
                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.12),
                                        hoverColor: Colors.white
                                            .withValues(alpha: 0.24),
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(32, 32),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: isFr
                                        ? 'Diapositive suivante'
                                        : 'Next slide',
                                    child: IconButton(
                                      onPressed: _nextSlide,
                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.12),
                                        hoverColor: Colors.white
                                            .withValues(alpha: 0.24),
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(32, 32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Badges de conformité permanente
                          Wrap(
                            spacing: 18,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildBadge(
                                Icons.shield_outlined,
                                isFr
                                    ? 'Certifié ISO 27001'
                                    : 'ISO 27001 Certified',
                              ),
                              _buildBadge(
                                Icons.gavel_rounded,
                                isFr
                                    ? 'RGPD & CNIL Conforme'
                                    : 'GDPR & CNIL Compliant',
                              ),
                              _buildBadge(
                                Icons.lock_outline_rounded,
                                isFr
                                    ? 'Chiffrement SSL 256-bit'
                                    : '256-bit SSL Encryption',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.tertiaryFixed, size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.onPrimaryContainer,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Peintre personnalisé pour un arrière-plan vivant avec orbes luminescents en mouvement continu,
/// rubans d'ondes aurorales ondulantes et poussière d'étoiles flottante.
class _LivingHeroPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  const _LivingHeroPainter({
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final theta = animationValue * 2 * math.pi;

    // ── 1. Orbes luminescents volumétriques (4 orbes aux teintes SaaS premium) ──

    // Orbe 1 : Bleu Royal Électrique (Nord-Ouest / Centre-Haut)
    final orb1Center = Offset(
      size.width * 0.18 + math.sin(theta) * (size.width * 0.18),
      size.height * 0.22 + math.cos(theta * 1.2) * (size.height * 0.12),
    );
    final orb1Radius = (size.width * 0.52) * (1.0 + 0.18 * math.sin(theta * 1.4));
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF2563EB) : const Color(0xFF3B82F6))
              .withValues(alpha: isDark ? 0.44 : 0.36),
          (isDark ? const Color(0xFF1D4ED8) : const Color(0xFF60A5FA))
              .withValues(alpha: isDark ? 0.22 : 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: orb1Center, radius: orb1Radius));
    canvas.drawCircle(orb1Center, orb1Radius, paint1);

    // Orbe 2 : Émeraude / Menthe Boréale (Sud-Est / Droite)
    final orb2Center = Offset(
      size.width * 0.82 - math.cos(theta * 0.9) * (size.width * 0.18),
      size.height * 0.74 - math.sin(theta * 1.1) * (size.height * 0.14),
    );
    final orb2Radius = (size.width * 0.48) * (1.0 + 0.20 * math.cos(theta * 1.3));
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF10B981) : const Color(0xFF059669))
              .withValues(alpha: isDark ? 0.38 : 0.32),
          (isDark ? const Color(0xFF047857) : const Color(0xFF34D399))
              .withValues(alpha: isDark ? 0.18 : 0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: orb2Center, radius: orb2Radius));
    canvas.drawCircle(orb2Center, orb2Radius, paint2);

    // Orbe 3 : Cyber Cyan / Aigue-marine (Centre & Flottant)
    final orb3Center = Offset(
      size.width * 0.62 + math.sin(theta * 1.3) * (size.width * 0.16),
      size.height * 0.44 + math.cos(theta * 1.5) * (size.height * 0.12),
    );
    final orb3Radius = (size.width * 0.40) * (1.0 + 0.22 * math.sin(theta * 1.6));
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF00F2FE) : const Color(0xFF06B6D4))
              .withValues(alpha: isDark ? 0.32 : 0.26),
          (isDark ? const Color(0xFF0891B2) : const Color(0xFF38BDF8))
              .withValues(alpha: isDark ? 0.15 : 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Rect.fromCircle(center: orb3Center, radius: orb3Radius));
    canvas.drawCircle(orb3Center, orb3Radius, paint3);

    // Orbe 4 : Améthyste / Violet Cosmique (Sud-Ouest / Bas Gauche)
    final orb4Center = Offset(
      size.width * 0.28 - math.cos(theta * 0.85) * (size.width * 0.14),
      size.height * 0.84 + math.sin(theta * 1.25) * (size.height * 0.09),
    );
    final orb4Radius = (size.width * 0.44) * (1.0 + 0.16 * math.cos(theta * 1.1));
    final paint4 = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED))
              .withValues(alpha: isDark ? 0.34 : 0.28),
          (isDark ? const Color(0xFF6D28D9) : const Color(0xFFA78BFA))
              .withValues(alpha: isDark ? 0.16 : 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: orb4Center, radius: orb4Radius));
    canvas.drawCircle(orb4Center, orb4Radius, paint4);

    // ── 2. Ondes lumineuses aurorales ondulantes (Courbes de Bézier vivantes) ──
    _drawAuroraWave(
      canvas: canvas,
      size: size,
      theta: theta,
      offsetY: size.height * 0.38,
      amplitude: 50,
      color: isDark ? const Color(0xFF00F2FE) : const Color(0xFF38BDF8),
      alpha: isDark ? 0.22 : 0.18,
    );
    _drawAuroraWave(
      canvas: canvas,
      size: size,
      theta: theta + 1.8,
      offsetY: size.height * 0.65,
      amplitude: 65,
      color: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
      alpha: isDark ? 0.20 : 0.16,
    );

    // ── 3. Particules d'étoiles flottantes en ascension (Stardust Embers) ──
    _drawStardustParticles(canvas, size, theta);
  }

  void _drawAuroraWave({
    required Canvas canvas,
    required Size size,
    required double theta,
    required double offsetY,
    required double amplitude,
    required Color color,
    required double alpha,
  }) {
    final path = Path();
    final y1 = offsetY + math.sin(theta) * amplitude;
    final y2 = offsetY + math.cos(theta * 1.1) * amplitude;
    final y3 = offsetY + math.sin(theta * 0.9) * amplitude;

    path.moveTo(-20, y1);
    path.cubicTo(
      size.width * 0.33,
      y1 - math.cos(theta) * (amplitude * 0.9),
      size.width * 0.66,
      y2 + math.sin(theta * 1.2) * (amplitude * 0.9),
      size.width + 20,
      y3,
    );

    // Halo d'onde large et diffus
    final glowPaint = Paint()
      ..color = color.withValues(alpha: alpha * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawPath(path, glowPaint);

    // Trait fin lumineux au cœur de l'onde
    final linePaint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(path, linePaint);
  }

  void _drawStardustParticles(Canvas canvas, Size size, double theta) {
    // 22 particules déterministes aux coordonnées pseudo-aléatoires et vitesses variables
    const count = 22;
    for (var i = 0; i < count; i++) {
      final seedX = ((i * 179.31) % 1000) / 1000.0;
      final seedY = ((i * 313.87) % 1000) / 1000.0;
      final speed = 0.45 + (i % 5) * 0.22;
      final radius = 1.4 + (i % 3) * 0.9;

      // Dérive ascendante continue basée sur animationValue
      final normalizedTime = (animationValue * speed) % 1.0;
      final currentY =
          ((seedY - normalizedTime) % 1.0 + 1.0) % 1.0 * size.height;
      final currentX =
          (seedX * size.width + math.sin(theta * 1.5 + i) * 22) % size.width;

      // Scintillement organique
      final pulse = (math.sin(theta * 2.5 + i * 1.7) + 1.0) / 2.0;
      final particleAlpha = (0.25 + 0.65 * pulse) * (isDark ? 0.75 : 0.60);

      final center = Offset(currentX, currentY);

      // Lueur extérieure douce
      final haloPaint = Paint()
        ..color = (i % 2 == 0 ? const Color(0xFF00F2FE) : const Color(0xFFFACC15))
            .withValues(alpha: particleAlpha * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, radius * 2.8, haloPaint);

      // Cœur d'étoile net et lumineux
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: particleAlpha);
      canvas.drawCircle(center, radius, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LivingHeroPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark;
  }
}

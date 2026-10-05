import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';

/// ──────────────────────────────────────────────────────
/// Train with AI – "S'entraîner avec l'IA"
/// ──────────────────────────────────────────────────────
class AiQuizPage extends ConsumerStatefulWidget {
  const AiQuizPage({super.key});

  @override
  ConsumerState<AiQuizPage> createState() => _AiQuizPageState();
}

class _AiQuizPageState extends ConsumerState<AiQuizPage>
    with TickerProviderStateMixin {
  // State
  String _selectedModule = 'Algorithmique Avancée';
  String _selectedModuleSubtitle = 'LICENCE 3 • ALGORITHMIQUE';
  String _selectedModuleProf = 'Prof. Amine Mansouri';

  final Set<int> _selectedChapters = {1, 2};
  int _selectedDifficulty = 1; // 0=Débutant, 1=Intermédiaire, 2=Expert
  double _questionCount = 15;
  bool _explanationsEnabled = true;
  bool _timedModeEnabled = true;
  bool _mcqEnabled = true;
  bool _isGenerating = false;

  late AnimationController _entryController;
  late AnimationController _pulseController;

  final List<Map<String, String>> _availableCourses = [
    {
      'title': 'Algorithmique Avancée',
      'dept': 'LICENCE 3 • ALGORITHMIQUE',
      'prof': 'Prof. Amine Mansouri',
    },
    {
      'title': 'Systèmes d\'Exploitation',
      'dept': 'LICENCE 3 • SYSTÈMES & RÉSEAUX',
      'prof': 'Prof. Mansouri H.',
    },
    {
      'title': 'Bases de Données Relationnelles',
      'dept': 'LICENCE 3 • DONNÉES & IA',
      'prof': 'Prof. Karray S.',
    },
    {
      'title': 'Intelligence Artificielle',
      'dept': 'LICENCE 3 • DONNÉES & IA',
      'prof': 'Prof. Benali R.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedEntry({
    required Widget child,
    required double start,
    required double end,
  }) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  int get _estimatedDuration => (_questionCount * 1.2).round();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              pinned: true,
              backgroundColor: cs.surface.withValues(alpha: 0.95),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leadingWidth: 56,
              leading: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? cs.surfaceContainerHigh.withValues(alpha: 0.6)
                            : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              centerTitle: true,
              title: Image.asset(
                'assets/images/logo.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_rounded, color: cs.primary, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'SmartClass',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow
                                .withValues(alpha: isDark ? 0.3 : 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/student_avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(Icons.person,
                                size: 16, color: cs.onPrimaryContainer),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Body Content ──
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),

                // ── Header with badge ──
                _buildAnimatedEntry(
                  start: 0.0,
                  end: 0.30,
                  child: _buildHeader(theme, cs),
                ),
                const SizedBox(height: 20),

                // ── Active Course Card ──
                _buildAnimatedEntry(
                  start: 0.12,
                  end: 0.42,
                  child: _buildCourseCard(theme, cs, isDark),
                ),
                const SizedBox(height: 20),

                // ── Chapter Selection ──
                _buildAnimatedEntry(
                  start: 0.24,
                  end: 0.54,
                  child: _buildChapterSection(theme, cs, isDark),
                ),
                const SizedBox(height: 20),

                // ── Difficulty Level ──
                _buildAnimatedEntry(
                  start: 0.36,
                  end: 0.66,
                  child: _buildDifficultySection(theme, cs, isDark),
                ),
                const SizedBox(height: 20),

                // ── Question Count Slider ──
                _buildAnimatedEntry(
                  start: 0.48,
                  end: 0.78,
                  child: _buildQuestionCountSection(theme, cs, isDark),
                ),
                const SizedBox(height: 20),

                // ── Evaluation Options ──
                _buildAnimatedEntry(
                  start: 0.60,
                  end: 0.90,
                  child: _buildEvaluationSection(theme, cs, isDark),
                ),
                const SizedBox(height: 20),

                // ── AI Badge ──
                _buildAnimatedEntry(
                  start: 0.68,
                  end: 0.95,
                  child: _buildAiBadge(theme, cs, isDark),
                ),
                const SizedBox(height: 20),

                // ── CTA ──
                _buildAnimatedEntry(
                  start: 0.75,
                  end: 1.0,
                  child: Column(
                    children: [
                      _buildStartButton(theme, cs, isDark),
                      const SizedBox(height: 10),
                      _buildCtaSubtext(theme, cs),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ────────── HEADER ──────────
  Widget _buildHeader(ThemeData theme, ColorScheme cs) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Badge pill row
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? cs.secondaryContainer.withValues(alpha: 0.3)
                    : cs.secondaryFixed.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) => Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.15),
                      child: Icon(Icons.auto_awesome, size: 14, color: cs.primary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      context.tr('ai_quiz_generator_badge'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 14, color: cs.secondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      context.tr('ai_adapted_exams'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "${context.tr('ai_quiz_title')} ✨",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            fontSize: 25,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr('ai_quiz_subtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.45,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ────────── COURSE CARD ──────────
  Widget _buildCourseCard(ThemeData theme, ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.terminal_rounded, size: 24, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedModuleSubtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.secondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedModule,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _selectedModuleProf,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showCourseSelector(context, theme, cs),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('ai_change'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.expand_more_rounded,
                        size: 16, color: cs.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────── CHAPTERS SELECTION ──────────
  Widget _buildChapterSection(ThemeData theme, ColorScheme cs, bool isDark) {
    final chapters = [
      context.tr('ai_all_module'),
      'Ch. 1 : Complexité Asymptotique',
      'Ch. 2 : Récursivité & Appels',
      'Ch. 3 : Arbres Binaires & AVL',
      'Ch. 4 : Graphes & BFS/DFS',
    ];

    final allSelected = _selectedChapters.length == chapters.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: context.tr('ai_chapters_selection'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: context.tr('ai_chapters_selected_count',
                          args: {'count': '${_selectedChapters.length}'}),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.secondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (allSelected) {
                    _selectedChapters.clear();
                  } else {
                    _selectedChapters.addAll(
                        List.generate(chapters.length, (i) => i));
                  }
                });
              },
              child: Text(
                allSelected
                    ? context.tr('deselect_all')
                    : context.tr('select_all'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(chapters.length, (index) {
            final isSelected = _selectedChapters.contains(index);
            final isAllModule = index == 0;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isAllModule) {
                      if (isSelected) {
                        _selectedChapters.clear();
                      } else {
                        _selectedChapters.addAll(
                            List.generate(chapters.length, (i) => i));
                      }
                    } else {
                      if (isSelected) {
                        _selectedChapters.remove(index);
                      } else {
                        _selectedChapters.add(index);
                      }
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primaryContainer
                        : cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            cs.shadow.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                    border: isSelected
                        ? null
                        : Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.3),
                          ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : (isAllModule
                                ? Icons.library_books_rounded
                                : Icons.radio_button_unchecked_rounded),
                        size: 18,
                        color: isSelected
                            ? const Color(0xFF83F8CD)
                            : cs.outline,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          chapters[index],
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAllModule) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.secondaryFixed,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            context.tr('recommended'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ────────── DIFFICULTY ──────────
  Widget _buildDifficultySection(
      ThemeData theme, ColorScheme cs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.tr('ai_difficulty_level'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('ai_adapted_exams'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.secondary,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            _difficultyCard(
              theme: theme,
              cs: cs,
              isDark: isDark,
              index: 0,
              emoji: '🌱',
              title: context.tr('ai_diff_beginner'),
              subtitle: context.tr('ai_diff_beginner_sub'),
              barIcon: Icons.signal_cellular_alt_1_bar_rounded,
            ),
            const SizedBox(width: 10),
            _difficultyCard(
              theme: theme,
              cs: cs,
              isDark: isDark,
              index: 1,
              emoji: '⚡',
              title: context.tr('ai_diff_intermediate'),
              subtitle: context.tr('ai_diff_intermediate_sub'),
              barIcon: Icons.signal_cellular_alt_2_bar_rounded,
            ),
            const SizedBox(width: 10),
            _difficultyCard(
              theme: theme,
              cs: cs,
              isDark: isDark,
              index: 2,
              emoji: '🎯',
              title: context.tr('ai_diff_expert'),
              subtitle: context.tr('ai_diff_expert_sub'),
              barIcon: Icons.signal_cellular_alt_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _difficultyCard({
    required ThemeData theme,
    required ColorScheme cs,
    required bool isDark,
    required int index,
    required String emoji,
    required String title,
    required String subtitle,
    required IconData barIcon,
  }) {
    final isSelected = _selectedDifficulty == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedDifficulty = index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedScale(
            scale: isSelected ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(minHeight: 96),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF243DA0) : cs.primary)
                    : cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(
                        alpha: isSelected ? 0.16 : (isDark ? 0.2 : 0.04)),
                    blurRadius: isSelected ? 12 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isSelected
                    ? Border.all(
                        color: (isDark ? const Color(0xFF6B8EFF) : cs.primary)
                            .withValues(alpha: 0.4),
                        width: 1.5,
                      )
                    : Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 20)),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: child,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                key: ValueKey('checked'),
                                size: 18,
                                color: Color(0xFF83F8CD))
                            : Icon(barIcon,
                                key: const ValueKey('bar'),
                                size: 16,
                                color: cs.outlineVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? const Color(0xFFB9C3FF)
                          : cs.onSurfaceVariant,
                      fontSize: 10,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────── QUESTION COUNT ──────────
  Widget _buildQuestionCountSection(
      ThemeData theme, ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('ai_question_count_title'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('ai_question_count_subtitle'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  context.tr('ai_questions_badge',
                      args: {'count': '${_questionCount.round()}'}),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: cs.primary,
              inactiveTrackColor: cs.surfaceContainerHigh,
              thumbColor: cs.primary,
              overlayColor: cs.primary.withValues(alpha: 0.12),
              trackHeight: 5,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: _questionCount,
              min: 5,
              max: 30,
              divisions: 5,
              onChanged: (v) => setState(() => _questionCount = v),
            ),
          ),

          // Clickable Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sliderTickLabel(context.tr('ai_5_express'), 5, theme, cs),
                _sliderTickLabel(context.tr('ai_15_standard'), 15, theme, cs),
                _sliderTickLabel(context.tr('ai_30_intensive'), 30, theme, cs),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Duration estimate
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('ai_duration_estimate',
                        args: {'min': '$_estimatedDuration'}),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
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

  Widget _sliderTickLabel(
      String text, double val, ThemeData theme, ColorScheme cs) {
    final isSelected = _questionCount.round() == val.round();
    return GestureDetector(
      onTap: () => setState(() => _questionCount = val),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isSelected ? cs.primary : cs.outline,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }

  // ────────── EVALUATION OPTIONS ──────────
  Widget _buildEvaluationSection(
      ThemeData theme, ColorScheme cs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('ai_evaluation_modalities'),
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle: Explications détaillées
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('ai_detailed_explanations'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('ai_detailed_exp_sub'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    value: _explanationsEnabled,
                    onChanged: (v) =>
                        setState(() => _explanationsEnabled = v),
                    activeTrackColor: cs.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: cs.surfaceContainerHigh, height: 1),
              const SizedBox(height: 12),

              // Format pills
              Text(
                context.tr('ai_restitution_format'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _formatPill(
                    Icons.schedule_rounded,
                    context.tr('ai_timed_mode'),
                    _timedModeEnabled,
                    () => setState(() => _timedModeEnabled = !_timedModeEnabled),
                    theme,
                    cs,
                  ),
                  _formatPill(
                    Icons.rule_rounded,
                    context.tr('ai_mcq_tf'),
                    _mcqEnabled,
                    () => setState(() => _mcqEnabled = !_mcqEnabled),
                    theme,
                    cs,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _formatPill(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? cs.primaryContainer.withValues(alpha: 0.15)
                : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? cs.primary : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────── AI BADGE ──────────
  Widget _buildAiBadge(ThemeData theme, ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(Icons.verified_rounded,
                size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('ai_reassurance_badge'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────── CTA ──────────
  Widget _buildStartButton(ThemeData theme, ColorScheme cs, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;
        return Transform.scale(
          scale: _isGenerating ? 0.98 : 1.0 + (pulse * 0.012),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isGenerating ? null : _handleStart,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  color: _isGenerating
                      ? cs.surfaceContainerHigh
                      : (isDark ? const Color(0xFF243DA0) : cs.primary),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isGenerating
                      ? null
                      : [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.25 + (pulse * 0.15)),
                            blurRadius: 14 + (pulse * 6),
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: _isGenerating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(cs.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.tr('ai_generating_quiz'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr('ai_start_quiz_btn'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Transform.rotate(
                            angle: pulse * 0.1 - 0.05,
                            child: const Icon(Icons.bolt_rounded,
                                size: 20, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCtaSubtext(ThemeData theme, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_sync_rounded, size: 14, color: cs.outline),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            context.tr('ai_quiz_subtext'),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.outline,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleStart() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      setState(() => _isGenerating = false);
      _showQuizSessionModal(context, Theme.of(context), Theme.of(context).colorScheme);
    }
  }

  void _showCourseSelector(
      BuildContext context, ThemeData theme, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('ai_select_course_title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_availableCourses.length, (i) {
                  final c = _availableCourses[i];
                  final isSelected = c['title'] == _selectedModule;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? cs.primary : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.terminal_rounded,
                        color: isSelected ? cs.onPrimary : cs.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      c['title']!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '${c['dept']} • ${c['prof']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: cs.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedModule = c['title']!;
                        _selectedModuleSubtitle = c['dept']!;
                        _selectedModuleProf = c['prof']!;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQuizSessionModal(
      BuildContext context, ThemeData theme, ColorScheme cs) {
    int selectedAnswer = -1;
    bool answered = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bolt, color: cs.primary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('ai_question_counter', args: {
                                'current': '1',
                                'total': '${_questionCount.round()}'
                              }),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                        if (_timedModeEnabled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timer, size: 14, color: cs.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '01:12',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Quelle est la complexité dans le pire des cas d\'une opération de recherche dans un Arbre Binaire de Recherche Équilibré (AVL) contenant n nœuds ?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(4, (i) {
                      final answers = [
                        'O(1)',
                        'O(log n)',
                        'O(n)',
                        'O(n log n)',
                      ];
                      final isCorrect = i == 1;
                      final isChosen = selectedAnswer == i;

                      Color itemBg = cs.surfaceContainerLow;
                      Color borderCol = cs.outlineVariant.withValues(alpha: 0.3);

                      if (answered) {
                        if (isCorrect) {
                          itemBg = const Color(0xFF0F9D78).withValues(alpha: 0.15);
                          borderCol = const Color(0xFF0F9D78);
                        } else if (isChosen && !isCorrect) {
                          itemBg = cs.errorContainer.withValues(alpha: 0.3);
                          borderCol = cs.error;
                        }
                      } else if (isChosen) {
                        itemBg = cs.primaryContainer.withValues(alpha: 0.1);
                        borderCol = cs.primary;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: answered
                                ? null
                                : () {
                                    setModalState(() {
                                      selectedAnswer = i;
                                      answered = true;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: itemBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderCol),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isChosen
                                        ? cs.primary
                                        : cs.surfaceContainerHigh,
                                    child: Text(
                                      String.fromCharCode(65 + i),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isChosen
                                            ? Colors.white
                                            : cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    answers[i],
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (answered && isCorrect)
                                    const Icon(Icons.check_circle,
                                        color: Color(0xFF0F9D78), size: 18)
                                  else if (answered && isChosen && !isCorrect)
                                    Icon(Icons.cancel,
                                        color: cs.error, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (answered && _explanationsEnabled) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 16, color: cs.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${context.tr('ai_explanation_prefix')}Dans un AVL, la hauteur h est strictement bornée par 1.44 log₂(n), garantissant une recherche en O(log n) même dans le pire des cas.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(answered
                            ? context.tr('ai_next_question')
                            : context.tr('ai_quit_test')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

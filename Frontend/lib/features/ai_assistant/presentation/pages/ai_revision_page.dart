import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';

/// ──────────────────────────────────────────────────────
/// Assist Revision AI – "Générer Mes Révisions"
/// ──────────────────────────────────────────────────────
class AiRevisionPage extends ConsumerStatefulWidget {
  const AiRevisionPage({super.key});

  @override
  ConsumerState<AiRevisionPage> createState() => _AiRevisionPageState();
}

class _AiRevisionPageState extends ConsumerState<AiRevisionPage>
    with TickerProviderStateMixin {
  // State
  String _selectedModule = 'Licence 3 - Algorithmique Avancée';
  String _selectedModuleProf = 'Prof. Amine • Semestre 6';
  String? _importedDocumentName;

  int _selectedFormat = 0; // 0=Résumé, 1=Flashcards, 2=MindMap
  double _granularity = 2; // 1=Concis, 2=Équilibré, 3=Détaillé
  bool _isGenerating = false;
  late AnimationController _entranceController;
  late AnimationController _pulseController;

  final List<Map<String, String>> _availableModules = [
    {
      'title': 'Licence 3 - Algorithmique Avancée',
      'prof': 'Prof. Amine • Semestre 6',
    },
    {
      'title': 'Licence 3 - Systèmes d\'Exploitation',
      'prof': 'Prof. Mansouri • Semestre 6',
    },
    {
      'title': 'Licence 3 - Bases de Données Avancées',
      'prof': 'Prof. Karray • Semestre 6',
    },
    {
      'title': 'Licence 3 - Intelligence Artificielle',
      'prof': 'Prof. Benali • Semestre 6',
    },
  ];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedEntry({
    required Widget child,
    required double start,
    required double end,
  }) {
    final anim = CurvedAnimation(
      parent: _entranceController,
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

  String _getGranularityLabel(BuildContext context) {
    switch (_granularity.round()) {
      case 1:
        return context.tr('ai_granularity_concise');
      case 3:
        return context.tr('ai_granularity_detailed');
      default:
        return context.tr('ai_granularity_balanced');
    }
  }

  String _getGranularityDescription(BuildContext context) {
    switch (_granularity.round()) {
      case 1:
        return context.tr('ai_granularity_desc_concise');
      case 3:
        return context.tr('ai_granularity_desc_detailed');
      default:
        return context.tr('ai_granularity_desc_balanced');
    }
  }

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
                          color: cs.shadow.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/student_avatar.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => CircleAvatar(
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

                // ── Header ──
                _buildAnimatedEntry(
                  start: 0.0,
                  end: 0.35,
                  child: _buildHeader(theme, cs, isDark),
                ),
                const SizedBox(height: 20),

                // ── Step 1: Source du cours ──
                _buildAnimatedEntry(
                  start: 0.15,
                  end: 0.50,
                  child: _buildStepCard(
                    theme: theme,
                    cs: cs,
                    isDark: isDark,
                    step: 1,
                    title: context.tr('ai_source_step_title'),
                    trailing: Text(
                      context.tr('ai_ent_presynced'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _buildSourceSection(theme, cs, isDark),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Step 2: Format souhaité ──
                _buildAnimatedEntry(
                  start: 0.30,
                  end: 0.65,
                  child: _buildStepCard(
                    theme: theme,
                    cs: cs,
                    isDark: isDark,
                    step: 2,
                    title: context.tr('ai_format_step_title'),
                    trailing: Text(
                      context.tr('ai_active_selection'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    subtitle: context.tr('ai_format_step_subtitle'),
                    child: _buildFormatSection(theme, cs, isDark),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Step 3: Niveau de détail ──
                _buildAnimatedEntry(
                  start: 0.45,
                  end: 0.80,
                  child: _buildStepCard(
                    theme: theme,
                    cs: cs,
                    isDark: isDark,
                    step: 3,
                    title: context.tr('ai_granularity_step_title'),
                    trailing: Text(
                      _getGranularityLabel(context),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _buildGranularitySection(theme, cs, isDark),
                  ),
                ),
                const SizedBox(height: 24),

                // ── CTA Button ──
                _buildAnimatedEntry(
                  start: 0.60,
                  end: 0.95,
                  child: Column(
                    children: [
                      _buildGenerateButton(theme, cs),
                      const SizedBox(height: 10),
                      _buildCtaSubtext(theme, cs),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Recent Summaries ──
                _buildAnimatedEntry(
                  start: 0.70,
                  end: 1.0,
                  child: _buildRecentSummariesSection(theme, cs, isDark),
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
  Widget _buildHeader(ThemeData theme, ColorScheme cs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category / Kicker badges
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: isDark ? 0.35 : 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology_rounded, size: 15, color: cs.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      context.tr('ai_revision_header'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
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
                color: isDark
                    ? cs.secondaryContainer.withValues(alpha: 0.3)
                    : cs.secondaryFixed.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.secondary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) => Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.15),
                      child: Icon(Icons.auto_awesome, size: 13, color: cs.secondary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      context.tr('ai_model_l3_badge'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSecondaryContainer,
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

        // Main Screen Title: "Générer Mes Révisions"
        Text(
          context.tr('ai_revision_title'),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            fontSize: 25,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),

        // Descriptive Subtitle
        Text(
          context.tr('ai_revision_subtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.45,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ────────── STEP CARD WRAPPER ──────────
  Widget _buildStepCard({
    required ThemeData theme,
    required ColorScheme cs,
    required bool isDark,
    required int step,
    required String title,
    Widget? trailing,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: cs.primaryFixed,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$step',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onPrimaryFixed,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: trailing,
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ────────── SOURCE SECTION ──────────
  Widget _buildSourceSection(ThemeData theme, ColorScheme cs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Module selector label
        Text(
          context.tr('ai_select_module'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),

        // Module dropdown
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showModuleSelector(context, theme, cs),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.account_tree_rounded,
                        size: 20, color: cs.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedModule,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
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
                  Icon(Icons.expand_more_rounded,
                      size: 20, color: cs.outline),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Divider with "OU / OR"
        Row(
          children: [
            Expanded(
              child: Divider(color: cs.surfaceContainerHigh, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                context.tr('or').toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.outline,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: cs.surfaceContainerHigh, height: 1),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Upload dropzone
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleDocumentImport,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: _importedDocumentName != null
                    ? cs.primaryContainer.withValues(alpha: 0.08)
                    : cs.surfaceContainerLow.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _importedDocumentName != null
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _importedDocumentName != null
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _importedDocumentName != null
                          ? Icons.check_circle_rounded
                          : Icons.cloud_upload_rounded,
                      size: 24,
                      color: _importedDocumentName != null
                          ? cs.onPrimary
                          : cs.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _importedDocumentName ??
                              context.tr('ai_import_doc_title'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: cs.secondary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _importedDocumentName != null
                        ? context.tr('ai_import_doc_ready')
                        : context.tr('ai_import_doc_subtitle'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ────────── FORMAT SECTION ──────────
  Widget _buildFormatSection(ThemeData theme, ColorScheme cs, bool isDark) {
    final formats = [
      _FormatOption(
        icon: Icons.bolt_rounded,
        title: context.tr('ai_format_express'),
        badge: context.tr('ai_format_express_badge'),
        description: context.tr('ai_format_express_desc'),
      ),
      _FormatOption(
        icon: Icons.style_rounded,
        title: context.tr('ai_format_flashcards'),
        badge: context.tr('ai_format_flashcards_badge'),
        description: context.tr('ai_format_flashcards_desc'),
      ),
      _FormatOption(
        icon: Icons.hub_rounded,
        title: context.tr('ai_format_mindmap'),
        badge: context.tr('ai_format_mindmap_badge'),
        description: context.tr('ai_format_mindmap_desc'),
      ),
    ];

    return Column(
      children: List.generate(formats.length, (index) {
        final f = formats[index];
        final isSelected = _selectedFormat == index;

        return Padding(
          padding: EdgeInsets.only(bottom: index < formats.length - 1 ? 10 : 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _selectedFormat = index),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedScale(
                scale: isSelected ? 1.015 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primaryContainer
                        : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.16),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                    border: isSelected
                        ? Border.all(color: cs.primary.withValues(alpha: 0.35), width: 1.5)
                        : Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.2),
                          ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.18)
                              : cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          f.icon,
                          size: 22,
                          color: isSelected ? Colors.white : cs.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  f.title,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : cs.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : cs.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    f.badge,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : cs.onSurfaceVariant,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              f.description,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? const Color(0xFF9EAEFF)
                                    : cs.onSurfaceVariant,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: child,
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          key: ValueKey<bool>(isSelected),
                          size: 24,
                          color: isSelected
                              ? const Color(0xFF83F8CD)
                              : cs.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ────────── GRANULARITY SECTION ──────────
  Widget _buildGranularitySection(
      ThemeData theme, ColorScheme cs, bool isDark) {
    return Column(
      children: [
        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: cs.primary,
            inactiveTrackColor: cs.surfaceContainerHigh,
            thumbColor: cs.primary,
            overlayColor: cs.primary.withValues(alpha: 0.12),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _granularity,
            min: 1,
            max: 3,
            divisions: 2,
            onChanged: (v) => setState(() => _granularity = v),
          ),
        ),

        // Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _granularityTapLabel(context.tr('ai_granularity_concise'), 1, theme, cs),
              _granularityTapLabel(context.tr('ai_granularity_balanced'), 2, theme, cs),
              _granularityTapLabel(context.tr('ai_granularity_detailed'), 3, theme, cs),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Description
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(_granularity.round()),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: cs.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.45,
                        fontSize: 11,
                      ),
                      children: [
                        TextSpan(
                          text: _granularity.round() == 1
                              ? '${context.tr('ai_granularity_concise')} : '
                              : _granularity.round() == 2
                                  ? '${context.tr('ai_granularity_balanced')} : '
                                  : '${context.tr('ai_granularity_detailed')} : ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: _getGranularityDescription(context).contains(': ')
                              ? _getGranularityDescription(context).split(': ').last
                              : _getGranularityDescription(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _granularityTapLabel(
      String label, double val, ThemeData theme, ColorScheme cs) {
    final isActive = _granularity.round() == val.round();
    return GestureDetector(
      onTap: () => setState(() => _granularity = val),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isActive ? cs.primary : cs.onSurfaceVariant,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  // ────────── CTA BUTTON ──────────
  Widget _buildGenerateButton(ThemeData theme, ColorScheme cs) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;
        return Transform.scale(
          scale: _isGenerating ? 0.98 : 1.0 + (pulse * 0.012),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isGenerating ? null : _handleGenerate,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isGenerating
                        ? [cs.surfaceContainerHigh, cs.surfaceContainerHigh]
                        : [
                            const Color(0xFFF5A623),
                            const Color(0xFFE0961D),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isGenerating
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFFF5A623).withValues(alpha: 0.25 + (pulse * 0.2)),
                            blurRadius: 14 + (pulse * 8),
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
                            context.tr('ai_generating_analysis'),
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
                          Transform.rotate(
                            angle: pulse * 0.12 - 0.06,
                            child: const Icon(Icons.auto_awesome,
                                size: 22, color: Color(0xFF1D2338)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('ai_generate_summary_btn'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF1D2338),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
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
        Icon(Icons.bolt_rounded, size: 15, color: cs.secondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            context.tr('ai_generate_subtext'),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleGenerate() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      setState(() => _isGenerating = false);
      _showGeneratedSummaryModal(context, Theme.of(context), Theme.of(context).colorScheme);
    }
  }

  void _handleDocumentImport() {
    setState(() {
      _importedDocumentName = 'TD3_Arbres_AVL_Enonce_Corrige.pdf (1.4 Mo)';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(context.tr('ai_import_doc_success')),
          ],
        ),
        backgroundColor: const Color(0xFF0F9D78),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showModuleSelector(BuildContext context, ThemeData theme, ColorScheme cs) {
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
                  context.tr('ai_select_module_modal_title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_availableModules.length, (i) {
                  final mod = _availableModules[i];
                  final isSelected = mod['title'] == _selectedModule;
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
                        Icons.account_tree_rounded,
                        color: isSelected ? cs.onPrimary : cs.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      mod['title']!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      mod['prof']!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: cs.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedModule = mod['title']!;
                        _selectedModuleProf = mod['prof']!;
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

  void _showGeneratedSummaryModal(BuildContext context, ThemeData theme, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ListView(
                controller: scrollController,
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
                          Icon(Icons.auto_awesome, color: const Color(0xFFF5A623), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('ai_summary_modal_title'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedModule,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummarySection(
                    theme,
                    cs,
                    '1. Théorèmes & Axiomes Clés',
                    '• Définition de l\'arbre AVL : arbre binaire de recherche équilibré en hauteur.\n• Facteur d\'équilibrage : h(gauche) - h(droite) ∈ {-1, 0, 1}.\n• Complexité garantie : Recherche, insertion et suppression en O(log n).',
                  ),
                  const SizedBox(height: 12),
                  _buildSummarySection(
                    theme,
                    cs,
                    '2. Algorithmes de Rotations',
                    '• Rotation Gauche (LL) : appliquée lors d\'un déséquilibre consécutif à droite.\n• Rotation Droite (RR) : appliquée lors d\'un déséquilibre consécutif à gauche.\n• Double Rotation (LR / RL) : appliquée lors des cas de déséquilibres internes alternés.',
                  ),
                  const SizedBox(height: 12),
                  _buildSummarySection(
                    theme,
                    cs,
                    '3. Vigilance Partiels',
                    '• Vérifier systématiquement la mise à jour des hauteurs post-insertion.\n• Attention aux cas de suppression avec deux descendants.',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text(context.tr('ai_export_pdf')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/ai-quiz');
                        },
                        icon: const Icon(Icons.bolt, size: 18),
                        label: Text(context.tr('ai_practice_action')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.primary,
                          side: BorderSide(color: cs.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummarySection(
      ThemeData theme, ColorScheme cs, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ────────── RECENT SUMMARIES ──────────
  Widget _buildRecentSummariesSection(
      ThemeData theme, ColorScheme cs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('ai_recent_summaries_title'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                fontSize: 18,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('ai_see_all_count', args: {'count': '8'}),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: cs.secondary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Card 1
        _buildSummaryCard(
          theme: theme,
          cs: cs,
          isDark: isDark,
          icon: Icons.picture_as_pdf_rounded,
          iconBgColor: cs.errorContainer,
          iconColor: cs.onErrorContainer,
          title: 'Synthèse - Arbres AVL & Rotations',
          subtitle: 'Algorithmique • Il y a 2h • 4 pages • 8 flashcards',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniIconButton(Icons.share_rounded, cs),
              const SizedBox(width: 4),
              _actionChip(context.tr('open'), Icons.visibility_rounded, theme, cs, () {
                _showGeneratedSummaryModal(context, theme, cs);
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Card 2
        _buildSummaryCard(
          theme: theme,
          cs: cs,
          isDark: isDark,
          icon: Icons.description_rounded,
          iconBgColor: cs.primaryFixed,
          iconColor: cs.onPrimaryFixed,
          title: 'Fiche Mémo - Espaces Vectoriels & Rang',
          subtitle: 'Algèbre Linéaire • Hier • Résumé express',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.tertiaryFixed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded,
                        size: 13, color: cs.onTertiaryFixedVariant),
                    const SizedBox(width: 3),
                    Text(
                      '94%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onTertiaryFixedVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required ThemeData theme,
    required ColorScheme cs,
    required bool isDark,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
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
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          trailing,
        ],
      ),
    );
  }

  Widget _miniIconButton(IconData icon, ColorScheme cs) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('ai_share_link_copied')),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _actionChip(
      String label, IconData icon, ThemeData theme, ColorScheme cs, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatOption {
  final IconData icon;
  final String title;
  final String badge;
  final String description;

  const _FormatOption({
    required this.icon,
    required this.title,
    required this.badge,
    required this.description,
  });
}

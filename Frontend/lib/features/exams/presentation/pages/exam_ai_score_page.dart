import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/extensions.dart';

class ExamAiScorePage extends StatefulWidget {
  final String examTitle;
  final String courseContext;

  const ExamAiScorePage({
    super.key,
    this.examTitle = 'Examen Continu : Complexité & Structures Arborescentes',
    this.courseContext = 'Licence 3 Informatique • Algorithmique Avancée',
  });

  @override
  State<ExamAiScorePage> createState() => _ExamAiScorePageState();
}

class _ExamAiScorePageState extends State<ExamAiScorePage> {
  String _filter = 'all'; // 'all', 'errors', 'success'
  final Set<String> _expandedAiExplanations = {};
  bool _isPlayingAudio = false;

  void _toggleAiExplanation(String id) {
    setState(() {
      if (_expandedAiExplanations.contains(id)) {
        _expandedAiExplanations.remove(id);
      } else {
        _expandedAiExplanations.add(id);
      }
    });
  }

  void _showRemediationCardsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.push_pin_rounded,
                      color: colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '3 Fiches de Remédiation Ciblées',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Générées automatiquement par l\'IA pour consolider vos points d\'amélioration.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _RemediationCardItem(
                number: 1,
                title: 'Profondeur de la pile d\'appels (Call Stack)',
                concept:
                    'Pour fibonacci(n), bien qu\'il y ait O(2ⁿ) appels totaux, la pile mémoire ne retient simultanément que les appels actifs le long de la branche la plus profonde, soit une profondeur maximale O(n).',
                notion: 'Chapitre 2.3 • Récursion & Arbre d\'appels',
              ),
              const SizedBox(height: 10),
              _RemediationCardItem(
                number: 2,
                title: 'Arbres AVL : Cas de déséquilibre Gauche-Droite',
                concept:
                    'Lorsqu\'un nœud présente un facteur de balance +2 et que son enfant gauche a un facteur -1, une simple rotation droite ne suffit pas. Une double rotation gauche-droite (LR) est obligatoire pour restaurer la propriété AVL.',
                notion: 'Chapitre 4.2 • Équilibrage dynamique AVL',
              ),
              const SizedBox(height: 10),
              _RemediationCardItem(
                number: 3,
                title: 'Mémoïsation & Programmation Dynamique',
                concept:
                    'Pour éliminer la redondance des calculs récursifs de Fibonacci et abaisser la complexité temporelle de O(2ⁿ) à O(n), stockez chaque sous-problème résolu dans un tableau ou dictionnaire.',
                notion: 'Chapitre 5.1 • Optimisation de la récursivité',
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Enregistrer dans mes fiches de révision'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.screenWidth >= 1024;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/exams'),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Résultats De L\'Examen',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Exam Metadata & Status Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.school_outlined,
                                      size: 14,
                                      color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.courseContext.split('•').first.trim(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryFixed,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.terminal_rounded,
                                      size: 14,
                                      color: colorScheme.onSecondaryFixed),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.courseContext.contains('•')
                                        ? widget.courseContext.split('•').last.trim()
                                        : 'Algorithmique',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSecondaryFixed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.examTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 15, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '18 min 45s',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('•',
                                style: TextStyle(
                                    color: colorScheme.outlineVariant)),
                            const SizedBox(width: 10),
                            Icon(Icons.schedule_rounded,
                                size: 15, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '14:32',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('•',
                                style: TextStyle(
                                    color: colorScheme.outlineVariant)),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.workspace_premium_rounded,
                                      size: 13, color: colorScheme.tertiary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Très Bien',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.tertiary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Central Radial Score Showcase
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Radial Score Ring (80% / 16 on 20)
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(160, 160),
                                painter: _ScoreRingPainter(
                                  progress: 0.8,
                                  backgroundColor: colorScheme.surfaceContainer,
                                  primaryColor: colorScheme.primary,
                                  secondaryColor: colorScheme.secondary,
                                  tertiaryColor: colorScheme.tertiary,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '16',
                                    style: theme.textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      height: 1.0,
                                    ),
                                  ),
                                  Text(
                                    '/ 20',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'SCORE GLOBAL',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.08,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Cohort Comparison Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 16, color: colorScheme.tertiary),
                              const SizedBox(width: 8),
                              Text(
                                'Validé avec succès (+3.2 pts vs promo)',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.tertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),

                        // Mini KPI Metrics Grid (3 columns)
                        Row(
                          children: [
                            Expanded(
                              child: _KpiMetricCard(
                                label: 'Réussite',
                                value: '8 / 10',
                                badge: '80%',
                                badgeColor: colorScheme.tertiary,
                                badgeTextColor: colorScheme.onTertiary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _KpiMetricCard(
                                label: 'À revoir',
                                value: '2 / 10',
                                badge: '20%',
                                badgeColor: colorScheme.error,
                                badgeTextColor: colorScheme.onError,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _KpiMetricCard(
                                label: 'Rang Promo',
                                value: '4e',
                                badge: '/ 48',
                                badgeColor: colorScheme.secondaryFixed,
                                badgeTextColor: colorScheme.onSecondaryFixed,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // AI Pedagogical Synthesis Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.surfaceContainerLowest,
                          colorScheme.surfaceContainerLow,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryFixed,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome,
                                      size: 15, color: Colors.amber),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tuteur IA SmartClass',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimaryFixed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Diagnostic instantané',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.psychology_rounded,
                                  color: Colors.amber, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.4,
                                    ),
                                    children: const [
                                      TextSpan(text: '“Très bon travail, '),
                                      TextSpan(
                                        text: 'Salma',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                          text:
                                              ' ! Tu maîtrises parfaitement la complexité asymptotique (QuickSort, arbres binaires). Pense à revoir le '),
                                      TextSpan(
                                        text:
                                            'Chapitre 2 sur la récursivité et l’arbre d’appels',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                          text:
                                              ' ainsi que l’équilibrage des arbres AVL.”'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Remediation Quick Actions
                        FilledButton.icon(
                          onPressed: _showRemediationCardsDialog,
                          icon: const Icon(Icons.push_pin_rounded, size: 18),
                          label: const Text('Générer 3 fiches de remédiation'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _isPlayingAudio = !_isPlayingAudio);
                            context.showInfoToast(
                              _isPlayingAudio
                                  ? 'Lecture du débrief audio IA...'
                                  : 'Débrief audio mis en pause.',
                            );
                          },
                          icon: Icon(
                            _isPlayingAudio
                                ? Icons.pause_circle_filled_rounded
                                : Icons.headphones_rounded,
                            size: 18,
                            color: colorScheme.secondary,
                          ),
                          label: Text(_isPlayingAudio
                              ? 'En écoute... (1 min de débrief audio)'
                              : 'Écouter le débrief audio (1 min)'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Questions Detailed Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Détail des Questions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '10 questions',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Filter Segment Pills: Toutes (10), Erreurs (2), Réussies (8)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _FilterTab(
                          label: 'Toutes (10)',
                          selected: _filter == 'all',
                          onTap: () => setState(() => _filter = 'all'),
                        ),
                        _FilterTab(
                          label: 'Erreurs (2)',
                          selected: _filter == 'errors',
                          onTap: () => setState(() => _filter = 'errors'),
                        ),
                        _FilterTab(
                          label: 'Réussies (8)',
                          selected: _filter == 'success',
                          onTap: () => setState(() => _filter = 'success'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Question Breakdown Cards
                  if (_filter == 'all' || _filter == 'errors') ...[
                    // Error Question 6
                    _QuestionBreakdownCard(
                      id: 'Q6',
                      topic: 'Récursion & Arbre d\'appels',
                      question:
                          'Quelle est la profondeur maximale de récursion de la fonction fibonacci(n) naïve ?',
                      isError: true,
                      studentAnswer: 'A. O(2ⁿ)',
                      expectedAnswer: 'B. O(n)',
                      notion: 'Notion : Chapitre 2.3 • Pile d\'appels récursive',
                      pointsText: '0 pt',
                      aiExplanationExpanded:
                          _expandedAiExplanations.contains('Q6'),
                      onToggleAiExplanation: () => _toggleAiExplanation('Q6'),
                      aiExplanation:
                          'Attention à la confusion courante entre nombre total d\'appels et profondeur de la pile ! Bien que le nombre total de nœuds dans l\'arbre d\'appels de Fibonacci naïf soit O(2ⁿ), la profondeur maximale de récursion (la pile mémoire d\'exécution) n\'est que la hauteur maximale de cet arbre, c\'est-à-dire O(n).',
                    ),
                    const SizedBox(height: 12),

                    // Error Question 9
                    _QuestionBreakdownCard(
                      id: 'Q9',
                      topic: 'Arbres AVL & Équilibrage',
                      question:
                          'Après insertion avec facteur de balance +2 et enfant gauche -1, quelle rotation est requise ?',
                      isError: true,
                      studentAnswer: 'C. Simple rotation droite',
                      expectedAnswer: 'B. Double rotation gauche-droite',
                      notion: 'Notion : Chapitre 4.2 • Équilibrage dynamique AVL',
                      pointsText: '0 pt',
                      aiExplanationExpanded:
                          _expandedAiExplanations.contains('Q9'),
                      onToggleAiExplanation: () => _toggleAiExplanation('Q9'),
                      aiExplanation:
                          'Le motif (+2, -1) correspond au cas déséquilibré Gauche-Droite (Left-Right). Une simple rotation droite ne rétablirait pas l\'ordre strict car le sous-arbre intérieur violerait l\'équilibre. Une double rotation (rotation gauche sur l\'enfant, puis rotation droite sur le parent) est indispensable.',
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_filter == 'all' || _filter == 'success') ...[
                    // Successful Question 3 (featured in Stitch screen)
                    _QuestionBreakdownCard(
                      id: 'Q3',
                      topic: 'Analyse asymptotique',
                      question:
                          'Quelle est la complexité temporelle de l\'algorithme QuickSort dans le pire des cas ?',
                      isError: false,
                      studentAnswer: 'B. O(n²)',
                      expectedAnswer: 'B. O(n²)',
                      notion: 'Notion : Chapitre 1.4 • Partitionnement & Pivots',
                      pointsText: '+2 pts',
                      aiExplanationExpanded: false,
                      onToggleAiExplanation: () {},
                      aiExplanation:
                          'Parfaitement identifié ! Lorsque le pivot est systématiquement min ou max, le partitionnement se réduit à n-1 éléments à chaque niveau, donnant la série arithmétique de complexité O(n²).',
                    ),
                    const SizedBox(height: 12),

                    // Successful Question 1
                    _QuestionBreakdownCard(
                      id: 'Q1',
                      topic: 'Notions fondamentales',
                      question:
                          'Quelle est la complexité spatiale d\'une table de hachage contenant n éléments ?',
                      isError: false,
                      studentAnswer: 'A. O(n)',
                      expectedAnswer: 'A. O(n)',
                      notion: 'Notion : Chapitre 3.1 • Tables de hachage & Alvéoles',
                      pointsText: '+2 pts',
                      aiExplanationExpanded: false,
                      onToggleAiExplanation: () {},
                      aiExplanation:
                          'Exact : Le stockage linéaire de n éléments dans les alvéoles de la table requiert un espace O(n).',
                    ),
                    const SizedBox(height: 12),

                    // Successful Question 7
                    _QuestionBreakdownCard(
                      id: 'Q7',
                      topic: 'Tri & Complexité',
                      question:
                          'Quel algorithme de tri par comparaison possède une borne inférieure optimale de O(n log n) dans le pire des cas ?',
                      isError: false,
                      studentAnswer: 'B. Tri par fusion (MergeSort)',
                      expectedAnswer: 'B. Tri par fusion (MergeSort)',
                      notion: 'Notion : Chapitre 1.2 • Borne inférieure de tri',
                      pointsText: '+2 pts',
                      aiExplanationExpanded: false,
                      onToggleAiExplanation: () {},
                      aiExplanation:
                          'Excellent ! Le tri par fusion garantit O(n log n) dans tous les cas grâce au découpage équilibré en moitiés.',
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Bottom Return CTA Button
                  FilledButton.icon(
                    onPressed: () => context.go('/exams'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Retourner à mes examens'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;

  const _KpiMetricCard({
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeTextColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionBreakdownCard extends StatelessWidget {
  final String id;
  final String topic;
  final String question;
  final bool isError;
  final String studentAnswer;
  final String expectedAnswer;
  final String notion;
  final String pointsText;
  final bool aiExplanationExpanded;
  final VoidCallback onToggleAiExplanation;
  final String aiExplanation;

  const _QuestionBreakdownCard({
    required this.id,
    required this.topic,
    required this.question,
    required this.isError,
    required this.studentAnswer,
    required this.expectedAnswer,
    required this.notion,
    required this.pointsText,
    required this.aiExplanationExpanded,
    required this.onToggleAiExplanation,
    required this.aiExplanation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? colorScheme.error.withValues(alpha: 0.25)
              : colorScheme.tertiary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$id • $topic',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isError
                      ? colorScheme.errorContainer
                      : colorScheme.tertiaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  pointsText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isError ? colorScheme.onErrorContainer : colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isError) ...[
            // Incorrect student answer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel_rounded,
                      size: 16, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      studentAnswer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  Text(
                    'Ta réponse',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Correct answer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 16, color: colorScheme.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    expectedAnswer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.tertiary,
                    ),
                  ),
                ),
                Text(
                  isError ? 'Réponse attendue' : 'Bonne réponse (+2 pts)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Notion pill
          Row(
            children: [
              Icon(Icons.menu_book_rounded,
                  size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  notion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          if (isError) ...[
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: onToggleAiExplanation,
              icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
              label: Text(aiExplanationExpanded
                  ? 'Masquer l\'explication IA'
                  : 'Expliquer mon erreur avec l\'IA'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (aiExplanationExpanded) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_rounded,
                            size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Explication Pédagogique IA',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      aiExplanation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _RemediationCardItem extends StatelessWidget {
  final int number;
  final String title;
  final String concept;
  final String notion;

  const _RemediationCardItem({
    required this.number,
    required this.title,
    required this.concept,
    required this.notion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: colorScheme.primary,
                child: Text(
                  '$number',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            concept,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            notion,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  const _ScoreRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 12.0;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Gradient Progress Arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepGradient = SweepGradient(
      colors: [primaryColor, secondaryColor, tertiaryColor],
      startAngle: 0.0,
      endAngle: math.pi * 2,
    );
    final progressPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    const startAngle = -math.pi / 2;
    final sweepAngle = math.pi * 2 * progress;
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

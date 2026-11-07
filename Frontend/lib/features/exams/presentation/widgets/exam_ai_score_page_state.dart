part of '../pages/exam_ai_score_page.dart';
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
                    '3 Fiches de Rem├®diation Cibl├®es',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'G├®n├®r├®es automatiquement par l\'IA pour consolider vos points d\'am├®lioration.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _RemediationCardItem(
                number: 1,
                title: 'Profondeur de la pile d\'appels (Call Stack)',
                concept:
                    'Pour fibonacci(n), bien qu\'il y ait O(2Ôü┐) appels totaux, la pile m├®moire ne retient simultan├®ment que les appels actifs le long de la branche la plus profonde, soit une profondeur maximale O(n).',
                notion: 'Chapitre 2.3 ÔÇó R├®cursion & Arbre d\'appels',
              ),
              const SizedBox(height: 10),
              _RemediationCardItem(
                number: 2,
                title: 'Arbres AVL : Cas de d├®s├®quilibre Gauche-Droite',
                concept:
                    'Lorsqu\'un n┼ôud pr├®sente un facteur de balance +2 et que son enfant gauche a un facteur -1, une simple rotation droite ne suffit pas. Une double rotation gauche-droite (LR) est obligatoire pour restaurer la propri├®t├® AVL.',
                notion: 'Chapitre 4.2 ÔÇó ├ëquilibrage dynamique AVL',
              ),
              const SizedBox(height: 10),
              _RemediationCardItem(
                number: 3,
                title: 'M├®mo├»sation & Programmation Dynamique',
                concept:
                    'Pour ├®liminer la redondance des calculs r├®cursifs de Fibonacci et abaisser la complexit├® temporelle de O(2Ôü┐) ├á O(n), stockez chaque sous-probl├¿me r├®solu dans un tableau ou dictionnaire.',
                notion: 'Chapitre 5.1 ÔÇó Optimisation de la r├®cursivit├®',
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Enregistrer dans mes fiches de r├®vision'),
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
              'R├®sultats De L\'Examen',
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
                                    widget.courseContext.split('ÔÇó').first.trim(),
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
                                    widget.courseContext.contains('ÔÇó')
                                        ? widget.courseContext.split('ÔÇó').last.trim()
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
                            Text('ÔÇó',
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
                            Text('ÔÇó',
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
                                    'Tr├¿s Bien',
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
                                'Valid├® avec succ├¿s (+3.2 pts vs promo)',
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
                                label: 'R├®ussite',
                                value: '8 / 10',
                                badge: '80%',
                                badgeColor: colorScheme.tertiary,
                                badgeTextColor: colorScheme.onTertiary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _KpiMetricCard(
                                label: '├Ç revoir',
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
                              'Diagnostic instantan├®',
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
                                      TextSpan(text: 'ÔÇ£Tr├¿s bon travail, '),
                                      TextSpan(
                                        text: 'Salma',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                          text:
                                              ' ! Tu ma├«trises parfaitement la complexit├® asymptotique (QuickSort, arbres binaires). Pense ├á revoir le '),
                                      TextSpan(
                                        text:
                                            'Chapitre 2 sur la r├®cursivit├® et lÔÇÖarbre dÔÇÖappels',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                          text:
                                              ' ainsi que lÔÇÖ├®quilibrage des arbres AVL.ÔÇØ'),
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
                          label: const Text('G├®n├®rer 3 fiches de rem├®diation'),
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
                                  ? 'Lecture du d├®brief audio IA...'
                                  : 'D├®brief audio mis en pause.',
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
                              ? 'En ├®coute... (1 min de d├®brief audio)'
                              : '├ëcouter le d├®brief audio (1 min)'),
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
                        'D├®tail des Questions',
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

                  // Filter Segment Pills: Toutes (10), Erreurs (2), R├®ussies (8)
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
                          label: 'R├®ussies (8)',
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
                      topic: 'R├®cursion & Arbre d\'appels',
                      question:
                          'Quelle est la profondeur maximale de r├®cursion de la fonction fibonacci(n) na├»ve ?',
                      isError: true,
                      studentAnswer: 'A. O(2Ôü┐)',
                      expectedAnswer: 'B. O(n)',
                      notion: 'Notion : Chapitre 2.3 ÔÇó Pile d\'appels r├®cursive',
                      pointsText: '0 pt',
                      aiExplanationExpanded:
                          _expandedAiExplanations.contains('Q6'),
                      onToggleAiExplanation: () => _toggleAiExplanation('Q6'),
                      aiExplanation:
                          'Attention ├á la confusion courante entre nombre total d\'appels et profondeur de la pile ! Bien que le nombre total de n┼ôuds dans l\'arbre d\'appels de Fibonacci na├»f soit O(2Ôü┐), la profondeur maximale de r├®cursion (la pile m├®moire d\'ex├®cution) n\'est que la hauteur maximale de cet arbre, c\'est-├á-dire O(n).',
                    ),
                    const SizedBox(height: 12),

                    // Error Question 9
                    _QuestionBreakdownCard(
                      id: 'Q9',
                      topic: 'Arbres AVL & ├ëquilibrage',
                      question:
                          'Apr├¿s insertion avec facteur de balance +2 et enfant gauche -1, quelle rotation est requise ?',
                      isError: true,
                      studentAnswer: 'C. Simple rotation droite',
                      expectedAnswer: 'B. Double rotation gauche-droite',
                      notion: 'Notion : Chapitre 4.2 ÔÇó ├ëquilibrage dynamique AVL',
                      pointsText: '0 pt',
                      aiExplanationExpanded:
                          _expandedAiExplanations.contains('Q9'),
                      onToggleAiExplanation: () => _toggleAiExplanation('Q9'),
                      aiExplanation:
                          'Le motif (+2, -1) correspond au cas d├®s├®quilibr├® Gauche-Droite (Left-Right). Une simple rotation droite ne r├®tablirait pas l\'ordre strict car le sous-arbre int├®rieur violerait l\'├®quilibre. Une double rotation (rotation gauche sur l\'enfant, puis rotation droite sur le parent) est indispensable.',
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_filter == 'all' || _filter == 'success') ...[
                    // Successful Question 3 (featured in Stitch screen)
                    _QuestionBreakdownCard(
                      id: 'Q3',
                      topic: 'Analyse asymptotique',
                      question:
                          'Quelle est la complexit├® temporelle de l\'algorithme QuickSort dans le pire des cas ?',
                      isError: false,
                      studentAnswer: 'B. O(n┬▓)',
                      expectedAnswer: 'B. O(n┬▓)',
                      notion: 'Notion : Chapitre 1.4 ÔÇó Partitionnement & Pivots',
                      pointsText: '+2 pts',
                      aiExplanationExpanded: false,
                      onToggleAiExplanation: () {},
                      aiExplanation:
                          'Parfaitement identifi├® ! Lorsque le pivot est syst├®matiquement min ou max, le partitionnement se r├®duit ├á n-1 ├®l├®ments ├á chaque niveau, donnant la s├®rie arithm├®tique de complexit├® O(n┬▓).',
                    ),
                    const SizedBox(height: 12),

                    // Successful Question 1
                    _QuestionBreakdownCard(
                      id: 'Q1',
                      topic: 'Notions fondamentales',
                      question:
                          'Quelle est la complexit├® spatiale d\'une table de hachage contenant n ├®l├®ments ?',
                      isError: false,
                      studentAnswer: 'A. O(n)',
                      expectedAnswer: 'A. O(n)',
                      notion: 'Notion : Chapitre 3.1 ÔÇó Tables de hachage & Alv├®oles',
                      pointsText: '+2 pts',
                      aiExplanationExpanded: false,
                      onToggleAiExplanation: () {},
                      aiExplanation:
                          'Exact : Le stockage lin├®aire de n ├®l├®ments dans les alv├®oles de la table requiert un espace O(n).',
                    ),
                    const SizedBox(height: 12),

                    // Successful Question 7
                    _QuestionBreakdownCard(
                      id: 'Q7',
                      topic: 'Tri & Complexit├®',
                      question:
                          'Quel algorithme de tri par comparaison poss├¿de une borne inf├®rieure optimale de O(n log n) dans le pire des cas ?',
                      isError: false,
                      studentAnswer: 'B. Tri par fusion (MergeSort)',
                      expectedAnswer: 'B. Tri par fusion (MergeSort)',
                      notion: 'Notion : Chapitre 1.2 ÔÇó Borne inf├®rieure de tri',
                      pointsText: '+2 pts',
                      aiExplanationExpanded: false,
                      onToggleAiExplanation: () {},
                      aiExplanation:
                          'Excellent ! Le tri par fusion garantit O(n log n) dans tous les cas gr├óce au d├®coupage ├®quilibr├® en moiti├®s.',
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Bottom Return CTA Button
                  FilledButton.icon(
                    onPressed: () => context.go('/exams'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Retourner ├á mes examens'),
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


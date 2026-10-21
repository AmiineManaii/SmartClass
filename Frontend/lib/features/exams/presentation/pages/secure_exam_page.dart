import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/extensions.dart';
import 'exam_ai_score_page.dart';

class ExamQuestionItem {
  final String id;
  final String topic;
  final String question;
  final String hint;
  final List<String> options;
  final int correctIndex;
  final int points;

  const ExamQuestionItem({
    required this.id,
    required this.topic,
    required this.question,
    required this.hint,
    required this.options,
    required this.correctIndex,
    this.points = 2,
  });
}

class SecureExamPage extends StatefulWidget {
  final String? examTitle;
  final String? courseContext;

  const SecureExamPage({
    super.key,
    this.examTitle,
    this.courseContext,
  });

  @override
  State<SecureExamPage> createState() => _SecureExamPageState();
}

class _SecureExamPageState extends State<SecureExamPage> {
  int _currentIndex = 2; // Default to Question 3 (index 2) matching Stitch screen
  final Map<int, int> _selectedAnswers = {
    0: 0,
    1: 1,
    2: 1, // Option B selected on Q3
    3: 0,
    4: 2,
    5: 0, // Q6 answered incorrectly (A instead of B)
    6: 1,
    7: 2,
    8: 2, // Q9 answered incorrectly (C instead of B)
    9: 0,
  };

  Timer? _timer;
  int _remainingSeconds = 24 * 60 + 15; // 24:15

  static const List<ExamQuestionItem> _questions = [
    ExamQuestionItem(
      id: 'Q1',
      topic: 'Notions fondamentales',
      question: 'Quelle est la complexité spatiale d\'une table de hachage contenant n éléments ?',
      hint: 'Considérer le stockage de l\'ensemble des alvéoles et des listes de collision.',
      options: ['O(n)', 'O(1)', 'O(n²)', 'O(log n)'],
      correctIndex: 0,
    ),
    ExamQuestionItem(
      id: 'Q2',
      topic: 'Structures linéaires',
      question: 'Quel est le coût temporel d\'accès au k-ième élément dans une liste simplement chaînée ?',
      hint: 'Le parcours nécessite de suivre chaque pointeur successivement depuis la tête.',
      options: ['O(1)', 'O(k)', 'O(log k)', 'O(k²)'],
      correctIndex: 1,
    ),
    ExamQuestionItem(
      id: 'Q3',
      topic: 'Analyse asymptotique',
      question: 'Quelle est la complexité temporelle de l\'algorithme QuickSort dans le pire des cas ?',
      hint: 'Cas particulier où le pivot choisi lors du partitionnement est systématiquement l\'élément minimum ou maximum.',
      options: ['O(n log n)', 'O(n²)', 'O(log n)', 'O(n)'],
      correctIndex: 1,
    ),
    ExamQuestionItem(
      id: 'Q4',
      topic: 'Arbres binaires',
      question: 'Dans un arbre binaire de recherche équilibré, quelle est la hauteur maximale en fonction de n ?',
      hint: 'La propriété d\'équilibre garantit que la profondeur reste logarithmique.',
      options: ['O(n)', 'O(n²)', 'O(log n)', 'O(1)'],
      correctIndex: 2,
    ),
    ExamQuestionItem(
      id: 'Q5',
      topic: 'Graphes & Algorithmes',
      question: 'Quelle structure de données est utilisée pour implémenter un parcours en largeur (BFS) ?',
      hint: 'Principe FIFO (First In, First Out).',
      options: ['Pile (Stack)', 'File de priorité', 'File (Queue)', 'Arbre AVL'],
      correctIndex: 2,
    ),
    ExamQuestionItem(
      id: 'Q6',
      topic: 'Récursion & Arbre d\'appels',
      question: 'Quelle est la profondeur maximale de récursion de la fonction fibonacci(n) naïve ?',
      hint: 'La pile d\'appels correspond à la plus longue branche de l\'arbre d\'exécution.',
      options: ['O(2ⁿ)', 'O(n)', 'O(log n)', 'O(n²)'],
      correctIndex: 1,
    ),
    ExamQuestionItem(
      id: 'Q7',
      topic: 'Tri & Complexité',
      question: 'Quel algorithme de tri par comparaison possède une borne inférieure optimale de O(n log n) dans le pire des cas ?',
      hint: 'Algorithme diviser pour régner avec étape de fusion ordonnée.',
      options: ['Tri à bulles', 'Tri par fusion (MergeSort)', 'Tri par sélection', 'Tri rapide naïf'],
      correctIndex: 1,
    ),
    ExamQuestionItem(
      id: 'Q8',
      topic: 'Structures de tas',
      question: 'Quelle est la complexité d\'extraction du minimum (extract-min) dans un tas binaire ?',
      hint: 'Suppression de la racine suivie de l\'opération d\'entassement (heapify-down).',
      options: ['O(1)', 'O(n)', 'O(log n)', 'O(n log n)'],
      correctIndex: 2,
    ),
    ExamQuestionItem(
      id: 'Q9',
      topic: 'Arbres AVL & Équilibrage',
      question: 'Après insertion avec facteur de balance +2 et enfant gauche -1, quelle rotation est requise ?',
      hint: 'Cas déséquilibré gauche-droite nécessitant une double rotation.',
      options: ['Simple rotation gauche', 'Double rotation gauche-droite', 'Simple rotation droite', 'Aucune rotation'],
      correctIndex: 1,
    ),
    ExamQuestionItem(
      id: 'Q10',
      topic: 'Algorithmes gloutons',
      question: 'L\'algorithme de Dijkstra garantit-il le chemin le plus court en présence d\'arcs à poids négatifs ?',
      hint: 'Les poids négatifs peuvent invalider le choix glouton déjà fixé.',
      options: ['Non, jamais', 'Oui, toujours', 'Uniquement pour les graphes bipartis', 'Uniquement sans cycles'],
      correctIndex: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _finishExam();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _selectOption(int optionIndex) {
    setState(() {
      _selectedAnswers[_currentIndex] = optionIndex;
    });
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _confirmFinishExam();
    }
  }

  void _confirmFinishExam() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer l\'examen ?'),
        content: Text(
          'Vous avez répondu à ${_selectedAnswers.length} questions sur ${_questions.length}.\n'
          'Une fois l\'examen soumis, l\'évaluation IA analysera vos réponses et générera votre rapport.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuer l\'examen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _finishExam();
            },
            child: const Text('Soumettre & Voir mon Score'),
          ),
        ],
      ),
    );
  }

  void _finishExam() {
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ExamAiScorePage(
          examTitle: widget.examTitle ??
              'Examen Continu : Complexité & Structures Arborescentes',
          courseContext:
              widget.courseContext ?? 'Licence 3 Informatique • Algorithmique Avancée',
        ),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la session d\'examen ?'),
        content: const Text(
          'Attention : Le protocole anti-fraude enregistrera un abandon prématuré si vous quittez cette page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Rester'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('Quitter quand même'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.screenWidth >= 1024;
    final q = _questions[_currentIndex];
    final selectedOption = _selectedAnswers[_currentIndex];
    final totalQuestions = _questions.length;
    final progress = (_currentIndex + 1) / totalQuestions;
    final remainingQuestions = totalQuestions - (_currentIndex + 1);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _confirmExit,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Active Exam Session',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Locked Proctoring Active',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded,
                    size: 16, color: colorScheme.tertiary),
                const SizedBox(width: 6),
                Icon(Icons.videocam_rounded,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Icon(Icons.lock_rounded,
                    size: 16, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
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
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Live Security Telemetry & Timer Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colorScheme.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.shield_rounded,
                                      size: 15, color: colorScheme.tertiary),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'Mode Anti-fraude Actif',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: colorScheme.tertiary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Détection d\'onglet & écran scellé',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 16, color: colorScheme.secondary),
                              const SizedBox(width: 6),
                              Text(
                                _formatTimer(_remainingSeconds),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Course Context Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryFixed,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.courseContext?.split('•').first.trim() ??
                              'Licence 3 Informatique',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryFixed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('•',
                          style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.courseContext?.contains('•') == true
                              ? widget.courseContext!.split('•').last.trim()
                              : 'Algorithmique Avancée',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.examTitle ??
                        'Examen Continu : Complexité & Structures Arborescentes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar & Question Meta
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Question ${_currentIndex + 1}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'sur $totalQuestions',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${q.points} points',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Choix unique',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: colorScheme.surfaceContainerHigh,
                            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progression : ${(progress * 100).toInt()}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              remainingQuestions == 0
                                  ? 'Dernière question'
                                  : '$remainingQuestions restantes',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Main Question Card
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
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryFixed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  q.id,
                                  style: TextStyle(
                                    color: colorScheme.onPrimaryFixed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                q.topic,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          q.question,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Context Note Hint Pill
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 18, color: colorScheme.secondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  q.hint,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Interactive Answer Radio Options A, B, C, D
                        for (int i = 0; i < q.options.length; i++) ...[
                          _OptionRadioCard(
                            letter: String.fromCharCode(65 + i),
                            text: q.options[i],
                            selected: selectedOption == i,
                            onTap: () => _selectOption(i),
                          ),
                          if (i < q.options.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Security Protocol Assurance Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 20, color: colorScheme.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Protocole d\'intégrité actif : Quitter l\'application, changer d\'écran ou effectuer une capture déclenche un signalement automatique et invalidera la session.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom Navigation Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _currentIndex > 0 ? _previousQuestion : null,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Précédente'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _nextQuestion,
                          icon: Icon(
                            _currentIndex == totalQuestions - 1
                                ? Icons.check_circle_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _currentIndex == totalQuestions - 1
                                ? 'Terminer l\'examen'
                                : 'Suivante',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _OptionRadioCard extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRadioCard({
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.surfaceContainerLow
          : colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: selected ? 0.06 : 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: selected ? Colors.white : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? colorScheme.primary : colorScheme.onSurface,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? colorScheme.primaryFixed
                      : colorScheme.surfaceContainerHigh,
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? colorScheme.primary : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

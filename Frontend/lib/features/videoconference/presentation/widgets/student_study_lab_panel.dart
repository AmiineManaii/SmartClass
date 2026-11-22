import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/smart_toast.dart';
import '../../application/recording_providers.dart';
import '../../domain/entities/recording_models.dart';
import 'lesson_text_formatter.dart';

class StudentStudyLabPanel extends ConsumerStatefulWidget {
  final String sessionId;
  final LessonPackageEntity lessonPackage;
  final List<StudentStudyArtifactEntity> initialArtifacts;
  final List<StudentQuizAttemptEntity> initialQuizAttempts;
  final VoidCallback onRefreshWorkspace;
  final int? requestedModeIndex;
  final int modeRequestVersion;

  const StudentStudyLabPanel({
    super.key,
    required this.sessionId,
    required this.lessonPackage,
    required this.initialArtifacts,
    required this.initialQuizAttempts,
    required this.onRefreshWorkspace,
    this.requestedModeIndex,
    this.modeRequestVersion = 0,
  });

  @override
  ConsumerState<StudentStudyLabPanel> createState() =>
      _StudentStudyLabPanelState();
}

class _StudentStudyLabPanelState extends ConsumerState<StudentStudyLabPanel> {
  late int _modeIndex; // 0: Summaries, 1: Quiz, 2: Flashcards
  String _summaryStyle = 'medium';
  String _selectedLanguage = 'fr';
  String? _selectedChapterTitle;
  bool _isGenerating = false;

  // Quiz state
  String? _selectedQuizArtifactId; // null => Teacher's official quiz
  StudentStudyArtifactEntity? _latestGeneratedQuiz;
  String _quizDifficulty = 'moyen';
  int _quizQuestionCount = 5;
  final Map<int, int> _selectedAnswers = {};
  StudentQuizAttemptEntity? _latestQuizResult;

  // Flashcard state
  int _cardIndex = 0;
  bool _isCardFlipped = false;
  final Set<int> _masteredCards = {};
  List<LessonFlashcardEntity>? _customFlashcards;

  @override
  void initState() {
    super.initState();
    _modeIndex = (widget.requestedModeIndex ?? 0).clamp(0, 2);
  }

  @override
  void didUpdateWidget(covariant StudentStudyLabPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.modeRequestVersion != oldWidget.modeRequestVersion &&
        widget.requestedModeIndex != null) {
      _modeIndex = widget.requestedModeIndex!.clamp(0, 2);
    }
  }

  List<StudentStudyArtifactEntity> get _customQuizArtifacts {
    final map = <String, StudentStudyArtifactEntity>{};
    for (final a in widget.initialArtifacts) {
      if (a.artifactType == 'QUIZ' && !a.isTeacherBackingArtifact) {
        map[a.id] = a;
      }
    }
    if (_latestGeneratedQuiz != null &&
        _latestGeneratedQuiz!.artifactType == 'QUIZ' &&
        !_latestGeneratedQuiz!.isTeacherBackingArtifact) {
      map[_latestGeneratedQuiz!.id] = _latestGeneratedQuiz!;
    }
    return map.values.toList();
  }

  List<LessonQuizQuestionEntity> get _activeQuestions {
    if (_selectedQuizArtifactId != null) {
      final matching = _customQuizArtifacts
          .where((a) => a.id == _selectedQuizArtifactId)
          .toList();
      if (matching.isNotEmpty) {
        final qList = matching.first.contentJson['questions'];
        if (qList is List) {
          return qList
              .whereType<Map<String, dynamic>>()
              .map(LessonQuizQuestionEntity.fromJson)
              .toList();
        }
      }
    }
    return widget.lessonPackage.quizQuestions;
  }

  List<LessonFlashcardEntity> get _activeFlashcards =>
      _customFlashcards ?? widget.lessonPackage.flashcards;

  void _selectQuizSet(String? artifactId) {
    setState(() {
      _selectedQuizArtifactId = artifactId;
      _selectedAnswers.clear();
      _latestQuizResult = null;
    });
  }

  Future<void> _generateArtifact(String type) async {
    setState(() => _isGenerating = true);
    try {
      final ds = ref.read(recordingRemoteDataSourceProvider);
      final artifact = await ds.generateStudyArtifact(
        sessionId: widget.sessionId,
        artifactType: type,
        style: _summaryStyle,
        chapterTitle: _selectedChapterTitle,
        difficulty: type == 'QUIZ' ? _quizDifficulty : 'moyen',
        language: _selectedLanguage,
        count: type == 'FLASHCARDS'
            ? 8
            : (type == 'QUIZ' ? _quizQuestionCount : 5),
      );

      if (!mounted) return;
      final qList = artifact.contentJson['questions'];
      final cList =
          artifact.contentJson['flashcards'] ?? artifact.contentJson['cards'];
      if (type == 'QUIZ' && qList is List) {
        setState(() {
          _latestGeneratedQuiz = artifact;
          _selectedQuizArtifactId = artifact.id;
          _selectedAnswers.clear();
          _latestQuizResult = null;
        });
        SmartToast.success(
          context,
          'Nouveau quiz IA généré (${qList.length} questions inédites).',
          title: 'Nouveau Quiz IA',
        );
      } else if (type == 'FLASHCARDS' && cList is List) {
        setState(() {
          _customFlashcards = cList
              .whereType<Map<String, dynamic>>()
              .map(LessonFlashcardEntity.fromJson)
              .toList();
          _cardIndex = 0;
          _isCardFlipped = false;
        });
      } else if (type == 'SUMMARY') {
        SmartToast.success(
          context,
          'Synthèse personnalisée générée avec succès.',
          title: 'Synthèse IA',
        );
      }
      widget.onRefreshWorkspace();
    } catch (e) {
      if (mounted) {
        SmartToast.error(
          context,
          '${context.tr('error')}: $e',
          title: 'Génération',
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _submitQuiz() async {
    final questions = _activeQuestions;
    if (questions.isEmpty) return;

    setState(() => _isGenerating = true);
    try {
      final ds = ref.read(recordingRemoteDataSourceProvider);
      final answersPayload = <Map<String, dynamic>>[];
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        final selIdx = _selectedAnswers[i] ?? -1;
        final ansStr = (selIdx >= 0 && selIdx < q.options.length)
            ? q.options[selIdx]
            : '';
        answersPayload.add({
          'questionId': q.id.isNotEmpty ? q.id : 'q_${i + 1}',
          'answer': ansStr,
          'questionIndex': i,
          'selectedIndex': selIdx,
        });
      }
      final attempt = await ds.submitQuizAttempt(
        sessionId: widget.sessionId,
        artifactId: _selectedQuizArtifactId ?? 'teacher_default',
        answers: answersPayload,
      );
      if (mounted) {
        setState(() => _latestQuizResult = attempt);
        SmartToast.success(
          context,
          'Quiz soumis avec succès ! Score calculé.',
          title: 'Quiz complété',
        );
        widget.onRefreshWorkspace();
      }
    } catch (e) {
      if (mounted) {
        SmartToast.error(
          context,
          '${context.tr('error')}: $e',
          title: 'Erreur',
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teacherQuizCount = widget.lessonPackage.quizQuestions.length;
    final customQuizzesCount = _customQuizArtifacts.length;
    final flashcardCount = widget.lessonPackage.flashcards.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text(context.tr('study_lab_summary_title')),
              ),
              ButtonSegment(
                value: 1,
                icon: const Icon(Icons.quiz_outlined, size: 16),
                label: Text(
                  teacherQuizCount > 0 || customQuizzesCount > 0
                      ? '${context.tr('study_lab_quiz_title')} ($teacherQuizCount)'
                      : context.tr('study_lab_quiz_title'),
                ),
              ),
              ButtonSegment(
                value: 2,
                icon: const Icon(Icons.style_outlined, size: 16),
                label: Text(
                  flashcardCount > 0
                      ? '${context.tr('study_lab_flashcards_title')} ($flashcardCount)'
                      : context.tr('study_lab_flashcards_title'),
                ),
              ),
            ],
            selected: {_modeIndex},
            onSelectionChanged: (s) => setState(() => _modeIndex = s.first),
          ),
        ),
        if (_isGenerating) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: IndexedStack(
            index: _modeIndex,
            children: [
              _buildSummariesTab(theme),
              _buildQuizTab(theme),
              _buildFlashcardsTab(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummariesTab(ThemeData theme) {
    final summaries = widget.initialArtifacts
        .where((a) => a.artifactType == 'SUMMARY')
        .toList();
    final officialSummary = sanitizeLessonDisplayText(
      widget.lessonPackage.detailedSummary.isNotEmpty
          ? widget.lessonPackage.detailedSummary
          : widget.lessonPackage.shortSummary,
    );

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Paramètres de synthèse & Langue IA',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _styleChip('short', context.tr('study_lab_summary_short')),
                  _styleChip('medium', context.tr('study_lab_summary_medium')),
                  _styleChip(
                    'detailed',
                    context.tr('study_lab_summary_detailed'),
                  ),
                  _styleChip('exam', context.tr('study_lab_summary_exam')),
                  _styleChip('eli15', context.tr('study_lab_summary_eli15')),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _langChip('fr', '🇫🇷 Français'),
                  _langChip('ar-TN', '🇹🇳 Tounsi (Derja)'),
                  _langChip('ar', '🇸🇦 العربية'),
                  _langChip('en', '🇬🇧 English'),
                ],
              ),
              if (widget.lessonPackage.chapters.isNotEmpty) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedChapterTitle,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: context.tr('replay_chapters_title'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Toute la séance'),
                    ),
                    ...widget.lessonPackage.chapters.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.title,
                        child: Text(c.title, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedChapterTitle = v),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(context.tr('study_lab_generate_summary')),
                  onPressed:
                      _isGenerating ? null : () => _generateArtifact('SUMMARY'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lessonPackage.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                MarkdownBody(
                  data: officialSummary.isNotEmpty
                      ? officialSummary
                      : '*Synthèse officielle en attente.*',
                  selectable: true,
                ),
              ],
            ),
          ),
        ),
        ...summaries.map((art) {
          final rawText = (art.contentJson['summary'] ??
                  art.contentJson['text'] ??
                  art.contentJson['markdown'] ??
                  '')
              .toString();
          final formatted = sanitizeLessonDisplayText(rawText);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    art.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  MarkdownBody(
                    data: formatted,
                    selectable: true,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _styleChip(String key, String label) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      selected: _summaryStyle == key,
      onSelected: (_) => setState(() => _summaryStyle = key),
    );
  }

  Widget _langChip(String code, String label) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: _selectedLanguage == code,
      onSelected: (_) => setState(() => _selectedLanguage = code),
    );
  }

  Widget _buildQuizTab(ThemeData theme) {
    final questions = _activeQuestions;
    final customQuizzes = _customQuizArtifacts;
    final isTeacherQuiz = _selectedQuizArtifactId == null;
    final weakTopics = _latestQuizResult?.weakTopics ??
        (widget.initialQuizAttempts.isNotEmpty
            ? widget.initialQuizAttempts.first.weakTopics
            : const <String>[]);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // 1. Quiz Set Switcher: Official Teacher Quiz vs Student-Generated AI Quizzes
        Text(
          'Sélectionner un quiz',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ChoiceChip(
              key: const Key('quiz_selector_teacher'),
              avatar: const Icon(
                Icons.verified_rounded,
                size: 16,
                color: Color(0xFF10B981),
              ),
              label: Text(
                'Quiz de l\'enseignant (${widget.lessonPackage.quizQuestions.length} Q)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              selected: isTeacherQuiz,
              onSelected: (_) => _selectQuizSet(null),
            ),
            ...customQuizzes.asMap().entries.map((entry) {
              final idx = entry.key;
              final art = entry.value;
              final rawQs = art.contentJson['questions'];
              final qCount = rawQs is List ? rawQs.length : 0;
              return ChoiceChip(
                key: Key('quiz_selector_custom_${art.id}'),
                avatar: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 15,
                  color: Color(0xFF60A5FA),
                ),
                label: Text(
                  qCount > 0 ? art.title : 'Quiz IA #${idx + 1}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: _selectedQuizArtifactId == art.id,
                onSelected: (_) => _selectQuizSet(art.id),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),

        // 2. Generate a Brand-New Distinct Student AI Quiz
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.psychology_alt_rounded,
                    size: 18,
                    color: Color(0xFF60A5FA),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Générer un nouveau quiz IA (questions inédites)',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'L\'IA crée de nouvelles questions basées sur le cours, différentes du quiz de l\'enseignant.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Facile', style: TextStyle(fontSize: 11)),
                    selected: _quizDifficulty == 'facile',
                    onSelected: (_) =>
                        setState(() => _quizDifficulty = 'facile'),
                  ),
                  ChoiceChip(
                    label: const Text('Moyen', style: TextStyle(fontSize: 11)),
                    selected: _quizDifficulty == 'moyen',
                    onSelected: (_) =>
                        setState(() => _quizDifficulty = 'moyen'),
                  ),
                  ChoiceChip(
                    label:
                        const Text('Difficile', style: TextStyle(fontSize: 11)),
                    selected: _quizDifficulty == 'difficile',
                    onSelected: (_) =>
                        setState(() => _quizDifficulty = 'difficile'),
                  ),
                  const SizedBox(width: 6),
                  for (final count in [3, 5, 8])
                    ChoiceChip(
                      label: Text('$count Q', style: const TextStyle(fontSize: 11)),
                      selected: _quizQuestionCount == count,
                      onSelected: (_) =>
                          setState(() => _quizQuestionCount = count),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _langChip('fr', '🇫🇷 Français'),
                  _langChip('ar-TN', '🇹🇳 Tounsi'),
                  _langChip('ar', '🇸🇦 العربية'),
                  _langChip('en', '🇬🇧 English'),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  key: const Key('generate_new_student_quiz_btn'),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Générer un nouveau quiz IA'),
                  onPressed:
                      _isGenerating ? null : () => _generateArtifact('QUIZ'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Active Quiz Header + Score / Reset
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isTeacherQuiz
                          ? const Color(0xFF10B981)
                          : const Color(0xFF3B82F6))
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isTeacherQuiz
                      ? 'Quiz validé par l\'enseignant (${questions.length} Q)'
                      : 'Quiz IA personnalisé (${questions.length} Q)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isTeacherQuiz
                        ? const Color(0xFF10B981)
                        : const Color(0xFF60A5FA),
                  ),
                ),
              ),
            ),
            if (_latestQuizResult != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    avatar: const Icon(Icons.emoji_events_rounded, size: 16),
                    label: Text(
                      'Score: ${_latestQuizResult!.score.toStringAsFixed(0)}% (${_latestQuizResult!.correctCount}/${_latestQuizResult!.totalQuestions})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    icon: const Icon(Icons.replay_rounded, size: 15),
                    label: const Text('Recommencer'),
                    onPressed: () => setState(() {
                      _selectedAnswers.clear();
                      _latestQuizResult = null;
                    }),
                  ),
                ],
              ),
          ],
        ),

        if (weakTopics.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Wrap(
              spacing: 6,
              children: weakTopics
                  .map(
                    (t) => Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        sanitizeLessonDisplayText(t),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 10),

        if (questions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucun quiz officiel publié pour cette séance. Utilisez le générateur ci-dessus pour créer un quiz IA sur mesure.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else ...[
          ...List.generate(questions.length, (qIdx) {
            final q = questions[qIdx];
            final chosen = _selectedAnswers[qIdx];
            final showCorrection = _latestQuizResult != null;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${qIdx + 1}. ${sanitizeLessonDisplayText(q.question)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(q.options.length, (optIdx) {
                      final isSelected = chosen == optIdx;
                      final isCorrect = q.correctIndex == optIdx;
                      Color? tileColor;
                      if (showCorrection) {
                        if (isCorrect) {
                          tileColor = Colors.green.withValues(alpha: 0.15);
                        } else if (isSelected && !isCorrect) {
                          tileColor = Colors.red.withValues(alpha: 0.15);
                        }
                      }
                      return ListTile(
                        dense: true,
                        tileColor: tileColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 20,
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          sanitizeLessonDisplayText(q.options[optIdx]),
                        ),
                        onTap: () =>
                            setState(() => _selectedAnswers[qIdx] = optIdx),
                      );
                    }),
                    if (showCorrection && q.explanation.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '💡 ${sanitizeLessonDisplayText(q.explanation)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(context.tr('study_lab_submit_quiz')),
            onPressed: _isGenerating ? null : _submitQuiz,
          ),
        ],
      ],
    );
  }

  Widget _buildFlashcardsTab(ThemeData theme) {
    final cards = _activeFlashcards;
    if (cards.isEmpty) {
      return Center(
        child: FilledButton.icon(
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(context.tr('study_lab_generate_flashcards')),
          onPressed:
              _isGenerating ? null : () => _generateArtifact('FLASHCARDS'),
        ),
      );
    }

    final safeIdx = _cardIndex.clamp(0, cards.length - 1);
    final card = cards[safeIdx];
    final isMastered = _masteredCards.contains(safeIdx);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carte ${safeIdx + 1} / ${cards.length} • ${_masteredCards.length} ${context.tr('study_lab_flashcard_known')}',
                style: theme.textTheme.labelLarge,
              ),
              TextButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                label: Text(context.tr('study_lab_generate_flashcards')),
                onPressed: _isGenerating
                    ? null
                    : () => _generateArtifact('FLASHCARDS'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCardFlipped = !_isCardFlipped),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _isCardFlipped
                      ? theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.45)
                      : theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isMastered
                        ? Colors.green
                        : const Color(0xFF2563EB).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (card.chapterTitle != null &&
                        card.chapterTitle!.isNotEmpty)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          sanitizeLessonDisplayText(card.chapterTitle!),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Text(
                      sanitizeLessonDisplayText(
                        _isCardFlipped ? card.back : card.front,
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('study_lab_flashcard_flip'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.outlined(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: safeIdx > 0
                    ? () => setState(() {
                          _cardIndex = safeIdx - 1;
                          _isCardFlipped = false;
                        })
                    : null,
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.replay_rounded, size: 16),
                    label: Text(context.tr('study_lab_flashcard_review')),
                    onPressed: () =>
                        setState(() => _masteredCards.remove(safeIdx)),
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(context.tr('study_lab_flashcard_known')),
                    onPressed: () =>
                        setState(() => _masteredCards.add(safeIdx)),
                  ),
                ],
              ),
              IconButton.outlined(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: safeIdx < cards.length - 1
                    ? () => setState(() {
                          _cardIndex = safeIdx + 1;
                          _isCardFlipped = false;
                        })
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/recording_providers.dart';
import '../../domain/entities/recording_models.dart';

class StudentStudyLabPanel extends ConsumerStatefulWidget {
  final String sessionId;
  final LessonPackageEntity lessonPackage;
  final List<StudentStudyArtifactEntity> initialArtifacts;
  final List<StudentQuizAttemptEntity> initialQuizAttempts;
  final VoidCallback onRefreshWorkspace;

  const StudentStudyLabPanel({
    super.key,
    required this.sessionId,
    required this.lessonPackage,
    required this.initialArtifacts,
    required this.initialQuizAttempts,
    required this.onRefreshWorkspace,
  });

  @override
  ConsumerState<StudentStudyLabPanel> createState() =>
      _StudentStudyLabPanelState();
}

class _StudentStudyLabPanelState extends ConsumerState<StudentStudyLabPanel> {
  int _modeIndex = 0; // 0: Summaries, 1: Quiz, 2: Flashcards
  String _summaryStyle = 'medium';
  String _selectedLanguage = 'fr';
  String? _selectedChapterTitle;
  bool _isGenerating = false;

  // Quiz state
  final Map<int, int> _selectedAnswers = {};
  StudentQuizAttemptEntity? _latestQuizResult;
  List<LessonQuizQuestionEntity>? _customQuizQuestions;

  // Flashcard state
  int _cardIndex = 0;
  bool _isCardFlipped = false;
  final Set<int> _masteredCards = {};
  List<LessonFlashcardEntity>? _customFlashcards;

  List<LessonQuizQuestionEntity> get _activeQuestions =>
      _customQuizQuestions ?? widget.lessonPackage.quizQuestions;

  List<LessonFlashcardEntity> get _activeFlashcards =>
      _customFlashcards ?? widget.lessonPackage.flashcards;

  Future<void> _generateArtifact(String type) async {
    setState(() => _isGenerating = true);
    try {
      final ds = ref.read(recordingRemoteDataSourceProvider);
      final artifact = await ds.generateStudyArtifact(
        sessionId: widget.sessionId,
        artifactType: type,
        style: _summaryStyle,
        chapterTitle: _selectedChapterTitle,
        difficulty: 'moyen',
        language: _selectedLanguage,
        count: type == 'FLASHCARDS' ? 8 : 5,
      );

      if (!mounted) return;
      final qList = artifact.contentJson['questions'];
      final cList =
          artifact.contentJson['flashcards'] ?? artifact.contentJson['cards'];
      if (type == 'QUIZ' && qList is List) {
        setState(() {
          _customQuizQuestions = qList
              .whereType<Map<String, dynamic>>()
              .map(LessonQuizQuestionEntity.fromJson)
              .toList();
          _selectedAnswers.clear();
          _latestQuizResult = null;
        });
      } else if (type == 'FLASHCARDS' && cList is List) {
        setState(() {
          _customFlashcards = cList
              .whereType<Map<String, dynamic>>()
              .map(LessonFlashcardEntity.fromJson)
              .toList();
          _cardIndex = 0;
          _isCardFlipped = false;
        });
      }
      widget.onRefreshWorkspace();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e')),
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
        answers: answersPayload,
      );
      if (mounted) {
        setState(() => _latestQuizResult = attempt);
        widget.onRefreshWorkspace();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                label: Text(context.tr('study_lab_quiz_title')),
              ),
              ButtonSegment(
                value: 2,
                icon: const Icon(Icons.style_outlined, size: 16),
                label: Text(context.tr('study_lab_flashcards_title')),
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

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Stitch "Paramètres de synthèse IA" Card
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
                  _styleChip('detailed', context.tr('study_lab_summary_detailed')),
                  _styleChip('exam', context.tr('study_lab_summary_exam')),
                  _styleChip('eli15', context.tr('study_lab_summary_eli15')),
                ],
              ),
              const SizedBox(height: 10),
              // Multilingual / Tunisian Derja selector
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
                Text(
                  widget.lessonPackage.detailedSummary.isNotEmpty
                      ? widget.lessonPackage.detailedSummary
                      : widget.lessonPackage.shortSummary,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ),
        ...summaries.map(
          (art) => Card(
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
                  const SizedBox(height: 6),
                  Text(
                    (art.contentJson['summary'] ??
                            art.contentJson['text'] ??
                            art.contentJson['markdown'] ??
                            '')
                        .toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ),
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
    final weakTopics = _latestQuizResult?.weakTopics ??
        (widget.initialQuizAttempts.isNotEmpty
            ? widget.initialQuizAttempts.first.weakTopics
            : const <String>[]);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_latestQuizResult != null)
              Chip(
                avatar: const Icon(Icons.emoji_events_rounded, size: 16),
                label: Text(
                  'Score: ${_latestQuizResult!.score.toStringAsFixed(0)}% (${_latestQuizResult!.correctCount}/${_latestQuizResult!.totalQuestions})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            else
              const SizedBox.shrink(),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(context.tr('study_lab_generate_quiz')),
              onPressed: _isGenerating ? null : () => _generateArtifact('QUIZ'),
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
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 10),
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
                    'Q${qIdx + 1}. ${q.question}',
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
                      title: Text(q.options[optIdx]),
                      onTap: () =>
                          setState(() => _selectedAnswers[qIdx] = optIdx),
                    );
                  }),
                  if (showCorrection && q.explanation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '💡 ${q.explanation}',
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
        if (questions.isNotEmpty)
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
                          card.chapterTitle!,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Text(
                      _isCardFlipped ? card.back : card.front,
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

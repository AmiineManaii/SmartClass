part of '../pages/exam_authoring_page.dart';

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.labelKey,
    required this.value,
    required this.onTap,
  });

  final String labelKey;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: context.tr(labelKey)),
        child: Text(
          formatExamDateTime(context, value),
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _AiGenerateDialog extends ConsumerStatefulWidget {
  const _AiGenerateDialog({
    required this.initialTitle,
    required this.classGroupId,
  });

  final String initialTitle;
  final String classGroupId;

  @override
  ConsumerState<_AiGenerateDialog> createState() => _AiGenerateDialogState();
}

class _AiGenerateDialogState extends ConsumerState<_AiGenerateDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.initialTitle);
  final TextEditingController _focusTopicsController = TextEditingController();
  String _difficulty = 'moyen';
  int _count = 10;
  final Set<String> _courseIds = <String>{};
  final Set<String> _selectedChapters = <String>{};
  final Set<String> _knowledgeDocumentIds = <String>{};
  bool _includeDrafts = false;

  @override
  void dispose() {
    _title.dispose();
    _focusTopicsController.dispose();
    super.dispose();
  }

  List<String> _availableChapters(List<ExamCourseOption> courses) {
    final seen = <String>{};
    final result = <String>[];
    for (final course in courses) {
      if (!_courseIds.contains(course.id)) continue;
      for (final ch in course.chapters) {
        if (seen.add(ch)) result.add(ch);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final courses = ref.watch(examClassCoursesProvider(widget.classGroupId));
    final kbDocs = ref.watch(examKnowledgeDocumentsProvider);
    final hasAnySource =
        _courseIds.isNotEmpty || _knowledgeDocumentIds.isNotEmpty;

    return AlertDialog(
      title: Text(context.tr('exam_ai_action')),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('exam_ai_source_hint'),
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('exam_ai_courses_label'),
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              courses.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (_, _) => Text(
                  context.tr('exam_ai_courses_error'),
                  style: textTheme.bodySmall,
                ),
                data: (options) {
                  final chapterOptions = _availableChapters(options);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (options.isEmpty)
                        Text(
                          context.tr('exam_ai_courses_empty'),
                          style: textTheme.bodySmall,
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final course in options)
                              FilterChip(
                                label: Text(
                                  course.subject == null ||
                                          course.subject!.isEmpty
                                      ? course.title
                                      : '${course.title} — ${course.subject}',
                                  style: textTheme.bodySmall,
                                ),
                                selected: _courseIds.contains(course.id),
                                onSelected: (selected) => setState(() {
                                  if (selected) {
                                    _courseIds.add(course.id);
                                  } else {
                                    _courseIds.remove(course.id);
                                    final remaining = _availableChapters(
                                      options,
                                    ).toSet();
                                    _selectedChapters.retainAll(remaining);
                                  }
                                }),
                              ),
                          ],
                        ),
                      if (chapterOptions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          context.tr('exam_ai_chapters_label'),
                          style: textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final ch in chapterOptions)
                              FilterChip(
                                label: Text(ch, style: textTheme.bodySmall),
                                selected: _selectedChapters.contains(ch),
                                onSelected: (selected) => setState(() {
                                  if (selected) {
                                    _selectedChapters.add(ch);
                                  } else {
                                    _selectedChapters.remove(ch);
                                  }
                                }),
                              ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('exam_ai_kb_label'),
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              kbDocs.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: LinearProgressIndicator(),
                ),
                error: (_, _) => Text(
                  context.tr('exam_ai_kb_error'),
                  style: textTheme.bodySmall,
                ),
                data: (docs) {
                  final visibleDocs = docs
                      .where((doc) => _includeDrafts || !doc.isDraft)
                      .toList();
                  if (visibleDocs.isEmpty) {
                    return Text(
                      context.tr('exam_ai_kb_empty'),
                      style: textTheme.bodySmall,
                    );
                  }
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final doc in visibleDocs)
                            CheckboxListTile(
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _knowledgeDocumentIds.contains(doc.id),
                              onChanged: (checked) => setState(() {
                                if (checked == true) {
                                  _knowledgeDocumentIds.add(doc.id);
                                } else {
                                  _knowledgeDocumentIds.remove(doc.id);
                                }
                              }),
                              title: Text(
                                doc.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${doc.sourceType} • ${doc.chunkCount} blocs • ${context.tr(doc.isDraft ? 'exam_ai_trust_draft' : 'exam_ai_trust_verified')}',
                                style: textTheme.labelSmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _includeDrafts,
                onChanged: (value) => setState(() {
                  _includeDrafts = value ?? false;
                  if (!_includeDrafts) {
                    final allDocs =
                        kbDocs.valueOrNull ??
                        const <ExamKnowledgeDocumentOption>[];
                    final draftIds = allDocs
                        .where((d) => d.isDraft)
                        .map((d) => d.id)
                        .toSet();
                    _knowledgeDocumentIds.removeAll(draftIds);
                  }
                }),
                title: Text(
                  context.tr('exam_ai_kb_include_drafts'),
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  context.tr('exam_ai_kb_include_drafts_hint'),
                  style: textTheme.labelSmall,
                ),
              ),
              if (courses.hasValue && !hasAnySource)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    context.tr('exam_ai_sources_required'),
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _focusTopicsController,
                decoration: InputDecoration(
                  labelText: context.tr('exam_ai_focus_topics_label'),
                  hintText: context.tr('exam_ai_focus_topics_hint'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: context.tr('exam_title_optional'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _difficulty,
                decoration: InputDecoration(
                  labelText: context.tr('exam_ai_difficulty'),
                ),
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'facile',
                    child: Text(context.tr('exam_difficulty_easy')),
                  ),
                  DropdownMenuItem<String>(
                    value: 'moyen',
                    child: Text(context.tr('exam_difficulty_medium')),
                  ),
                  DropdownMenuItem<String>(
                    value: 'difficile',
                    child: Text(context.tr('exam_difficulty_hard')),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _difficulty = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _count,
                decoration: InputDecoration(
                  labelText: context.tr('exam_ai_question_count'),
                ),
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(value: 5, child: Text('5')),
                  DropdownMenuItem<int>(value: 10, child: Text('10')),
                  DropdownMenuItem<int>(value: 15, child: Text('15')),
                  DropdownMenuItem<int>(value: 20, child: Text('20')),
                  DropdownMenuItem<int>(value: 30, child: Text('30')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _count = value);
                },
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('exam_ai_slow_hint'),
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: !hasAnySource
              ? null
              : () {
                  final topics = _focusTopicsController.text
                      .split(RegExp(r'[,;\n]+'))
                      .map((entry) => entry.trim())
                      .where((entry) => entry.isNotEmpty)
                      .toList();
                  Navigator.of(context).pop(
                    _AiRequest(
                      title: _title.text.trim(),
                      difficulty: _difficulty,
                      questionCount: _count,
                      courseIds: _courseIds.toList(),
                      chapters: _selectedChapters.toList(),
                      focusTopics: topics,
                      knowledgeDocumentIds: _knowledgeDocumentIds.toList(),
                      includeDrafts: _includeDrafts,
                    ),
                  );
                },
          child: Text(context.tr('generate_exam')),
        ),
      ],
    );
  }
}

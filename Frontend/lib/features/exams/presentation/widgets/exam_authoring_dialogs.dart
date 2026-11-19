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
  String _difficulty = 'moyen';
  int _count = 10;
  final Set<String> _courseIds = <String>{};

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final courses = ref.watch(examClassCoursesProvider(widget.classGroupId));
    return AlertDialog(
      title: Text(context.tr('exam_ai_action')),
      content: SingleChildScrollView(
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
              data: (options) => options.isEmpty
                  ? Text(
                      context.tr('exam_ai_courses_empty'),
                      style: textTheme.bodySmall,
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final course in options)
                          FilterChip(
                            label: Text(
                              course.subject == null || course.subject!.isEmpty
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
                              }
                            }),
                          ),
                      ],
                    ),
            ),
            if (courses.hasValue && _courseIds.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  context.tr('exam_ai_courses_required'),
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: _courseIds.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  _AiRequest(
                    title: _title.text.trim(),
                    difficulty: _difficulty,
                    questionCount: _count,
                    courseIds: _courseIds.toList(),
                  ),
                ),
          child: Text(context.tr('generate_exam')),
        ),
      ],
    );
  }
}

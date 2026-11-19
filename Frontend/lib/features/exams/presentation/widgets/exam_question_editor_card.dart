import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/exam_definition.dart';

/// Editable single-choice question. Used for manual authoring and to review
/// imported/AI previews before saving.
class ExamQuestionEditorCard extends StatefulWidget {
  const ExamQuestionEditorCard({
    required this.index,
    required this.draft,
    required this.onChanged,
    this.onRemove,
    this.showCorrection = true,
    super.key,
  });

  final int index;
  final QuestionDraft draft;
  final ValueChanged<QuestionDraft> onChanged;
  final VoidCallback? onRemove;
  final bool showCorrection;

  @override
  State<ExamQuestionEditorCard> createState() => _ExamQuestionEditorCardState();
}

class _ExamQuestionEditorCardState extends State<ExamQuestionEditorCard> {
  late final TextEditingController _prompt;
  late final TextEditingController _points;
  late final Map<String, TextEditingController> _options;

  @override
  void initState() {
    super.initState();
    _prompt = TextEditingController(text: widget.draft.prompt);
    _points = TextEditingController(text: '${widget.draft.points}');
    _options = {
      for (final option in widget.draft.options)
        option.id: TextEditingController(text: option.text),
    };
  }

  @override
  void dispose() {
    _prompt.dispose();
    _points.dispose();
    for (final controller in _options.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _emit(QuestionDraft next) => widget.onChanged(next);

  void _updateOptions(List<ExamOption> options) {
    _emit(widget.draft.copyWith(options: options));
  }

  void _addOption() {
    final used = widget.draft.options.map((option) => option.id).toSet();
    String id = 'A';
    for (var code = 65; code <= 90; code += 1) {
      final candidate = String.fromCharCode(code);
      if (!used.contains(candidate)) {
        id = candidate;
        break;
      }
    }
    final controller = TextEditingController();
    setState(() => _options[id] = controller);
    _updateOptions([
      ...widget.draft.options,
      ExamOption(id: id, text: ''),
    ]);
  }

  void _removeOption(String id) {
    if (widget.draft.options.length <= 2) return;
    final controller = _options.remove(id);
    controller?.dispose();
    final nextOptions = widget.draft.options
        .where((option) => option.id != id)
        .toList();
    final correct = widget.draft.correctOptionIds.contains(id)
        ? const <String>[]
        : widget.draft.correctOptionIds;
    setState(() {});
    _emit(widget.draft.copyWith(options: nextOptions, correctOptionIds: correct));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  '${widget.index + 1}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('exam_question_label'),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              SizedBox(
                width: 84,
                child: TextFormField(
                  controller: _points,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.tr('exam_points_label'),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final points = int.tryParse(value.trim());
                    if (points != null && points > 0 && points <= 100) {
                      _emit(widget.draft.copyWith(points: points));
                    }
                  },
                ),
              ),
              if (widget.onRemove != null)
                IconButton(
                  tooltip: context.tr('exam_remove_question'),
                  onPressed: widget.onRemove,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _prompt,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: context.tr('exam_prompt_label'),
              hintText: context.tr('exam_prompt_hint'),
              alignLabelWithHint: true,
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty)
                    ? context.tr('required_field')
                    : null,
            onChanged: (value) => _emit(widget.draft.copyWith(prompt: value)),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(
              widget.showCorrection
                  ? 'exam_options_with_correction'
                  : 'exam_options_label',
            ),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: widget.draft.correctOptionIds.length == 1
                ? widget.draft.correctOptionIds.first
                : null,
            onChanged: (value) {
              if (value == null) return;
              _emit(
                widget.draft.copyWith(correctOptionIds: <String>[value]),
              );
            },
            child: Column(
              children: [
                for (final option in widget.draft.options) ...[
                  Row(
                    children: [
                      if (widget.showCorrection)
                        Radio<String>(value: option.id)
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            option.id,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      Expanded(
                        child: TextFormField(
                          controller: _options[option.id],
                          decoration: InputDecoration(
                            labelText: option.id,
                            isDense: true,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? context.tr('required_field')
                                  : null,
                          onChanged: (value) {
                            _updateOptions([
                              for (final current in widget.draft.options)
                                if (current.id == option.id)
                                  ExamOption(id: current.id, text: value)
                                else
                                  current,
                            ]);
                          },
                        ),
                      ),
                      if (widget.draft.options.length > 2)
                        IconButton(
                          tooltip: context.tr('exam_remove_option'),
                          onPressed: () => _removeOption(option.id),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
          if (widget.draft.options.length < 8)
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(context.tr('exam_add_option')),
            ),
          if (widget.showCorrection &&
              widget.draft.correctOptionIds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.tr('exam_correct_required'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

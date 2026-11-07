part of '../pages/ai_course_creator_page.dart';
class _EditorCard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onValidate;
  final VoidCallback onCancel;

  const _EditorCard({
    required this.controller,
    required this.onValidate,
    required this.onCancel,
  });

  @override
  State<_EditorCard> createState() => _EditorCardState();
}

class _EditorCardState extends State<_EditorCard> {
  /// Edit raw Markdown or preview the rendered document (like the final PDF).
  bool _preview = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_preview && mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.edit_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('ai_edit_title'),
                  style: theme.textTheme.labelLarge,
                ),
              ),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text(context.tr('ai_preview')),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text(context.tr('ai_edit')),
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                  ),
                ],
                selected: {_preview},
                onSelectionChanged: (s) => setState(() => _preview = s.first),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 480),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: _preview
                  ? MarkdownCourseView(data: widget.controller.text)
                  : TextField(
                      controller: widget.controller,
                      maxLines: null,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(4),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onValidate,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(context.tr('ai_validate_course')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: Text(context.tr('cancel')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


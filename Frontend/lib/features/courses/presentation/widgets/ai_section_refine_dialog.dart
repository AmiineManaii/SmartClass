import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../application/providers/ai_course_options_provider.dart';
import 'markdown_course_view.dart';

class AiSectionRefineDialog extends ConsumerStatefulWidget {
  final String fullCourseContent;
  final String? initialSelectedText;
  final String? level;
  final String? difficulty;
  final Future<void> Function(String oldText, String newText) onApply;

  const AiSectionRefineDialog({
    super.key,
    required this.fullCourseContent,
    this.initialSelectedText,
    this.level,
    this.difficulty,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required String fullCourseContent,
    String? initialSelectedText,
    String? level,
    String? difficulty,
    required Future<void> Function(String oldText, String newText) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiSectionRefineDialog(
        fullCourseContent: fullCourseContent,
        initialSelectedText: initialSelectedText,
        level: level,
        difficulty: difficulty,
        onApply: onApply,
      ),
    );
  }

  @override
  ConsumerState<AiSectionRefineDialog> createState() =>
      _AiSectionRefineDialogState();
}

class _AiSectionRefineDialogState extends ConsumerState<AiSectionRefineDialog> {
  late final TextEditingController _selectedTextCtrl;
  final _instructionCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _revisedText;
  String? _explanation;
  String? _model;
  List<String> _detectedHeadings = [];

  @override
  void initState() {
    super.initState();
    _selectedTextCtrl =
        TextEditingController(text: widget.initialSelectedText ?? '');
    _extractHeadings();

    // If initial text is empty but headings exist, default to the first heading/section
    if (_selectedTextCtrl.text.trim().isEmpty && _detectedHeadings.isNotEmpty) {
      _selectHeading(_detectedHeadings.first);
    }
  }

  @override
  void dispose() {
    _selectedTextCtrl.dispose();
    _instructionCtrl.dispose();
    super.dispose();
  }

  void _extractHeadings() {
    final lines = widget.fullCourseContent.split('\n');
    final headings = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ') ||
          trimmed.startsWith('## ') ||
          trimmed.startsWith('### ')) {
        headings.add(trimmed);
      }
    }
    _detectedHeadings = headings;
  }

  void _selectHeading(String heading) {
    // Find text from this heading until the next heading of same or higher level
    final lines = widget.fullCourseContent.split('\n');
    final startIndex = lines.indexWhere((l) => l.trim() == heading);
    if (startIndex == -1) {
      _selectedTextCtrl.text = heading;
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln(lines[startIndex]);
    for (var i = startIndex + 1; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.startsWith('# ') ||
          trimmed.startsWith('## ') ||
          trimmed.startsWith('### ')) {
        break;
      }
      buffer.writeln(line);
    }
    _selectedTextCtrl.text = buffer.toString().trim();
  }

  Future<void> _refine() async {
    final selectedText = _selectedTextCtrl.text.trim();
    final instruction = _instructionCtrl.text.trim();

    if (selectedText.isEmpty) {
      setState(() => _error = 'Veuillez sélectionner ou coller le texte à modifier.');
      return;
    }
    if (instruction.isEmpty) {
      setState(() => _error = 'Veuillez indiquer ce que l\'IA doit modifier.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _revisedText = null;
    });

    try {
      final remote = ref.read(aiCourseRemoteDataSourceProvider);
      final result = await remote.refineSection(
        courseContent: widget.fullCourseContent,
        selectedText: selectedText,
        instruction: instruction,
        level: widget.level,
        difficulty: widget.difficulty,
      );

      if (!mounted) return;
      setState(() {
        _loading = false;
        _revisedText = result['revisedText']?.toString() ?? '';
        _explanation = result['explanation']?.toString();
        _model = result['model']?.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : e.toString();
      });
    }
  }

  Future<void> _applyChanges() async {
    final revised = _revisedText;
    final original = _selectedTextCtrl.text.trim();
    if (revised == null || revised.isEmpty) return;

    setState(() => _loading = true);
    try {
      await widget.onApply(original, revised);
      if (!mounted) return;
      Navigator.of(context).pop();
      context.showSuccessToast(context.tr('ai_refine_success'));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _setQuickInstruction(String text) {
    if (_instructionCtrl.text.isEmpty) {
      _instructionCtrl.text = text;
    } else {
      _instructionCtrl.text = '${_instructionCtrl.text}. $text';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.auto_fix_high,
                      color: colorScheme.onPrimaryContainer, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('ai_refine_title'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        context.tr('ai_refine_subtitle'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                mediaQuery.viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Chapter quick selector if headings exist
                  if (_detectedHeadings.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.bookmark_outline_rounded,
                            size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Choisir une section du cours :',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Sélectionner un chapitre ou titre'),
                          items: _detectedHeadings.map((h) {
                            return DropdownMenuItem<String>(
                              value: h,
                              child: Text(
                                h.replaceAll(RegExp(r'^#+\s*'), ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) _selectHeading(val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Selected Text Area
                  Text(
                    context.tr('ai_refine_selected_text'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: TextField(
                      controller: _selectedTextCtrl,
                      maxLines: 5,
                      style: theme.textTheme.bodySmall,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                        hintText:
                            'Collez ou modifiez l\'extrait exact que vous souhaitez réviser...',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick instruction chips
                  Text(
                    'Suggestions rapides :',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickChip(
                        label: context.tr('ai_refine_quick_more_details'),
                        onTap: () => _setQuickInstruction(
                            'Développe cette section avec plus de détails et explications pas à pas.'),
                      ),
                      _QuickChip(
                        label: context.tr('ai_refine_quick_example'),
                        onTap: () => _setQuickInstruction(
                            'Ajoute un exemple concret illustratif de la vie réelle ou un bout de code commenté.'),
                      ),
                      _QuickChip(
                        label: context.tr('ai_refine_quick_simplify'),
                        onTap: () => _setQuickInstruction(
                            'Simplifie le vocabulaire et rend les explications beaucoup plus pédagogiques et claires.'),
                      ),
                      _QuickChip(
                        label: context.tr('ai_refine_quick_diagram'),
                        onTap: () => _setQuickInstruction(
                            'Ajoute un diagramme ou schéma explicatif en syntaxe Mermaid.'),
                      ),
                      _QuickChip(
                        label: context.tr('ai_refine_quick_quiz'),
                        onTap: () => _setQuickInstruction(
                            'Ajoute 2 questions d\'auto-évaluation ou un quiz rapide avec solution pour vérifier la compréhension.'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Prompt input
                  Text(
                    context.tr('ai_refine_instruction_label'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: TextField(
                      controller: _instructionCtrl,
                      maxLines: 3,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(12),
                        border: InputBorder.none,
                        hintText: context.tr('ai_refine_instruction_hint'),
                        hintStyle: TextStyle(
                          color: colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: colorScheme.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Generate Button
                  FilledButton.icon(
                    onPressed: _loading ? null : _refine,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(
                      _loading
                          ? 'Optimisation par l\'IA...'
                          : context.tr('ai_refine_submit'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Diff / Revision Result
                  if (_revisedText != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.tertiary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.compare_arrows_rounded,
                                  color: colorScheme.tertiary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.tr('ai_refine_diff_title'),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_model != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _model!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (_explanation != null &&
                              _explanation!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiary
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 16, color: colorScheme.tertiary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _explanation!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Revised Text Preview
                          Text(
                            context.tr('ai_refine_diff_revised'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.tertiary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 280),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    colorScheme.tertiary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: MarkdownCourseView(data: _revisedText!),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Validate / Apply or Discard buttons
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _loading ? null : _applyChanges,
                                  icon: const Icon(Icons.check_circle_outline,
                                      size: 18),
                                  label: Text(context.tr('ai_refine_apply')),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colorScheme.tertiary,
                                    foregroundColor: colorScheme.onTertiary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () {
                                  setState(() => _revisedText = null);
                                },
                                child: Text(context.tr('ai_refine_discard')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      backgroundColor: colorScheme.surfaceContainerLowest,
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9999),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

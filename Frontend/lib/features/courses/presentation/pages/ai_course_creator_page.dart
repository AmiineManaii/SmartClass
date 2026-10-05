import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_picker_row.dart';
import '../../../home/presentation/widgets/teacher_icons.dart';
import '../../application/providers/ai_course_options_provider.dart';

enum _GenerationState { idle, generating, success }

class AiCourseCreatorPage extends ConsumerStatefulWidget {
  const AiCourseCreatorPage({super.key});

  @override
  ConsumerState<AiCourseCreatorPage> createState() => _AiCourseCreatorPageState();
}

class _AiCourseCreatorPageState extends ConsumerState<AiCourseCreatorPage> {
  final _promptController = TextEditingController();
  final Set<String> _selectedChips = {};
  String _subject = 'Informatique & Algorithmique';
  String _level = 'Licence 3 (Intermédiaire / Avancé)';
  bool _optQuiz = true;
  bool _optTone = true;
  _GenerationState _generation = _GenerationState.idle;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_generation != _GenerationState.idle) return;
    setState(() => _generation = _GenerationState.generating);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _generation = _GenerationState.success);
  }

  Future<void> _pickOption({
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: options.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final option = options[index];
              return ListTile(
                title: Text(option, style: theme.textTheme.bodyMedium),
                trailing: option == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(option),
              );
            },
          ),
        );
      },
    );
    if (selected != null) {
      onSelected(selected);
    }
  }

  void _toggleChip(String id, String label) {
    setState(() {
      if (_selectedChips.contains(id)) {
        _selectedChips.remove(id);
        final text = _promptController.text.replaceAll('$label, ', '').replaceAll(label, '').trim();
        _promptController.text = text;
      } else {
        _selectedChips.add(id);
        final current = _promptController.text;
        final prefix = current.isEmpty ? '' : (current.endsWith(' ') ? '' : ' ');
        _promptController.text = '$current$prefix$label, ';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subjects = ref.watch(aiCourseSubjectsProvider);
    final levels = ref.watch(aiCourseLevelsProvider);
    final chips = ref.watch(aiCourseSuggestionChipsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SMARTCLASS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.secondary,
                letterSpacing: 0.08,
              ),
            ),
            Text(context.tr('course_editor'), style: theme.textTheme.headlineSmall),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/teacher_avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) => Container(
                    color: colorScheme.primary,
                    child: Icon(Icons.person, color: colorScheme.onPrimary, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.screenWidth >= 600 ? 32 : 20,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryFixed,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: colorScheme.onSecondaryFixed),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.tr('ai_engine_banner').toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryFixed,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.06,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(context.tr('ai_create_title'), style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('ai_create_desc'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [colorScheme.primaryContainer, colorScheme.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            Icons.auto_stories_outlined,
                            color: colorScheme.onPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('smart_designer'),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.tr('smart_designer_desc'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.04),
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              size: 28,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('drop_pdf_title'),
                            style: theme.textTheme.labelLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('drop_pdf_formats'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: theme.textTheme.labelMedium,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.folder_open_outlined, size: 18),
                                const SizedBox(width: 6),
                                Text(context.tr('browse_files')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: colorScheme.surfaceContainerHighest)),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          context.tr('or_divider'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      Expanded(child: Container(height: 1, color: colorScheme.surfaceContainerHighest)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.tr('topic_label'), style: theme.textTheme.labelLarge),
                      Text(
                        context.tr('recommended'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.04),
                          offset: const Offset(0, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _promptController,
                      maxLines: 4,
                      minLines: 4,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: context.tr('topic_hint'),
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('module_suggestions').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.06,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips.map((chip) {
                      final selected = _selectedChips.contains(chip.id);
                      return _SuggestionChip(
                        icon: teacherIconFromName(chip.icon),
                        label: context.tr(chip.labelKey),
                        selected: selected,
                        onTap: () => _toggleChip(chip.id, context.tr(chip.labelKey)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(context.tr('subject_label'), style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  AppPickerRow(
                    icon: Icons.laptop_mac_outlined,
                    value: _subject,
                    onTap: () => _pickOption(
                      options: subjects,
                      current: _subject,
                      onSelected: (v) => setState(() => _subject = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(context.tr('academic_level_label'), style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  AppPickerRow(
                    icon: Icons.school_outlined,
                    value: _level,
                    onTap: () => _pickOption(
                      options: levels,
                      current: _level,
                      onSelected: (v) => setState(() => _level = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.04),
                          offset: const Offset(0, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune_outlined, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('ai_params'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _AiOptionRow(
                          title: context.tr('opt_quiz_title'),
                          description: context.tr('opt_quiz_desc'),
                          value: _optQuiz,
                          onChanged: (v) => setState(() => _optQuiz = v),
                        ),
                        const SizedBox(height: 12),
                        _AiOptionRow(
                          title: context.tr('opt_tone_title'),
                          description: context.tr('opt_tone_desc'),
                          value: _optTone,
                          onChanged: (v) => setState(() => _optTone = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GenerateButton(state: _generation, onPressed: _generate),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined, size: 15, color: colorScheme.secondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          context.tr('estimate_rgpd'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
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

class _SuggestionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SuggestionChip({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected ? colorScheme.primary : colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? colorScheme.onPrimary : colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiOptionRow extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AiOptionRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final _GenerationState state;
  final VoidCallback? onPressed;

  const _GenerateButton({required this.state, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (Color bg, Color fg, Widget content) = switch (state) {
      _GenerationState.generating => (
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(context.tr('generating_course'))),
            ],
          ),
        ),
      _GenerationState.success => (
          colorScheme.tertiaryFixed,
          colorScheme.onTertiaryFixed,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 22),
              const SizedBox(width: 8),
              Flexible(child: Text(context.tr('course_generated'))),
            ],
          ),
        ),
      _GenerationState.idle => (
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 22),
              const SizedBox(width: 8),
              Flexible(child: Text(context.tr('generate_course_full'))),
            ],
          ),
        ),
    };

    return FilledButton(
      onPressed: state == _GenerationState.idle ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg,
        disabledForegroundColor: fg,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: theme.textTheme.labelLarge,
      ),
      child: content,
    );
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_picker_row.dart';
import '../../application/providers/ai_course_options_provider.dart';
import '../../application/providers/course_generation_job_provider.dart';
import '../widgets/markdown_course_view.dart';

const _genLevels = ['concis', 'equilibre', 'detaille'];

String _levelLabel(String level) {
  switch (level) {
    case 'concis':
      return 'Cours court';
    case 'detaille':
      return 'Cours complet';
    default:
      return 'Cours normal';
  }
}

String _difficultyLabel(String difficulty) {
  switch (difficulty) {
    case 'facile':
      return 'Facile';
    case 'difficile':
      return 'Difficile';
    default:
      return 'Moyenne';
  }
}

class AiCourseCreatorPage extends ConsumerStatefulWidget {
  const AiCourseCreatorPage({super.key});

  @override
  ConsumerState<AiCourseCreatorPage> createState() => _AiCourseCreatorPageState();
}

class _AiCourseCreatorPageState extends ConsumerState<AiCourseCreatorPage> {
  final _topicController = TextEditingController();
  final _urlController = TextEditingController();
  String _mode = 'topic';
  String _level = 'equilibre';
  String _difficulty = 'moyen';
  // Output always `resume` (structured course): the format picker was
  // removed from the UI, the level (court/normal/complet) drives the shape.
  static const _format = 'resume';
  bool _exExamples = true;
  bool _exMermaid = true;
  bool _exWebImages = false;
  // Teacher-chosen AI tooling (sent as extras, default OFF for speed):
  // web search delays the first visible token (~20 s+ of server-side
  // tool calls), thinking adds a long silent reasoning phase.
  bool _exWebSearch = false;
  bool _exThinking = false;
  String? _pdfName;
  List<int>? _pdfBytes;

  // Local edition of the finished generation (previewed, then optionally
  // re-saved as a new draft via the background job).
  bool _editing = false;
  bool _validated = false;
  final _editController = TextEditingController();

  /// Validated (edited) text, shown instead of the job content once set.
  /// Cleared on every new run so a fresh generation never shows stale text.
  String? _editedContent;

  static const _maxPdfBytes = 25 * 1024 * 1024;

  @override
  void dispose() {
    // NOTE: no job cancellation here on purpose — leaving the page never
    // stops a running generation (it auto-saves to drafts when ready).
    _topicController.dispose();
    _urlController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _showFailure(Object error) {
    final Failure failure =
        error is ApiException ? apiExceptionToFailure(error) : error as Failure;
    final l10n = failureL10n(failure);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(l10n.key, args: l10n.args)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickPdf() async {
    List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('something_went_wrong')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (files.isEmpty || !mounted) return;
    final file = files.first;
    try {
      final size = await file.length();
      if (size != null && size > _maxPdfBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ai_pdf_too_big')),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pdfName = file.name;
        _pdfBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('something_went_wrong')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Starts a background generation: the page may be left immediately —
  /// the job keeps streaming, then auto-saves the DRAFT (see
  /// `CourseGenerationJob`). Progress and result are observed below.
  Future<void> _generate() async {
    final job = ref.read(courseGenerationJobProvider);
    if (job.status == GenerationJobStatus.running) return;
    final topic = _topicController.text.trim();
    final url = _urlController.text.trim();
    if (_mode == 'topic' && topic.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('ai_topic_too_short')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_mode == 'pdf' && (_pdfBytes == null || _pdfName == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('ai_pdf_missing')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_mode == 'url' && url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('required_field')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final subject = switch (_mode) {
      'pdf' => _pdfName ?? '',
      'url' => url,
      _ => topic,
    };
    setState(() {
      _editing = false;
      _validated = false;
      _editedContent = null;
    });
    await ref.read(courseGenerationJobProvider.notifier).start(
          GenerationJobParams(
            mode: _mode,
            subject: subject,
            pdfBytes: _pdfBytes,
            pdfName: _pdfName,
            url: url.isEmpty ? null : url,
            level: _level,
            difficulty: _difficulty,
            format: _format,
            examples: _exExamples,
            mermaid: _exMermaid,
            webImages: _exWebImages,
            webSearch: _exWebSearch,
            thinking: _exThinking,
          ),
        );
  }

  void _resetResult() {
    ref.read(courseGenerationJobProvider.notifier).reset();
    setState(() {
      _editing = false;
      _validated = false;
      _editedContent = null;
    });
  }

  /// Displayed result text: the validated edition if any, else the job's.
  String? _displayedContent(GenerationJobState job) {
    if (job.status != GenerationJobStatus.done || job.content.isEmpty) {
      return null;
    }
    return _editedContent ?? job.content;
  }

  void _startEdit(String content) {
    _editController.text = content;
    setState(() => _editing = true);
  }

  void _validateEdit() {
    final edited = _editController.text;
    setState(() {
      _editing = false;
      _validated = true;
      _editedContent = edited;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('ai_validated')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickOption({
    required String titleKey,
    required List<String> options,
    required List<String> labels,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  context.tr(titleKey),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(labels[index],
                          style: theme.textTheme.bodyMedium),
                      trailing: options[index] == current
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () =>
                          Navigator.of(context).pop(options[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusAsync = ref.watch(aiModelStatusProvider);
    final job = ref.watch(courseGenerationJobProvider);
    final running = job.status == GenerationJobStatus.running;
    final displayed = _displayedContent(job);

    // Stream failure or manual-save failure surfaces here (the job has no
    // BuildContext of its own). Cancellation goes silently back to idle.
    ref.listen<GenerationJobStatus>(
      courseGenerationJobProvider.select((s) => s.status),
      (_, next) {
        if (next == GenerationJobStatus.error) {
          final error = ref.read(courseGenerationJobProvider).error;
          if (error != null) _showFailure(error);
        }
      },
    );
    ref.listen<Object?>(
      courseGenerationJobProvider.select((s) => s.saveError),
      (_, error) {
        if (error != null) _showFailure(error);
      },
    );
    // A draft id appearing means the course just landed in "Mes cours"
    // (auto-save on completion, or manual save) — offer a shortcut there.
    // No-op when returning to an already-saved result (same id).
    ref.listen<String?>(
      courseGenerationJobProvider.select((s) => s.courseId),
      (previous, next) {
        if (next != null && next != previous) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('course_ready')),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: context.tr('view_drafts'),
                onPressed: () => context.push('/courses'),
              ),
            ),
          );
        }
      },
    );

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
                  const SizedBox(height: 8),
                  statusAsync.when(
                    data: (status) => _ModelStatusRow(status: status),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
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
                  Text(context.tr('ai_mode_label'), style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final mode in const ['topic', 'pdf', 'url'])
                        _ModeChip(
                          label: context.tr('ai_mode_$mode'),
                          selected: _mode == mode,
                          onTap: () => setState(() => _mode = mode),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_mode == 'pdf') ...[
                    InkWell(
                      onTap: _pickPdf,
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
                            context.tr('ai_pdf_note'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ],
                  const SizedBox(height: 16),
                  if (_mode == 'topic') ...[
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
                        controller: _topicController,
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
                  ],
                  if (_mode == 'pdf' && _pdfName != null) ...[
                    const SizedBox(height: 8),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryFixed
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf_outlined,
                                size: 18,
                                color: colorScheme.onSecondaryFixed),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _pdfName!,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSecondaryFixed,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              tooltip: context.tr('cancel'),
                              onPressed: () => setState(() {
                                _pdfName = null;
                                _pdfBytes = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  if (_mode == 'url') ...[
                    Text(context.tr('ai_url_label'), style: theme.textTheme.labelLarge),
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
                        controller: _urlController,
                        keyboardType: TextInputType.url,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: context.tr('ai_url_hint'),
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
                  ],
                  const SizedBox(height: 16),
                  Text(context.tr('academic_level_label'), style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  AppPickerRow(
                    icon: Icons.school_outlined,
                    value: _levelLabel(_level),
                    onTap: () => _pickOption(
                      titleKey: 'academic_level_label',
                      options: _genLevels,
                      labels: _genLevels.map(_levelLabel).toList(),
                      current: _level,
                      onSelected: (v) => setState(() => _level = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('ai_level_hint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(context.tr('ai_difficulty_label'), style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  AppPickerRow(
                    icon: Icons.speed_outlined,
                    value: _difficultyLabel(_difficulty),
                    onTap: () => _pickOption(
                      titleKey: 'ai_difficulty_label',
                      options: const ['facile', 'moyen', 'difficile'],
                      labels: const ['Facile', 'Moyenne', 'Difficile'],
                      current: _difficulty,
                      onSelected: (v) => setState(() => _difficulty = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(context.tr('ai_extras_label'), style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  _ExtrasBox(
                    examples: _exExamples,
                    mermaid: _exMermaid,
                    webImages: _exWebImages,
                    webSearch: _exWebSearch,
                    thinking: _exThinking,
                    onChanged: (examples, mermaid, webImages, webSearch,
                            thinking) =>
                        setState(() {
                      _exExamples = examples;
                      _exMermaid = mermaid;
                      _exWebImages = webImages;
                      _exWebSearch = webSearch;
                      _exThinking = thinking;
                    }),
                  ),
                  const SizedBox(height: 16),
                  _GenerateButton(
                    generating: running,
                    hasResult: displayed != null,
                    onPressed: _generate,
                  ),
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
                  if (displayed != null) ...[
                    const SizedBox(height: 16),
                    if (_editing)
                      _EditorCard(
                        controller: _editController,
                        onValidate: _validateEdit,
                        onCancel: () => setState(() => _editing = false),
                      )
                    else
                      _ResultCard(
                        result: {...job.meta, 'content': displayed},
                        validated: _validated,
                        saving: job.saving,
                        saved: job.courseId != null &&
                            displayed == job.savedContent,
                        showDraftsLink: job.courseId != null,
                        onReset: _resetResult,
                        onEdit: () => _startEdit(displayed),
                        onSave: () => ref
                            .read(courseGenerationJobProvider.notifier)
                            .saveCurrentEdits(displayed),
                        onViewDrafts: () => context.push('/courses'),
                      ),
                  ],
                  if (running) ...[
                    const SizedBox(height: 16),
                    _LiveProgressCard(
                      elapsedSec: job.elapsedSec,
                      liveChars: job.chars,
                      preview: job.preview,
                      phase: job.phase,
                      onCancel: () => ref
                          .read(courseGenerationJobProvider.notifier)
                          .cancel(),
                    ),
                  ],
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

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected ? colorScheme.primary : colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModelStatusRow extends StatelessWidget {
  final Map<String, dynamic> status;

  const _ModelStatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final available = status['available'] == true;
    final model = (status['model'] as String?) ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (available ? colorScheme.tertiary : colorScheme.error)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: available ? colorScheme.tertiary : colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              available
                  ? context.tr('ai_model_online', args: {'model': model})
                  : context.tr('ai_model_offline'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final bool validated;
  final bool saving;
  final bool saved;
  final bool showDraftsLink;
  final VoidCallback onReset;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onViewDrafts;

  const _ResultCard({
    required this.result,
    required this.validated,
    required this.saving,
    required this.saved,
    required this.showDraftsLink,
    required this.onReset,
    required this.onEdit,
    required this.onSave,
    required this.onViewDrafts,
  });

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: '${result['content'] ?? ''}'),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('ai_copied')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final usage = result['usage'] as Map<String, dynamic>?;
    final promptTokens = usage?['promptTokens'];
    final completionTokens = usage?['completionTokens'];
    final meta = [
      '${result['model'] ?? ''}',
      if (promptTokens != null && completionTokens != null)
        '$promptTokens+$completionTokens tk',
      if (result['truncatedSource'] == true) context.tr('ai_truncated_warn'),
      if (validated) context.tr('ai_validated'),
    ].where((s) => s.toString().isNotEmpty).join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 20, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('ai_result_title'),
                  style: theme.textTheme.labelLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.content_copy_rounded, size: 20),
                tooltip: context.tr('ai_copy'),
                onPressed: () => _copy(context),
              ),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              meta,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 480),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              // Markdown rendered as a clean document (titles, figures,
              // code, images) — no raw markup shown to the teacher.
              child: MarkdownCourseView(data: '${result['content'] ?? ''}'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(context.tr('ai_edit_course')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(context.tr('ai_new_generation')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Manual save (edited text, or retry after an auto-save failure).
          // The background job auto-saves on completion; this button only
          // shows when the displayed text has no saved snapshot.
          if (!saved)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(context.tr('save_course')),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          if (showDraftsLink) ...[
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: onViewDrafts,
                icon: const Icon(Icons.drafts_outlined, size: 18),
                label: Text(context.tr('view_drafts')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.4),
        ),
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
                onSelectionChanged: (s) =>
                    setState(() => _preview = s.first),
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

class _LiveProgressCard extends StatelessWidget {
  final int elapsedSec;
  final int liveChars;
  final String preview;

  /// Backend pipeline phase (`extracting` while the PDF is parsed, else
  /// the model is generating). Shown so 0-token waits read as progress.
  final String phase;
  final VoidCallback onCancel;

  const _LiveProgressCard({
    required this.elapsedSec,
    required this.liveChars,
    required this.preview,
    required this.phase,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = liveChars ~/ 4;
    final minutes = elapsedSec ~/ 60;
    final seconds = (elapsedSec % 60).toString().padLeft(2, '0');
    final tail = preview.length > 600
        ? '…${preview.substring(preview.length - 600)}'
        : preview;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  phase == 'extracting'
                      ? context.tr('phase_extracting')
                      : context.tr('ai_generating_live', args: {
                          'tokens': '$tokens',
                          'time': '$minutes:$seconds'
                        }),
                  style: theme.textTheme.labelLarge,
                ),
              ),
              TextButton(
                onPressed: onCancel,
                child: Text(context.tr('ai_cancel_generation')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 4),
          if (tail.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  tail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExtrasBox extends StatelessWidget {
  final bool examples;
  final bool mermaid;
  final bool webImages;
  final bool webSearch;
  final bool thinking;
  final void Function(
      bool examples, bool mermaid, bool webImages, bool webSearch, bool thinking) onChanged;

  const _ExtrasBox({
    required this.examples,
    required this.mermaid,
    required this.webImages,
    required this.webSearch,
    required this.thinking,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget row(String titleKey, String descKey, bool value, ValueChanged<bool> set) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(value: value, onChanged: (v) => set(v ?? false)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(titleKey), style: theme.textTheme.bodyMedium),
                Text(
                  context.tr(descKey),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
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
        children: [
          row('ai_extra_examples', 'ai_extra_examples_desc', examples,
              (v) => onChanged(v, mermaid, webImages, webSearch, thinking)),
          const SizedBox(height: 12),
          row('ai_extra_mermaid', 'ai_extra_mermaid_desc', mermaid,
              (v) => onChanged(examples, v, webImages, webSearch, thinking)),
          const SizedBox(height: 12),
          row('ai_extra_webimages', 'ai_extra_webimages_desc', webImages,
              (v) => onChanged(examples, mermaid, v, webSearch, thinking)),
          const SizedBox(height: 12),
          row('ai_extra_websearch', 'ai_extra_websearch_desc', webSearch,
              (v) => onChanged(examples, mermaid, webImages, v, thinking)),
          const SizedBox(height: 12),
          row('ai_extra_thinking', 'ai_extra_thinking_desc', thinking,
              (v) => onChanged(examples, mermaid, webImages, webSearch, v)),
        ],
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final bool generating;
  final bool hasResult;
  final VoidCallback? onPressed;

  const _GenerateButton({
    required this.generating,
    required this.hasResult,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (Color bg, Color fg, Widget content) = switch ((generating, hasResult)) {
      (true, _) => (
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
      (false, true) => (
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
      (false, false) => (
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
      onPressed: generating ? null : onPressed,
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

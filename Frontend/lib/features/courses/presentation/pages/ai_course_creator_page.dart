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
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/ai_course_options_provider.dart';
import '../../application/providers/course_generation_job_provider.dart';
import '../../application/providers/course_plan_job_provider.dart';
import '../../application/providers/courses_provider.dart';
import '../../domain/entities/course_outline.dart';
import '../widgets/ai_section_refine_dialog.dart';
import '../widgets/course_outline_editor_card.dart';
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
  ConsumerState<AiCourseCreatorPage> createState() =>
      _AiCourseCreatorPageState();
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
  // Plan: no thinking/search. Sections (builder): thinking + web search.
  // URL imports default to web search, PDF imports to thinking + search.
  bool get _thinkingForSource => _mode == 'pdf';
  bool get _webSearchForSource => _mode == 'url' || _mode == 'pdf';
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

  /// Proposed course outline before full text generation.
  CourseOutline? _outline;
  
  /// Whether the current outline has been saved as a draft.
  bool _outlineSaved = false;
  bool _savingPlan = false;
  final _scrollController = ScrollController();

  static const _maxPdfBytes = 25 * 1024 * 1024;

  @override
  void dispose() {
    _topicController.dispose();
    _urlController.dispose();
    _editController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showFailure(Object error) {
    if (error is ApiException) {
      // Afficher le message d'erreur spécifique du backend
      String message = error.message;
      if (error.code != null) {
        message = '[${error.code}] $message';
      }
      if (error.details.isNotEmpty) {
        message += '\nDétails: ${error.details.join(', ')}';
      }
      context.showErrorToast(message);
      return;
    }
    final Failure failure = error as Failure;
    final l10n = failureL10n(failure);
    context.showErrorToast(context.tr(l10n.key, args: l10n.args));
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
      context.showErrorToast(context.tr('something_went_wrong'));
      return;
    }
    if (files.isEmpty || !mounted) return;
    final file = files.first;
    try {
      final size = await file.length();
      if (size != null && size > _maxPdfBytes) {
        if (!mounted) return;
        context.showWarningToast(context.tr('ai_pdf_too_big'));
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pdfName = file.name;
        _pdfBytes = bytes;
        if (_topicController.text.trim().isEmpty) {
          final clean = file.name
              .replaceAll(RegExp(r'\.[^/.]+$'), '')
              .replaceAll(RegExp(r'[_]+'), ' ')
              .trim();
          if (clean.isNotEmpty) {
            _topicController.text = clean;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      context.showErrorToast(context.tr('something_went_wrong'));
    }
  }

  /// Starts a background generation: the page may be left immediately —
  /// the job keeps streaming, then auto-saves the DRAFT (see
  /// `CourseGenerationJob`). Progress and result are observed below.
  bool _validateInputs() {
    final topic = _topicController.text.trim();
    final url = _urlController.text.trim();
    if (_mode == 'topic' && topic.length < 3) {
      context.showWarningToast(context.tr('ai_topic_too_short'));
      return false;
    }
    if (_mode == 'pdf' && (_pdfBytes == null || _pdfName == null)) {
      context.showWarningToast(context.tr('ai_pdf_missing'));
      return false;
    }
    if (_mode == 'url' && url.isEmpty) {
      context.showWarningToast(context.tr('required_field'));
      return false;
    }
    return true;
  }

  /// Rapidly proposes a structured outline with background execution & timer.
  Future<void> _generateOutline() async {
    if (!_validateInputs()) return;
    final topic = _topicController.text.trim();
    final url = _urlController.text.trim();
    final cleanPdfSubject = _pdfName != null
        ? _pdfName!
            .replaceAll(RegExp(r'\.[^/.]+$'), '')
            .replaceAll(RegExp(r'[_]+'), ' ')
            .trim()
        : '';
    final subject = switch (_mode) {
      'pdf' => topic.isNotEmpty ? topic : (cleanPdfSubject.isNotEmpty ? cleanPdfSubject : (_pdfName ?? '')),
      'url' => url,
      _ => topic,
    };

    ref.read(coursePlanJobProvider.notifier).start(
      mode: _mode,
      level: _level,
      difficulty: _difficulty,
      format: _format,
      subject: subject,
      url: url.isNotEmpty ? url : null,
      pdfBytes: _mode == 'pdf' ? _pdfBytes : null,
      pdfName: _mode == 'pdf' ? _pdfName : null,
      examples: _exExamples,
      mermaid: _exMermaid,
    );
  }

  /// Starts full course background generation (with or without outline).
  Future<void> _generate({bool useOutline = true}) async {
    final job = ref.read(courseGenerationJobProvider);
    if (job.status == GenerationJobStatus.running) return;
    if (!_validateInputs()) return;

    final topic = _topicController.text.trim();
    final url = _urlController.text.trim();
    final cleanPdfSubject = _pdfName != null
        ? _pdfName!
            .replaceAll(RegExp(r'\.[^/.]+$'), '')
            .replaceAll(RegExp(r'[_]+'), ' ')
            .trim()
        : '';
    final subject = switch (_mode) {
      'pdf' => topic.isNotEmpty ? topic : (cleanPdfSubject.isNotEmpty ? cleanPdfSubject : (_pdfName ?? '')),
      'url' => url,
      _ => topic,
    };
    setState(() {
      _editing = false;
      _validated = false;
      _editedContent = null;
    });
    final future = ref
        .read(courseGenerationJobProvider.notifier)
        .start(
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
            webImages: false,
            webSearch: _webSearchForSource,
            thinking: _thinkingForSource,
            generateImages: false,
            outline: useOutline ? _outline : null,
          ),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
        );
      }
    });
    await future;
  }

  /// Persists the teacher-validated plan as a DRAFT and opens the
  /// section-by-section builder, which materializes its chapters.
  Future<void> _buildSectionBySection() async {
    final outline = _outline;
    if (outline == null || _savingPlan) return;
    if (outline.sections.isEmpty) {
      context.showWarningToast(context.tr('ai_outline_empty'));
      return;
    }

    final url = _urlController.text.trim();
    final cleanPdfSubject = _pdfName != null
        ? _pdfName!
            .replaceAll(RegExp(r'\.[^/.]+$'), '')
            .replaceAll(RegExp(r'[_]+'), ' ')
            .trim()
        : '';
    final topic = _topicController.text.trim();
    final subject = switch (_mode) {
      'pdf' => topic.isNotEmpty
          ? topic
          : (outline.title.isNotEmpty
              ? outline.title
              : (cleanPdfSubject.isNotEmpty ? cleanPdfSubject : (_pdfName ?? ''))),
      'url' => url.isEmpty ? outline.title : url,
      _ =>
        topic.isEmpty
            ? outline.title
            : topic,
    };
    setState(() => _savingPlan = true);
    try {
      final saved = await ref
          .read(generatedCoursesDataSourceProvider)
          .saveDraft(
            title: outline.title.isEmpty ? subject : outline.title,
            subject: subject.isEmpty ? null : subject,
            content:
                '# ${outline.title}\n\n> Plan validé : les chapitres sont rédigés un par un dans le constructeur de sections.',
            level: _level,
            difficulty: _difficulty,
            format: _format,
            outline: outline,
          );
      ref.invalidate(myGeneratedCoursesProvider);
      if (!mounted) return;
      ref.read(coursePlanJobProvider.notifier).markOutlineSaved(saved.id);
      setState(() {
        _savingPlan = false;
        _outlineSaved = true; // Outline is now saved with the draft
      });
      await context.push('/courses/${saved.id}/build');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingPlan = false);
      _showFailure(e);
    }
  }

  Future<void> _onApplyRefinedSection(String oldText, String newText) async {
    final job = ref.read(courseGenerationJobProvider);
    final current = _displayedContent(job) ?? '';
    String updated;
    if (current.contains(oldText)) {
      updated = current.replaceFirst(oldText, newText);
    } else {
      updated = current.replaceAll(oldText.trim(), newText);
    }
    setState(() {
      _editedContent = updated;
      _validated = true;
    });
    await ref
        .read(courseGenerationJobProvider.notifier)
        .applyRefinedContent(updated);
  }

  void _resetResult() {
    ref.read(courseGenerationJobProvider.notifier).reset();
    setState(() {
      _editing = false;
      _validated = false;
      _editedContent = null;
      _outline = null;
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
    context.showSuccessToast(context.tr('ai_validated'));
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                      title: Text(
                        labels[index],
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: options[index] == current
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => Navigator.of(context).pop(options[index]),
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

  void _applySuggestionChip(String chipText) {
    final current = _topicController.text.trim();
    String addition;
    switch (chipText) {
      case 'Plan détaillé':
        addition = 'avec un plan détaillé en 4 chapitres structurés';
        break;
      case 'Quiz interactif inclus':
        setState(() => _exExamples = true);
        addition =
            'incluant un quiz interactif d\'évaluation avec barème et corrigés';
        break;
      case 'Exercices pratiques':
        addition = 'avec des exercices pratiques d\'application et corrections';
        break;
      case 'Études de cas':
        addition =
            'illustré d\'études de cas réelles et contextualisations d\'ingénierie';
        break;
      case 'Schémas Mermaid':
        setState(() => _exMermaid = true);
        addition = 'enrichi de schémas conceptuels et diagrammes Mermaid';
        break;
      default:
        addition = chipText;
    }
    if (current.isEmpty) {
      _topicController.text = addition;
    } else if (!current.contains(addition)) {
      _topicController.text = '$current, $addition';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final job = ref.watch(courseGenerationJobProvider);
    final displayed = _displayedContent(job);
    final isDesktop = context.screenWidth >= 1024;
    final planJob = ref.watch(coursePlanJobProvider);

    // Synchronize outline from background job if page was re-entered
    if (_outline == null &&
        planJob.outline != null &&
        planJob.status == CoursePlanJobStatus.completed) {
      _outline = planJob.outline;
      _outlineSaved = planJob.outlineSaved;
      if (_topicController.text.trim().isEmpty && planJob.subject.isNotEmpty) {
        _topicController.text = planJob.subject;
      }
    }

    ref.listen<CoursePlanJobStatus>(
      coursePlanJobProvider.select((s) => s.status),
      (prev, next) {
        if (next == CoursePlanJobStatus.error) {
          final error = ref.read(coursePlanJobProvider).error;
          if (error != null) _showFailure(error);
        } else if (next == CoursePlanJobStatus.completed &&
            prev != CoursePlanJobStatus.completed) {
          final outline = ref.read(coursePlanJobProvider).outline;
          if (outline != null) {
            setState(() {
              _outline = outline;
              _outlineSaved = ref.read(coursePlanJobProvider).outlineSaved;
            });
            context.showSuccessToast(
              'Plan généré et enregistré dans vos brouillons !',
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                );
              }
            });
          }
        }
      },
    );

    // Stream failure or manual-save failure surfaces here (the job has no
    // BuildContext of its own). Cancellation goes silently back to idle.
    ref.listen<GenerationJobStatus>(
      courseGenerationJobProvider.select((s) => s.status),
      (prev, next) {
        if (next == GenerationJobStatus.error) {
          final error = ref.read(courseGenerationJobProvider).error;
          if (error != null) _showFailure(error);
        } else if (next == GenerationJobStatus.done &&
            prev != GenerationJobStatus.done) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
              );
            }
          });
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
    ref.listen<String?>(courseGenerationJobProvider.select((s) => s.courseId), (
      previous,
      next,
    ) {
      if (next != null && next != previous) {
        context.showSuccessToast(
          context.tr('course_ready'),
          actionLabel: context.tr('view_drafts'),
          onAction: () => context.go('/courses'),
        );
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/courses');
            }
          },
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
            Text(
              context.tr('course_editor'),
              style: theme.textTheme.headlineSmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: context.tr('my_courses'),
            onPressed: () => context.go('/courses'),
          ),
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
                    child: Icon(
                      Icons.person,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : (context.screenWidth >= 600 ? 24 : 16),
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1600 : 640),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (flex: 48): Config Studio Form
                        Expanded(
                          flex: 48,
                          child: _buildConfigForm(
                            context,
                            isDesktop: true,
                            job: job,
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Right Column (flex: 52): Live Canvas / Editor / Inspiration
                        Expanded(
                          flex: 52,
                          child: _buildStudioCanvas(
                            context,
                            isDesktop: true,
                            job: job,
                            displayed: displayed,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildConfigForm(context, isDesktop: false, job: job),
                        if (displayed != null ||
                            _outline != null ||
                            job.status == GenerationJobStatus.running ||
                            job.status == GenerationJobStatus.error) ...[
                          const SizedBox(height: 20),
                          _buildStudioCanvas(
                            context,
                            isDesktop: false,
                            job: job,
                            displayed: displayed,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigForm(
    BuildContext context, {
    required bool isDesktop,
    required GenerationJobState job,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusAsync = ref.watch(aiModelStatusProvider);
    final running = job.status == GenerationJobStatus.running;
    final planJob = ref.watch(coursePlanJobProvider);
    final isGeneratingOutline = planJob.status == CoursePlanJobStatus.running;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Engine Sparks Banner
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.secondaryFixed,
              borderRadius: BorderRadius.circular(9999),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.04),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: colorScheme.onSecondaryFixed,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Moteur Pédagogique IA v3.2'.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryFixed,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.06,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        statusAsync.when(
          data: (status) => _ModelStatusRow(status: status),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('ai_create_title'),
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('ai_create_desc'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Visual Inspiration Card / Educational Assistant Prompt
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Concepteur intelligent',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Structurez vos unités d\'enseignement conformément aux normes LMD et référentiels européens.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
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
                    'Formats acceptés : PDF, Word (.docx), PPTX ou Markdown (max 25 Mo)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _pickPdf,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('Parcourir les fichiers'),
                  ),
                ],
              ),
            ),
          ),
          if (_pdfName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.secondaryFixed.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 18,
                    color: colorScheme.onSecondaryFixed,
                  ),
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
            const SizedBox(height: 12),
            Text(
              context.tr('topic_label'),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: TextField(
                controller: _topicController,
                maxLines: 2,
                minLines: 1,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Titre ou consignes spécifiques (optionnel)',
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
        ],

        if (_mode == 'topic') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('topic_label'),
                style: theme.textTheme.labelLarge,
              ),
              Text(
                context.tr('recommended'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
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
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
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
          const SizedBox(height: 10),
          // Stitch Quick Suggestion Chips
          Text(
            'Suggestions de modules pédagogiques'.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.05,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SuggestionChip(
                icon: Icons.format_list_numbered_rounded,
                label: 'Plan détaillé',
                onTap: () => _applySuggestionChip('Plan détaillé'),
              ),
              _SuggestionChip(
                icon: Icons.quiz_outlined,
                label: 'Quiz interactif inclus',
                onTap: () => _applySuggestionChip('Quiz interactif inclus'),
              ),
              _SuggestionChip(
                icon: Icons.code_rounded,
                label: 'Exercices pratiques',
                onTap: () => _applySuggestionChip('Exercices pratiques'),
              ),
              _SuggestionChip(
                icon: Icons.cases_outlined,
                label: 'Études de cas',
                onTap: () => _applySuggestionChip('Études de cas'),
              ),
              _SuggestionChip(
                icon: Icons.account_tree_outlined,
                label: 'Schémas Mermaid',
                onTap: () => _applySuggestionChip('Schémas Mermaid'),
              ),
            ],
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
        Text(
          context.tr('academic_level_label'),
          style: theme.textTheme.labelLarge,
        ),
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
        Text(
          context.tr('ai_difficulty_label'),
          style: theme.textTheme.labelLarge,
        ),
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
          onChanged: (examples, mermaid) => setState(() {
            _exExamples = examples;
            _exMermaid = mermaid;
          }),
        ),

        const SizedBox(height: 20),

        if (_outline != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _outlineSaved
                  ? colorScheme.tertiaryContainer.withValues(alpha: 0.15)
                  : colorScheme.secondaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _outlineSaved
                    ? colorScheme.tertiary.withValues(alpha: 0.5)
                    : colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _outlineSaved ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  color: _outlineSaved ? colorScheme.tertiary : colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _outlineSaved
                            ? 'Plan proposé & sauvegardé'
                            : 'Plan proposé (non sauvegardé)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _outlineSaved
                              ? colorScheme.tertiary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Consultez et validez le plan ci-dessous avant la génération du cours.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  child: const Text('Voir le plan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: running ? null : () => _generate(useOutline: true),
            icon: const Icon(Icons.auto_awesome_rounded, size: 20),
            label: const Text(
              'Générer le cours complet depuis ce plan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _outline = null);
              ref.read(coursePlanJobProvider.notifier).reset();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Modifier les options ou recommencer'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ] else ...[
          // Primary Outline Validation Button (Recommended: 3s outline preview)
          FilledButton.icon(
            onPressed: running || isGeneratingOutline ? null : _generateOutline,
            icon: isGeneratingOutline
                ? const SmartLoader.small(customSize: 18, color: Colors.white)
                : const Icon(Icons.schema_rounded, size: 20),
            label: Text(
              isGeneratingOutline
                  ? '⏱️ Élaboration du plan (${planJob.elapsedSec}s)...'
                  : '💡 Proposer le plan en 3s (Recommandé)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (isGeneratingOutline) ...[
            const SizedBox(height: 6),
            Text(
              '💡 La génération tourne en tâche de fond. Vous pouvez naviguer ailleurs dans l\'application.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Direct generation button (without outline)
          OutlinedButton.icon(
            onPressed: running || isGeneratingOutline
                ? null
                : () => _generate(useOutline: false),
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: Text(context.tr('ai_outline_generate_direct')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],

        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 15, color: colorScheme.secondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Estimation : ~20 secondes • Modèle certifié RGPD Pédagogie Sup',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStudioCanvas(
    BuildContext context, {
    required bool isDesktop,
    required GenerationJobState job,
    required String? displayed,
  }) {
    final running = job.status == GenerationJobStatus.running;
    final hasError = job.status == GenerationJobStatus.error;

    // 1. Finished result state (takes precedence once full course is generated)
    if (displayed != null) {
      if (_editing) {
        return _EditorCard(
          controller: _editController,
          onValidate: _validateEdit,
          onCancel: () => setState(() => _editing = false),
        );
      }
      return _ResultCard(
        result: {...job.meta, 'content': displayed},
        validated: _validated,
        saving: job.saving,
        saved: job.courseId != null && displayed == job.savedContent,
        showDraftsLink: job.courseId != null,
        onReset: _resetResult,
        onEdit: () => _startEdit(displayed),
        onRefineWithAi: () {
          AiSectionRefineDialog.show(
            context: context,
            fullCourseContent: displayed,
            level: _level,
            difficulty: _difficulty,
            onApply: _onApplyRefinedSection,
          );
        },
        onSave: () => ref
            .read(courseGenerationJobProvider.notifier)
            .saveCurrentEdits(displayed),
        onViewDrafts: () => context.go('/courses'),
      );
    }

    // 2. Running progress state (generation in progress)
    if (running) {
      return _LiveProgressCard(
        elapsedSec: job.elapsedSec,
        liveChars: job.chars,
        preview: job.preview,
        phase: job.phase,
        onCancel: () => ref.read(courseGenerationJobProvider.notifier).cancel(),
      );
    }

    // 3. Error state - display error card with retry
    if (hasError) {
      return _GenerationErrorCard(
        error: job.error,
        onRetry: () => _generate(useOutline: _outline != null),
        onCancel: () => ref.read(courseGenerationJobProvider.notifier).reset(),
      );
    }

    // 4. Proposed Outline state (shown when outline is ready for review before full generation)
    if (_outline != null) {
      return CourseOutlineEditorCard(
        outline: _outline!,
        generating: running,
        onOutlineChanged: (o) {
          setState(() => _outline = o);
          ref.read(coursePlanJobProvider.notifier).updateOutline(o);
        },
        onGenerateFullCourse: () => _generate(useOutline: true),
        onBuildSections: _buildSectionBySection,
        building: _savingPlan,
        onRegenerateOutline: _generateOutline,
        onCancel: () {
          setState(() => _outline = null);
          ref.read(coursePlanJobProvider.notifier).reset();
        },
        outlineSaved: _outlineSaved,
      );
    }

    // 5. Idle state: no extra canvas on mobile or desktop if no models needed
    return const SizedBox.shrink();
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary
          : colorScheme.surfaceContainerLowest,
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
  final VoidCallback onRefineWithAi;
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
    required this.onRefineWithAi,
    required this.onSave,
    required this.onViewDrafts,
  });

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: '${result['content'] ?? ''}'));
    if (!context.mounted) return;
    context.showSuccessToast(context.tr('ai_copied'));
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

    final contentStr = '${result['content'] ?? ''}';
    final words = contentStr
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final readingMin = (words / 200).ceil().clamp(1, 180);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stitch Floating AI Assistant Bar matching Stitch screen bfcc2ec5274b4c5ab96fa9f7267ba62c
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                  colorScheme.secondary,
                ],
              ),
            ),
            padding: const EdgeInsets.all(1.5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Assistant Rédaction IA',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Actif',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Sélection contextuelle',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _AiActionChip(
                          icon: Icons.auto_fix_high,
                          label: 'Reformuler',
                          iconColor: colorScheme.primary,
                          onTap: onRefineWithAi,
                        ),
                        const SizedBox(width: 8),
                        _AiActionChip(
                          icon: Icons.add_circle_outline,
                          label: 'Ajouter des exemples',
                          iconColor: colorScheme.secondary,
                          onTap: onRefineWithAi,
                        ),
                        const SizedBox(width: 8),
                        _AiActionChip(
                          icon: Icons.psychology_outlined,
                          label: 'Simplifier',
                          iconColor: colorScheme.tertiary,
                          onTap: onRefineWithAi,
                        ),
                        const SizedBox(width: 8),
                        _AiActionChip(
                          icon: Icons.quiz_outlined,
                          label: 'Générer un QCM',
                          iconColor: colorScheme.primary,
                          filled: true,
                          onTap: onRefineWithAi,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20,
                color: colorScheme.tertiary,
              ),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '~$readingMin min de lecture',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$words mots',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
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
              child: MarkdownCourseView(data: contentStr),
            ),
          ),
          const SizedBox(height: 12),
          // AI In-line refinement button
          FilledButton.icon(
            onPressed: onRefineWithAi,
            icon: const Icon(Icons.auto_fix_high, size: 18),
            label: Text(context.tr('ai_refine_btn')),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.tertiary,
              foregroundColor: colorScheme.onTertiary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
          // Save status and actions.
          if (saved) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_done_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enregistré dans vos brouillons',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onViewDrafts,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(context.tr('view_drafts')),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? SmartLoader.small(
                        customSize: 18,
                        color: colorScheme.onPrimary,
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(context.tr('save_course')),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: onViewDrafts,
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: Text(context.tr('my_courses')),
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

class _LiveProgressCard extends StatelessWidget {
  final int elapsedSec;
  final int liveChars;
  final String preview;
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header avec statut animé
          Row(
            children: [
              _PulsingDot(color: colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase == 'extracting'
                          ? context.tr('phase_extracting')
                          : context.tr(
                              'ai_generating_live',
                              args: {
                                'tokens': '$tokens',
                                'time': '$minutes:$seconds',
                              },
                            ),
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      'IA en train de rédiger...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onCancel,
                child: Text(context.tr('ai_cancel_generation')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barre de progression animée
          LinearProgressIndicator(
            minHeight: 4,
            valueColor: AlwaysStoppedAnimation(colorScheme.secondary),
            backgroundColor: colorScheme.secondary.withValues(alpha: 0.2),
          ),
          // Preview live des tokens avec effet typewriter
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: _StreamingPreview(text: preview),
            ),
          ],
        ],
      ),
    );
  }
}

/// Point pulsant pour indiquer l'activité live
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Preview qui affiche le texte en streaming avec auto-scroll
class _StreamingPreview extends StatelessWidget {
  final String text;
  const _StreamingPreview({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          // Auto-scroll vers le bas pour voir les nouveaux tokens
          reverse: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SelectableText(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExtrasBox extends StatelessWidget {
  final bool examples;
  final bool mermaid;
  final void Function(bool examples, bool mermaid) onChanged;

  const _ExtrasBox({
    required this.examples,
    required this.mermaid,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget row(
      String titleKey,
      String descKey,
      bool value,
      ValueChanged<bool> set,
    ) {
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
          row(
            'ai_extra_examples',
            'ai_extra_examples_desc',
            examples,
            (v) => onChanged(v, mermaid),
          ),
          const SizedBox(height: 12),
          row(
            'ai_extra_mermaid',
            'ai_extra_mermaid_desc',
            mermaid,
            (v) => onChanged(examples, v),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, size: 18, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('ai_extras_auto'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colorScheme.secondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final bool filled;
  final VoidCallback onTap;

  const _AiActionChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: filled
          ? colorScheme.primaryFixed
          : colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: filled
                      ? colorScheme.onPrimaryFixed
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }}

/// Carte d'erreur affichée inline quand la génération échoue
class _GenerationErrorCard extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _GenerationErrorCard({
    required this.error,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String errorMessage = 'Erreur inconnue';
    String? errorCode;

    final apiError = error as ApiException?;
    if (apiError != null) {
      errorCode = apiError.code ?? '';
      errorMessage = apiError.message;
      if (apiError.details.isNotEmpty) {
        errorMessage += '\nDétails: ${apiError.details.join(', ')}';
      }
    } else if (error != null) {
      errorMessage = error.toString();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colorScheme.error,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Échec de la génération',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (errorCode != null)
                      Text(
                        'Code: $errorCode',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onErrorContainer.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              errorMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Annuler'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Réessayer'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

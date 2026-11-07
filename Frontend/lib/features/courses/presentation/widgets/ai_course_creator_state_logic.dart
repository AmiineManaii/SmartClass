part of '../pages/ai_course_creator_page.dart';

extension on _AiCourseCreatorPageState {
  void _showFailure(Object error) {
    if (error is ApiException) {
      // Afficher le message d'erreur sp├®cifique du backend
      String message = error.message;
      if (error.code != null) {
        message = '[${error.code}] $message';
      }
      if (error.details.isNotEmpty) {
        message += '\nD├®tails: ${error.details.join(', ')}';
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
      if (size != null && size > _AiCourseCreatorPageState._maxPdfBytes) {
        if (!mounted) return;
        context.showWarningToast(context.tr('ai_pdf_too_big'));
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      updateState(() {
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

  /// Starts a background generation: the page may be left immediately ÔÇö
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
      format: _AiCourseCreatorPageState._format,
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
    updateState(() {
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
            format: _AiCourseCreatorPageState._format,
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
    updateState(() => _savingPlan = true);
    try {
      final saved = await ref
          .read(generatedCoursesDataSourceProvider)
          .saveDraft(
            title: outline.title.isEmpty ? subject : outline.title,
            subject: subject.isEmpty ? null : subject,
            content:
                '# ${outline.title}\n\n> Plan valid├® : les chapitres sont r├®dig├®s un par un dans le constructeur de sections.',
            level: _level,
            difficulty: _difficulty,
            format: _AiCourseCreatorPageState._format,
            outline: outline,
          );
      ref.invalidate(myGeneratedCoursesProvider);
      if (!mounted) return;
      ref.read(coursePlanJobProvider.notifier).markOutlineSaved(saved.id);
      updateState(() {
        _savingPlan = false;
        _outlineSaved = true; // Outline is now saved with the draft
      });
      await context.push('/courses/${saved.id}/build');
    } catch (e) {
      if (!mounted) return;
      updateState(() => _savingPlan = false);
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
    updateState(() {
      _editedContent = updated;
      _validated = true;
    });
    await ref
        .read(courseGenerationJobProvider.notifier)
        .applyRefinedContent(updated);
  }

  void _resetResult() {
    ref.read(courseGenerationJobProvider.notifier).reset();
    updateState(() {
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
    updateState(() => _editing = true);
  }

  void _validateEdit() {
    final edited = _editController.text;
    updateState(() {
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

  void _applySuggestionChip(String chipType) {
    final current = _topicController.text.trim();
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    String addition;
    switch (chipType) {
      case 'plan':
        addition = isEn
            ? 'with a structured 4-chapter syllabus and progressive competencies'
            : 'avec un plan d├®taill├® en 4 chapitres structur├®s';
        break;
      case 'quiz':
        updateState(() => _exExamples = true);
        addition = isEn
            ? 'including an interactive evaluation quiz with answer key'
            : 'incluant un quiz interactif d\'├®valuation avec bar├¿me et corrig├®s';
        break;
      case 'exercises':
        addition = isEn
            ? 'with practical exercises and step-by-step corrections'
            : 'avec des exercices pratiques d\'application et corrections';
        break;
      case 'cases':
        addition = isEn
            ? 'illustrated with real-world case studies and contextual applications'
            : 'illustr├® d\'├®tudes de cas r├®elles et contextualisations d\'ing├®nierie';
        break;
      case 'mermaid':
        updateState(() => _exMermaid = true);
        addition = isEn
            ? 'enriched with conceptual Mermaid diagrams and flowcharts'
            : 'enrichi de sch├®mas conceptuels et diagrammes Mermaid';
        break;
      default:
        addition = chipType;
    }
    if (current.isEmpty) {
      _topicController.text = addition;
    } else if (!current.contains(addition)) {
      _topicController.text = '$current, $addition';
    }
    updateState(() {});
  }
}


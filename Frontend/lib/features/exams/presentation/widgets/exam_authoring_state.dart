part of '../pages/exam_authoring_page.dart';

class _ExamAuthoringPageState extends ConsumerState<ExamAuthoringPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _violationController = TextEditingController(text: '3');

  String? _classGroupId;
  String? _className;
  DateTime _startsAt = _defaultStart();
  DateTime _endsAt = _defaultStart().add(const Duration(hours: 2));
  ExamSource _source = ExamSource.manual;
  ExamStatus _status = ExamStatus.draft;
  List<QuestionDraft> _questions = <QuestionDraft>[];
  ExamSettings _settings = const ExamSettings();
  bool _loading = false;
  bool _saving = false;
  bool _importing = false;
  bool _generating = false;
  String? _loadedModel;
  String? _knowledgeSearchMode;
  String? _knowledgeDegradedReason;
  List<ExamKnowledgeSource> _knowledgeSources = const <ExamKnowledgeSource>[];
  ExamCoverageReport? _coverageReport;
  int _editorRevision = 0;
  String? _loadErrorKey;

  static DateTime _defaultStart() {
    final now = DateTime.now().add(const Duration(days: 1));
    return DateTime(now.year, now.month, now.day, 9);
  }

  bool get _isEditing => widget.examId != null;

  @override
  Widget build(BuildContext context) => buildAuthoring(context);

  void _applyState(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExisting();
    } else {
      _addQuestion();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _violationController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() {
      _loading = true;
      _loadErrorKey = null;
    });
    try {
      final detail = await ref
          .read(examRepositoryProvider)
          .getTeacherExam(widget.examId!);
      if (!mounted) return;
      setState(() {
        _titleController.text = detail.title;
        _descriptionController.text = detail.description ?? '';
        _classGroupId = detail.classGroupId;
        _className = detail.className;
        _durationController.text = '${detail.durationMinutes}';
        _startsAt = detail.startsAt;
        _endsAt = detail.endsAt;
        _source = detail.source;
        _status = detail.status;
        _settings = detail.settings;
        _violationController.text = '${detail.settings.maxViolationCount}';
        _questions = detail.questions
            .map(QuestionDraft.fromTeacherQuestion)
            .toList();
        if (_questions.isEmpty) _addQuestion();
        _editorRevision += 1;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadErrorKey = examErrorKey(error);
      });
    }
  }

  void _addQuestion() {
    _questions = <QuestionDraft>[
      ..._questions,
      const QuestionDraft(
        prompt: '',
        options: <ExamOption>[
          ExamOption(id: 'A', text: ''),
          ExamOption(id: 'B', text: ''),
        ],
        correctOptionIds: <String>[],
      ),
    ];
    _editorRevision += 1;
  }

  void _updateQuestion(int index, QuestionDraft draft) {
    final next = List<QuestionDraft>.of(_questions);
    next[index] = draft;
    _questions = next;
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) return;
    final next = List<QuestionDraft>.of(_questions)..removeAt(index);
    setState(() {
      _questions = next;
      _editorRevision += 1;
    });
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _startsAt : _endsAt;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (time == null) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _startsAt = value;
        if (!_endsAt.isAfter(value)) {
          _endsAt = value.add(const Duration(hours: 1));
        }
      } else {
        _endsAt = value;
      }
    });
  }

  Future<void> _showSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                context.tr('exam_settings_title'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('exam_setting_shuffle')),
                value: _settings.shuffleQuestions,
                onChanged: (value) => setSheetState(
                  () => _settings = _settings.copyWith(
                    shuffleQuestions: value,
                  ),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('exam_setting_camera')),
                subtitle: Text(context.tr('exam_setting_camera_hint')),
                value: _settings.requireCamera,
                onChanged: (value) => setSheetState(
                  () => _settings = _settings.copyWith(requireCamera: value),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('exam_setting_skip')),
                value: _settings.allowQuestionSkip,
                onChanged: (value) => setSheetState(
                  () => _settings = _settings.copyWith(
                    allowQuestionSkip: value,
                  ),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('exam_setting_results')),
                subtitle: Text(context.tr('exam_setting_results_hint')),
                value: _settings.showResultsAfterClose,
                onChanged: (value) => setSheetState(
                  () => _settings = _settings.copyWith(
                    showResultsAfterClose: value,
                  ),
                ),
              ),
              TextFormField(
                controller: _violationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('exam_setting_max_violations'),
                  helperText: context.tr('exam_setting_max_violations_hint'),
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value.trim());
                  if (parsed != null && parsed >= 1 && parsed <= 20) {
                    setSheetState(
                      () => _settings = _settings.copyWith(
                        maxViolationCount: parsed,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('done')),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _pickImport() async {
    if (_classGroupId == null) {
      context.showWarningToast(context.tr('exam_select_class_first'));
      return;
    }
    List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['json', 'csv', 'txt'],
      );
    } catch (_) {
      if (!mounted) return;
      context.showErrorToast(context.tr('exam_error_import_read'));
      return;
    }
    if (files.isEmpty || !mounted) return;
    final file = files.first;
    setState(() => _importing = true);
    try {
      final size = await file.length();
      if (size != null && size > 10 * 1024 * 1024) {
        if (!mounted) return;
        context.showWarningToast(context.tr('exam_import_too_large'));
        return;
      }
      final bytes = await file.readAsBytes();
      final preview = await ref
          .read(examRepositoryProvider)
          .previewImport(filename: file.name, bytes: bytes);
      if (!mounted) return;
      setState(() {
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = preview.title;
        }
        _descriptionController.text = preview.description ?? '';
        _questions = List<QuestionDraft>.of(preview.questions);
        _source = ExamSource.import;
        _knowledgeSearchMode = null;
        _knowledgeDegradedReason = null;
        _knowledgeSources = const <ExamKnowledgeSource>[];
        _coverageReport = null;
        _editorRevision += 1;
      });
      context.showSuccessToast(
        context.tr(
          'exam_import_preview_ready',
          args: {'count': '${preview.questions.length}'},
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      context.showErrorToast(context.tr(examErrorKey(error)));
    } catch (_) {
      if (!mounted) return;
      context.showErrorToast(context.tr('exam_error_import_read'));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _generateAi() async {
    if (_classGroupId == null) {
      context.showWarningToast(context.tr('exam_select_class_first'));
      return;
    }
    final request = await showDialog<_AiRequest>(
      context: context,
      builder: (context) => _AiGenerateDialog(
        initialTitle: _titleController.text.trim(),
        classGroupId: _classGroupId!,
      ),
    );
    if (request == null || !mounted) return;
    setState(() => _generating = true);
    try {
      final preview = await ref
          .read(examRepositoryProvider)
          .generateWithAi(
            classGroupId: _classGroupId!,
            courseIds: request.courseIds,
            chapters: request.chapters,
            focusTopics: request.focusTopics,
            knowledgeDocumentIds: request.knowledgeDocumentIds,
            includeDrafts: request.includeDrafts,
            title: request.title.isEmpty ? null : request.title,
            difficulty: request.difficulty,
            questionCount: request.questionCount,
          );
      if (!mounted) return;
      setState(() {
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = preview.title;
        }
        _descriptionController.text = preview.description ?? '';
        _questions = List<QuestionDraft>.of(preview.questions);
        _source = ExamSource.ai;
        _loadedModel = preview.model;
        _knowledgeSearchMode = preview.knowledgeSearchMode;
        _knowledgeDegradedReason = preview.knowledgeDegradedReason;
        _knowledgeSources = preview.knowledgeSources;
        _coverageReport = preview.coverage;
        _editorRevision += 1;
      });
      context.showSuccessToast(
        context.tr(
          'exam_ai_preview_ready',
          args: {'count': '${preview.questions.length}'},
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      context.showErrorToast(context.tr(examErrorKey(error)));
    } catch (_) {
      if (!mounted) return;
      context.showErrorToast(context.tr('exam_error_generic'));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  bool _validateInputs() {
    if (_classGroupId == null) {
      context.showWarningToast(context.tr('exam_select_class_required'));
      return false;
    }
    if (_titleController.text.trim().isEmpty) {
      context.showWarningToast(context.tr('exam_title_required'));
      return false;
    }
    final duration = int.tryParse(_durationController.text.trim());
    if (duration == null || duration < 1 || duration > 600) {
      context.showWarningToast(context.tr('exam_duration_invalid'));
      return false;
    }
    if (!_endsAt.isAfter(_startsAt)) {
      context.showWarningToast(context.tr('exam_window_invalid'));
      return false;
    }
    if (_questions.isEmpty) {
      context.showWarningToast(context.tr('exam_questions_required'));
      return false;
    }
    for (final question in _questions) {
      if (question.prompt.trim().isEmpty ||
          question.options.length < 2 ||
          question.options.any((option) => option.text.trim().isEmpty)) {
        context.showWarningToast(context.tr('exam_questions_incomplete'));
        return false;
      }
      if (question.correctOptionIds.length != 1) {
        context.showWarningToast(context.tr('exam_correct_required'));
        return false;
      }
      if (question.points < 1) {
        context.showWarningToast(context.tr('exam_points_invalid'));
        return false;
      }
    }
    return true;
  }

  Future<void> _save() async {
    if (_saving || !_validateInputs() || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final duration = int.parse(_durationController.text.trim());
    try {
      if (_isEditing) {
        final detail = await ref
            .read(examRepositoryProvider)
            .updateExam(
              widget.examId!,
              UpdateExamInput(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                durationMinutes: duration,
                startsAt: _startsAt,
                endsAt: _endsAt,
                settings: _settings,
                questions: _questions,
              ),
            );
        ref.invalidate(myExamsProvider);
        ref.invalidate(teacherExamProvider(detail.id));
        if (mounted) {
          context.showSuccessToast(context.tr('exam_saved_toast'));
          context.go('/exams/${detail.id}/manage');
        }
      } else {
        final detail = await ref
            .read(examRepositoryProvider)
            .createExam(
              CreateExamInput(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                classGroupId: _classGroupId!,
                durationMinutes: duration,
                startsAt: _startsAt,
                endsAt: _endsAt,
                source: _source,
                settings: _settings,
                questions: _questions,
              ),
            );
        ref.invalidate(myExamsProvider);
        if (mounted) {
          context.showSuccessToast(context.tr('exam_created_toast'));
          context.go('/exams/${detail.id}/manage');
        }
      }
    } on ApiException catch (error) {
      if (mounted) {
        context.showErrorToast(context.tr(examErrorKey(error)));
      }
    } catch (_) {
      if (mounted) context.showErrorToast(context.tr('exam_error_generic'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int get _totalPoints =>
      _questions.fold<int>(0, (sum, question) => sum + question.points);
}

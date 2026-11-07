part of '../pages/ai_course_creator_page.dart';

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

  void _onFormUpdated() {
    if (mounted) updateState(() {});
  }

  @override
  void initState() {
    super.initState();
    _topicController.addListener(_onFormUpdated);
    _urlController.addListener(_onFormUpdated);
  }

  @override
  void dispose() {
    _topicController.removeListener(_onFormUpdated);
    _urlController.removeListener(_onFormUpdated);
    _topicController.dispose();
    _urlController.dispose();
    _editController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void updateState(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) => _buildPage(context);
}

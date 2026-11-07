part of '../pages/course_section_builder_page.dart';

class _CourseSectionBuilderPageState extends ConsumerState<CourseSectionBuilderPage> {
  /// Section currently asking ComfyUI for an illustration (button spinner).
  String? _imageLoadingKey;

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};

  CourseSectionBuild get _build =>
      ref.read(courseSectionBuildProvider(widget.courseId).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always refresh: another tab (reader) may have changed statuses.
      _build.load();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void updateState(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) => _buildPage(context);
}

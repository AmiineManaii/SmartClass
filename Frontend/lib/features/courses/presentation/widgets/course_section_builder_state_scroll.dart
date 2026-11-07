part of '../pages/course_section_builder_page.dart';
extension on _CourseSectionBuilderPageState {
  void _scrollToSection(String sectionKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _sectionKeys[sectionKey];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.08,
        );
      }
    });
  }

  CourseSectionBuild get _build =>
      ref.read(courseSectionBuildProvider(widget.courseId).notifier);

  bool _imageActionBusy(String sectionKey) =>
      _imageLoadingKey != null ||
      (ref
              .read(courseSectionBuildProvider(widget.courseId))
              .imageJob(sectionKey)
              ?.isActive ??
          false);

  void _showSnack(String key, {Map<String, String>? args}) {
    context.showSuccessToast(context.tr(key, args: args));
  }

  Future<void> _confirmRegenerate(CourseSectionEntry section) async {
    final wasValidated = section.status == CourseSectionStatus.validated;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('ai_build_regenerate_title')),
        content: Text(
          wasValidated
              ? context.tr('ai_build_regenerate_confirm_validated')
              : context.tr('ai_build_regenerate_confirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.tr('ai_build_regenerate')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _build.generate(sectionKey: section.sectionKey, regenerate: true);
  }

  Future<void> _validate(CourseSectionEntry section) async {
    try {
      await _build.validate(section.sectionKey);
      if (!mounted) return;
      final state = ref.read(courseSectionBuildProvider(widget.courseId));
      final remaining = state.remainingToValidate;
      if (remaining == 0) {
        _showSnack('ai_build_all_validated_snack');
      } else {
        _showSnack('ai_build_validated_snack', args: {'count': '$remaining'});
      }
    } catch (e) {
      if (!mounted) return;
      _showBuildFailure(context, e);
    }
  }

  /// Caption under the generated illustration: the section's own wording
  /// (description, else key topics). Omitted when the section has neither.
}

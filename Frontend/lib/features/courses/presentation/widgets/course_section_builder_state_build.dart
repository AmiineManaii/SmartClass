part of '../pages/course_section_builder_page.dart';
extension on _CourseSectionBuilderPageState {
  Widget _buildPage(BuildContext context) {
    final provider = courseSectionBuildProvider(widget.courseId);
    final state = ref.watch(provider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen<CourseSectionBuildState>(provider, (previous, next) {
      final error = next.streamError;
      if (!mounted || error == null || error == previous?.streamError) return;
      _showBuildFailure(context, error);
      ref.read(provider.notifier).acknowledgeStreamError();
    });

    ref.listen<String?>(provider.select((s) => s.streamingKey), (previous, next) {
      if (next != null && next != previous) {
        _scrollToSection(next);
      }
    });

    final bool allValidated =
        state.sections.isNotEmpty && state.remainingToValidate == 0;

    return Scaffold(
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
        title: Text(
          state.course?.title ?? context.tr('ai_build_title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (state.sections.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: allValidated
                      ? colorScheme.secondaryContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.validatedCount}/${state.sections.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: allValidated
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

}

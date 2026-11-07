part of '../pages/course_section_builder_page.dart';
extension on _CourseSectionBuilderPageState {
  Widget _buildBody(BuildContext context, CourseSectionBuildState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state.loading && state.sections.isEmpty && state.error == null) {
      return const Center(
        child: SmartLoader.large(
          message: 'Chargement des sections du cours...',
        ),
      );
    }
    if (state.error != null && state.sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('ai_build_error'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => ref
                    .read(courseSectionBuildProvider(widget.courseId).notifier)
                    .load(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      );
    }
    if (state.sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.list_alt_rounded,
                size: 44,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('ai_build_no_sections'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(context.tr('back')),
              ),
            ],
          ),
        ),
      );
    }

    final notifier = ref.read(
      courseSectionBuildProvider(widget.courseId).notifier,
    );

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _buildProgressDashboard(context, state, notifier),
        const SizedBox(height: 16),
        for (var index = 0; index < state.sections.length; index++) ...[
          _SectionCard(
            key: _sectionKeys.putIfAbsent(
              state.sections[index].sectionKey,
              () => GlobalKey(),
            ),
            index: index,
            section: state.sections[index],
            state: state,
            imageLoading:
                _imageLoadingKey == state.sections[index].sectionKey ||
                (state.imageJob(state.sections[index].sectionKey)?.isActive ??
                    false),
            onGenerate: () => ref
                .read(courseSectionBuildProvider(widget.courseId).notifier)
                .generate(
                  sectionKey: state.sections[index].sectionKey,
                  regenerate: false,
                ),
            onRegenerate: () => _confirmRegenerate(state.sections[index]),
            onValidate: () => _validate(state.sections[index]),
            onImage: () => _chooseImageAction(state.sections[index]),
            onCancel: () => notifier.cancel(),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

}

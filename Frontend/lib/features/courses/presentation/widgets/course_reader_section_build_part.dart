part of '../pages/course_reader_body.dart';

/// Panneau de construction par sections (RG4/RG27).
///
/// Affiche chaque section avec son statut (À générer / À valider / Validée)
/// et les actions : Générer, Régénérer, Valider, Chercher des images.
class _SectionBuildPanel extends ConsumerWidget {
  final String courseId;

  const _SectionBuildPanel({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(courseSectionBuildProvider(courseId));

    ref.listen<CourseSectionBuildState>(courseSectionBuildProvider(courseId), (
      prev,
      next,
    ) {
      if (next.streamError != null && prev?.streamError != next.streamError) {
        // En cas d'erreur de stream (ex: timeout), forcer un reload car le backend a peut-être fini
        ref.read(courseSectionBuildProvider(courseId).notifier).load();
        _showCourseFailure(context, next.streamError!);
      }
    });

    if (state.loading) {
      return const SmartLoader.medium(message: 'Chargement des sections...');
    }
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          context.tr('ai_build_error'),
          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        ),
      );
    }

    final hasOutline = state.initializedFromOutline;
    final hasSections = state.sections.isNotEmpty;

    // Cas 1 : aucun plan généré encore
    if (!hasOutline && !hasSections) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('ai_build_no_outline'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/courses/ai-create'),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(context.tr('ai_outline_generate_direct')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Cas 2 : plan détecté, sections pas encore matérialisées
    if (hasOutline && !hasSections) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('ai_build_outline_ready'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/courses/$courseId/build'),
                icon: const Icon(Icons.build_circle, size: 18),
                label: Text(context.tr('ai_build_save_outline')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Cas 3 : sections existent — panneau de construction
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('ai_build_title'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (state.remainingToValidate > 0)
                    Text(
                      context.tr(
                        'ai_build_remaining',
                        args: {'count': state.remainingToValidate.toString()},
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (state.remainingToValidate > 0)
                    FilledButton.icon(
                      onPressed: state.isStreaming || state.isGeneratingAll
                          ? () => ref
                                .read(
                                  courseSectionBuildProvider(courseId).notifier,
                                )
                                .cancel()
                          : () => ref
                                .read(
                                  courseSectionBuildProvider(courseId).notifier,
                                )
                                .generateAllRemaining(),
                      icon: Icon(
                        state.isGeneratingAll
                            ? Icons.stop_circle_outlined
                            : Icons.auto_awesome,
                        size: 16,
                      ),
                      label: Text(
                        state.isGeneratingAll
                            ? 'Arrêter'
                            : 'Tout générer (${state.remainingToValidate})',
                      ),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: state.isGeneratingAll
                            ? colorScheme.error
                            : colorScheme.primary,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/courses/$courseId/build'),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Modifier le plan'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ...state.sections.asMap().entries.map((entry) {
          final index = entry.key;
          final section = entry.value;
          final isCurrentStreaming = state.streamingKey == section.sectionKey;
          return CourseSectionCard(
            key: ValueKey(section.sectionKey),
            sectionNumber: index + 1,
            section: section,
            isStreaming: isCurrentStreaming,
            streamingPhase: isCurrentStreaming ? state.streamingPhase : null,
            streamingText: isCurrentStreaming ? state.streamingText : null,
            onCancelStream: isCurrentStreaming
                ? () => ref
                      .read(courseSectionBuildProvider(courseId).notifier)
                      .cancel()
                : null,
            onGenerate: () =>
                _generateSection(context, ref, section.sectionKey, false),
            onRegenerate: () =>
                _generateSection(context, ref, section.sectionKey, true),
            onValidate: () =>
                _validateSection(context, ref, section.sectionKey),
            onImageSearch: () =>
                _searchImages(context, ref, section.sectionKey),
          );
        }),
      ],
    );
  }

  Future<void> _generateSection(
    BuildContext context,
    WidgetRef ref,
    String sectionKey,
    bool regenerate,
  ) async {
    if (regenerate) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('ai_build_regenerate_title')),
          content: Text(context.tr('ai_build_regenerate_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr('ai_build_regenerate')),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    await ref
        .read(courseSectionBuildProvider(courseId).notifier)
        .generate(sectionKey: sectionKey, regenerate: regenerate);
    if (!context.mounted) return;
    await ref.read(courseSectionBuildProvider(courseId).notifier).load();
  }

  Future<void> _validateSection(
    BuildContext context,
    WidgetRef ref,
    String sectionKey,
  ) async {
    try {
      await ref
          .read(courseSectionBuildProvider(courseId).notifier)
          .validate(sectionKey);
      ref
        ..invalidate(generatedCourseProvider(courseId))
        ..invalidate(myGeneratedCoursesProvider)
        ..invalidate(publishedCoursesProvider);
      if (!context.mounted) return;
      final remaining = ref
          .read(courseSectionBuildProvider(courseId))
          .remainingToValidate;
      context.showSuccessToast(
        context.tr(
          'ai_build_validated_snack',
          args: {'count': remaining.toString()},
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showCourseFailure(context, e);
    }
  }

  void _showCourseFailure(BuildContext context, Object error) {
    final Failure failure = error is ApiException
        ? apiExceptionToFailure(error)
        : error as Failure;
    final l10n = failureL10n(failure);
    context.showErrorToast(context.tr(l10n.key, args: l10n.args));
  }

  Future<void> _searchImages(
    BuildContext context,
    WidgetRef ref,
    String sectionKey,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr('ai_image_choose_title'),
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(context.tr('ai_image_generate_local')),
              subtitle: Text(context.tr('ai_image_generate_local_desc')),
              onTap: () => Navigator.of(ctx).pop('local'),
            ),
            ListTile(
              leading: const Icon(Icons.image_search_rounded),
              title: Text(context.tr('ai_image_search_web')),
              subtitle: Text(context.tr('ai_image_search_web_desc')),
              onTap: () => Navigator.of(ctx).pop('web'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;

    if (choice == 'local') {
      try {
        context.showInfoToast('Génération en cours avec ComfyUI (SDXL)...');
        final result = await ref
            .read(courseSectionBuildProvider(courseId).notifier)
            .generateSectionImage(sectionKey);
        if (!context.mounted) return;
        final imageUrl = result['imageUrl']?.toString() ?? '';
        final prompt = result['prompt']?.toString();
        final insert = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(context.tr('ai_build_image_title')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isEmpty
                      ? const SizedBox.shrink()
                      : Image.network(
                          imageUrl,
                          errorBuilder: (_, _, _) => const Padding(
                            padding: EdgeInsets.all(16),
                            child: Icon(Icons.broken_image_outlined, size: 48),
                          ),
                        ),
                ),
                if (prompt != null && prompt.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    prompt,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(context.tr('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(context.tr('ai_build_image_insert')),
              ),
            ],
          ),
        );
        if (insert == true && context.mounted) {
          await ref
              .read(courseSectionBuildProvider(courseId).notifier)
              .applySectionImage(
                sectionKey: sectionKey,
                imageUrl: imageUrl,
                caption: prompt,
              );
          if (context.mounted) {
            context.showSuccessToast(context.tr('ai_image_added'));
          }
        }
      } catch (e) {
        if (!context.mounted) return;
        _showCourseFailure(context, e);
      }
    } else {
      try {
        final state = ref.read(courseSectionBuildProvider(courseId));
        final section = state.section(sectionKey);
        String? query;
        if (section != null) {
          if (section.keyTopics.isNotEmpty) {
            query = section.keyTopics.take(3).join(' ');
          } else if (section.title.isNotEmpty) {
            query = section.title;
          }
        }

        context.showInfoToast(
          'Recherche de 5 images sur le web via le modèle IA...',
        );
        final candidates = await ref
            .read(courseSectionBuildProvider(courseId).notifier)
            .searchSectionImages(sectionKey, query: query);
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => CourseImageSearchDialog(
            candidates: candidates,
            onInsert: (imageUrl, caption) async {
              await ref
                  .read(courseSectionBuildProvider(courseId).notifier)
                  .applySectionImage(
                    sectionKey: sectionKey,
                    imageUrl: imageUrl,
                    caption: caption,
                  );
              if (context.mounted) {
                context.pop();
                context.showSuccessToast(context.tr('ai_image_added'));
              }
            },
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        _showCourseFailure(context, e);
      }
    }
  }
}

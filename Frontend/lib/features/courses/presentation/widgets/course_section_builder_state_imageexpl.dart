part of '../pages/course_section_builder_page.dart';
extension on _CourseSectionBuilderPageState {
  String _imageExplanation(CourseSectionEntry section) {
    final description = section.description.trim();
    if (description.isNotEmpty) return description;
    return section.keyTopics.join(' · ');
  }

  /// Two image options for a section: local ComfyUI generation or a web
  /// search returning five candidates.
  Future<void> _chooseImageAction(CourseSectionEntry section) async {
    if (_imageActionBusy(section.sectionKey)) return;
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
    if (!mounted || choice == null) return;
    if (choice == 'local') {
      await _generateImage(section);
    } else {
      await _searchWebImage(section);
    }
  }

  Future<void> _applyImage(
    CourseSectionEntry section, {
    required String imageUrl,
    String? caption,
  }) async {
    try {
      await _build.applySectionImage(
        sectionKey: section.sectionKey,
        imageUrl: imageUrl,
        caption: caption,
      );
      if (!mounted) return;
      _showSnack('ai_image_added');
    } catch (e) {
      if (!mounted) return;
      _showBuildFailure(context, e);
    }
  }

  Future<void> _searchWebImage(
    CourseSectionEntry section, {
    String? query,
  }) async {
    if (_imageActionBusy(section.sectionKey)) return;
    updateState(() => _imageLoadingKey = section.sectionKey);
    try {
      final queryToUse = query ?? section.keyTopics.join(' ');
      final images = await _build.searchSectionImages(
        section.sectionKey,
        query: queryToUse,
      );
      if (!mounted) return;
      updateState(() => _imageLoadingKey = null);
      if (images.isEmpty) {
        // A refined query that still finds nothing is a dead end: keep the
        // honest one-shot toast instead of looping the dialog forever.
        if (query != null) {
          context.showInfoToast(context.tr('ai_image_search_empty'));
          return;
        }
        final retry = await showDialog<_ImageRetry>(
          context: context,
          builder: (ctx) => const _NoImageFoundDialog(),
        );
        if (!mounted || retry == null) return;
        if (retry.regenerate) {
          await _searchWebImage(section);
        } else if (retry.query != null && retry.query!.isNotEmpty) {
          await _searchWebImage(section, query: retry.query);
        }
        return;
      }
      final selected = await showDialog<SectionImageCandidate>(
        context: context,
        builder: (ctx) => _WebImagePickerDialog(images: images),
      );
      if (selected == null || !mounted) return;
      await _applyImage(
        section,
        imageUrl: selected.url,
        caption: selected.caption.isNotEmpty
            ? selected.caption
            : selected.title,
      );
    } catch (e) {
      if (!mounted) return;
      _showBuildFailure(context, e);
    } finally {
      if (mounted) updateState(() => _imageLoadingKey = null);
    }
  }

  Future<void> _generateImage(CourseSectionEntry section) async {
    if (_imageActionBusy(section.sectionKey)) return;
    updateState(() => _imageLoadingKey = section.sectionKey);
    try {
      final result = await _build.generateSectionImage(section.sectionKey);
      if (!mounted) return;
      // The request is over: stop the card spinner before opening the
      // dialog (an indeterminate spinner behind the dialog never settles).
      updateState(() => _imageLoadingKey = null);
      final imageUrl = result['imageUrl']?.toString() ?? '';
      final prompt = result['prompt']?.toString();
      final provider = result['provider']?.toString();
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
                        errorBuilder: (_, _, _) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: Theme.of(ctx).colorScheme.outline,
                          ),
                        ),
                      ),
              ),
              if (_imageExplanation(section).isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  context.tr('ai_build_image_explanation'),
                  style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _imageExplanation(section),
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (prompt != null && prompt.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  prompt,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (provider != null && provider.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    provider,
                    style: Theme.of(ctx).textTheme.labelSmall,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(context.tr('close')),
            ),
            FilledButton.icon(
              onPressed: imageUrl.isEmpty
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(context.tr('ai_image_insert')),
            ),
          ],
        ),
      );
      if (insert == true && imageUrl.isNotEmpty && mounted) {
        await _applyImage(
          section,
          imageUrl: imageUrl,
          caption: _imageExplanation(section),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showBuildFailure(context, e);
    } finally {
      if (mounted) updateState(() => _imageLoadingKey = null);
    }
  }
}

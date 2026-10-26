import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../application/providers/course_section_build_provider.dart';
import '../../domain/entities/course_section.dart';
import '../widgets/markdown_course_view.dart';
import '../../../../core/widgets/smart_loader.dart';

void _showBuildFailure(BuildContext context, Object error) {
  // ComfyUI unavailable: point the teacher to the web image search.
  if (error is ApiException && error.code == 'IMAGE_SERVICE_UNAVAILABLE') {
    context.showInfoToast(context.tr('ai_build_image_soon'));
    return;
  }
  final String key;
  final Map<String, String> args;
  if (error is ApiException) {
    final l10n = failureL10n(apiExceptionToFailure(error));
    key = l10n.key;
    args = l10n.args;
  } else if (error is Failure) {
    final l10n = failureL10n(error);
    key = l10n.key;
    args = l10n.args;
  } else {
    key = 'something_went_wrong';
    args = const {};
  }
  context.showErrorToast(context.tr(key, args: args));
}

/// Per-section build page (`/courses/:courseId/build`): generate → review →
/// validate each chapter one at a time (RG4/RG27 — the draft only becomes
/// publishable once every section is VALIDATED).
class CourseSectionBuilderPage extends ConsumerStatefulWidget {
  const CourseSectionBuilderPage({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseSectionBuilderPage> createState() =>
      _CourseSectionBuilderPageState();
}

class _CourseSectionBuilderPageState
    extends ConsumerState<CourseSectionBuilderPage> {
  /// Section currently asking ComfyUI for an illustration (button spinner).
  String? _imageLoadingKey;

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always refresh: another tab (reader) may have changed statuses.
      _build.load();
    });
  }

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
    setState(() => _imageLoadingKey = section.sectionKey);
    try {
      final queryToUse = query ?? section.keyTopics.join(' ');
      final images = await _build.searchSectionImages(
        section.sectionKey,
        query: queryToUse,
      );
      if (!mounted) return;
      setState(() => _imageLoadingKey = null);
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
      if (mounted) setState(() => _imageLoadingKey = null);
    }
  }

  Future<void> _generateImage(CourseSectionEntry section) async {
    if (_imageActionBusy(section.sectionKey)) return;
    setState(() => _imageLoadingKey = section.sectionKey);
    try {
      final result = await _build.generateSectionImage(section.sectionKey);
      if (!mounted) return;
      // The request is over: stop the card spinner before opening the
      // dialog (an indeterminate spinner behind the dialog never settles).
      setState(() => _imageLoadingKey = null);
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
      if (mounted) setState(() => _imageLoadingKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _buildProgressDashboard(
    BuildContext context,
    CourseSectionBuildState state,
    CourseSectionBuild notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = state.sections.length;
    final validated = state.validatedCount;
    final allValidated = total > 0 && state.remainingToValidate == 0;
    final generated = state.sections
        .where((s) => s.status == CourseSectionStatus.generated)
        .length;
    final pending = state.sections
        .where((s) => s.status == CourseSectionStatus.pending)
        .length;
    final progress = total == 0 ? 0.0 : (validated / total).clamp(0.0, 1.0);
    final activeStreamingKey = state.streamingKey;
    final isGenerating = state.isStreaming || state.isGeneratingAll;
    final activeSection = activeStreamingKey != null
        ? state.section(activeStreamingKey)
        : null;
    final activeIndex = activeSection != null
        ? state.sections.indexOf(activeSection)
        : -1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGenerating
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : (allValidated
                ? colorScheme.secondaryContainer.withValues(alpha: 0.35)
                : colorScheme.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGenerating
              ? colorScheme.primary.withValues(alpha: 0.55)
              : (allValidated
                  ? colorScheme.secondary.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant.withValues(alpha: 0.45)),
          width: isGenerating ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isGenerating
                ? colorScheme.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Status icon + Description & Action Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isGenerating
                      ? colorScheme.primary
                      : (allValidated
                          ? colorScheme.secondary
                          : colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: isGenerating
                      ? const SmartLoader.small(customSize: 18, color: Colors.white)
                      : Icon(
                          allValidated
                              ? Icons.verified_rounded
                              : Icons.auto_awesome_rounded,
                          size: 20,
                          color: allValidated
                              ? colorScheme.onSecondary
                              : colorScheme.primary,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGenerating
                          ? 'Génération en cours...'
                          : (allValidated
                              ? 'Cours complet prêt !'
                              : 'Construction du cours'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isGenerating
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGenerating && activeSection != null
                          ? 'Section ${activeIndex + 1}/$total : "${activeSection.title}"'
                          : (allValidated
                              ? 'Toutes les sections sont rédigées et validées'
                              : '$pending section(s) restante(s) à générer'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isGenerating)
                FilledButton.icon(
                  onPressed: () => notifier.cancel(),
                  icon: const Icon(Icons.stop_rounded, size: 16),
                  label: const Text('Arrêter'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                )
              else if (!allValidated)
                FilledButton.icon(
                  onPressed: () => notifier.generateAllRemaining(),
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('Tout générer'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () => context.push('/courses/${widget.courseId}'),
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: const Text('Lire'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                allValidated ? colorScheme.secondary : colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBadge(
                icon: Icons.check_circle_rounded,
                color: Colors.green.shade700,
                label: '$validated validée(s)',
              ),
              if (activeSection != null)
                _buildStatBadge(
                  icon: Icons.bolt_rounded,
                  color: colorScheme.primary,
                  label: '1 en cours',
                ),
              if (generated > 0)
                _buildStatBadge(
                  icon: Icons.edit_note_rounded,
                  color: Colors.amber.shade800,
                  label: '$generated à relire',
                ),
              _buildStatBadge(
                icon: Icons.hourglass_empty_rounded,
                color: colorScheme.onSurfaceVariant,
                label: '$pending en attente',
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Interactive Stepper Strip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < state.sections.length; i++) ...[
                    _buildSectionNavChip(
                      context: context,
                      index: i,
                      section: state.sections[i],
                      isCurrent:
                          state.streamingKey == state.sections[i].sectionKey,
                      onTap: () =>
                          _scrollToSection(state.sections[i].sectionKey),
                    ),
                    if (i < state.sections.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionNavChip({
    required BuildContext context,
    required int index,
    required CourseSectionEntry section,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isValidated = section.status == CourseSectionStatus.validated;
    final isGenerated = section.status == CourseSectionStatus.generated;

    Color bg;
    Color fg;
    Widget iconWidget;

    if (isCurrent) {
      bg = colorScheme.primary;
      fg = colorScheme.onPrimary;
      iconWidget =
          const SmartLoader.small(customSize: 12, color: Colors.white);
    } else if (isValidated) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      iconWidget = Icon(Icons.check_circle_rounded, size: 14, color: fg);
    } else if (isGenerated) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade800;
      iconWidget = Icon(Icons.edit_note_rounded, size: 14, color: fg);
    } else {
      bg = colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
      fg = colorScheme.onSurfaceVariant;
      iconWidget = Icon(Icons.hourglass_empty_rounded, size: 13, color: fg);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent
                ? colorScheme.primary
                : (isValidated
                    ? Colors.green.shade300
                    : colorScheme.outlineVariant.withValues(alpha: 0.4)),
            width: isCurrent ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 5),
            Text(
              'S${index + 1}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.index,
    required this.section,
    required this.state,
    required this.imageLoading,
    required this.onGenerate,
    required this.onRegenerate,
    required this.onValidate,
    required this.onImage,
    required this.onCancel,
  });

  final int index;
  final CourseSectionEntry section;
  final CourseSectionBuildState state;
  final bool imageLoading;
  final Future<void> Function() onGenerate;
  final Future<void> Function() onRegenerate;
  final Future<void> Function() onValidate;
  final Future<void> Function() onImage;
  final VoidCallback onCancel;

  Color _statusColor(ColorScheme colors, bool isStreaming) {
    if (isStreaming) {
      return colors.primary;
    }
    switch (section.status) {
      case CourseSectionStatus.validated:
        return Colors.green.shade50;
      case CourseSectionStatus.generated:
        return const Color(0xFFFEF3C7);
      case CourseSectionStatus.pending:
        return colors.surfaceContainerHighest;
    }
  }

  Color _statusTextColor(ColorScheme colors, bool isStreaming) {
    if (isStreaming) {
      return colors.onPrimary;
    }
    switch (section.status) {
      case CourseSectionStatus.validated:
        return Colors.green.shade800;
      case CourseSectionStatus.generated:
        return const Color(0xFF92400E);
      case CourseSectionStatus.pending:
        return colors.onSurfaceVariant;
    }
  }

  IconData _statusIcon(bool isStreaming) {
    if (isStreaming) {
      return Icons.bolt_rounded;
    }
    switch (section.status) {
      case CourseSectionStatus.validated:
        return Icons.check_circle_rounded;
      case CourseSectionStatus.generated:
        return Icons.rate_review_outlined;
      case CourseSectionStatus.pending:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _statusLabel(
    BuildContext context, {
    required bool isStreaming,
    required bool isNext,
  }) {
    if (isStreaming) {
      return 'EN COURS DE RÉDACTION...';
    }
    switch (section.status) {
      case CourseSectionStatus.validated:
        return 'Validée & Prête';
      case CourseSectionStatus.generated:
        return 'Rédigée (À valider)';
      case CourseSectionStatus.pending:
        return isNext ? 'Prochaine en attente' : 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isStreaming = state.streamingKey == section.sectionKey;
    final otherBusy = state.isStreaming && !isStreaming;
    final isValidated = section.status == CourseSectionStatus.validated;
    final isGenerated = section.status == CourseSectionStatus.generated;
    final isPending = section.status == CourseSectionStatus.pending;

    final pendingSections = state.sections
        .where((s) => s.status == CourseSectionStatus.pending)
        .toList();
    final isNext = isPending &&
        pendingSections.isNotEmpty &&
        pendingSections.first.sectionKey == section.sectionKey;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: (isPending && (otherBusy || state.isGeneratingAll)) ? 0.72 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: isStreaming
              ? colorScheme.primaryContainer.withValues(alpha: 0.12)
              : (isValidated
                  ? Colors.green.withValues(alpha: 0.02)
                  : colorScheme.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isStreaming
                ? colorScheme.primary
                : (isValidated
                    ? Colors.green.shade400.withValues(alpha: 0.5)
                    : (isGenerated
                        ? Colors.amber.shade400.withValues(alpha: 0.6)
                        : colorScheme.outlineVariant.withValues(alpha: 0.45))),
            width: isStreaming ? 2.0 : (isValidated ? 1.3 : 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: isStreaming
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isStreaming ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: badge + status chip + duration.
              Row(
                children: [
                  Flexible(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isStreaming
                                ? colorScheme.primary
                                : colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.tr(
                              'ai_build_section_num',
                              args: {'n': (index + 1).toString().padLeft(2, '0')},
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.5,
                              color: isStreaming
                                  ? colorScheme.onPrimary
                                  : colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(colorScheme, isStreaming),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isStreaming) ...[
                                const SmartLoader.small(
                                  customSize: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                              ] else ...[
                                Icon(
                                  _statusIcon(isStreaming),
                                  size: 13,
                                  color: _statusTextColor(
                                    colorScheme,
                                    isStreaming,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                _statusLabel(
                                  context,
                                  isStreaming: isStreaming,
                                  isNext: isNext,
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _statusTextColor(
                                    colorScheme,
                                    isStreaming,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${section.estimatedMinutes} min',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title + description.
            Text(
              section.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            if (section.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                section.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],

            // Key topic pills.
            if (section.keyTopics.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final topic in section.keyTopics)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Text(
                        topic,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            // Live streaming panel (progress + preview + cancel).
            if (isStreaming) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SmartLoader.small(customSize: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.streamingPhase == 'memory'
                                ? context.tr('ai_build_phase_memory')
                                : context.tr('ai_build_phase_generating'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: Text(context.tr('cancel')),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(minHeight: 3),
                    if (state.streamingText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: SingleChildScrollView(
                          child: Text(
                            state.streamingText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              // Markdown preview of the generated content.
              if (section.hasContent) ...[
                const SizedBox(height: 6),
                // Inner Material: the tile's ListTile must paint its ink on
                // a Material *inside* the card's decorated surface.
                Material(
                  color: colorScheme.surface,
                  child: Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      dense: true,
                      title: Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('ai_build_preview'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      children: [MarkdownCourseView(data: section.content!)],
                    ),
                  ),
                ),
              ],

              // Actions by status.
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (section.status == CourseSectionStatus.pending)
                    FilledButton.icon(
                      onPressed: otherBusy ? null : () => onGenerate(),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text(context.tr('ai_build_generate')),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  if (section.status == CourseSectionStatus.generated)
                    FilledButton.icon(
                      onPressed: otherBusy ? null : () => onValidate(),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(context.tr('ai_build_validate')),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  if (section.status != CourseSectionStatus.pending)
                    OutlinedButton.icon(
                      onPressed: otherBusy ? null : () => onRegenerate(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(context.tr('ai_build_regenerate')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: context.tr('ai_build_image'),
                    onPressed: otherBusy || imageLoading
                        ? null
                        : () => onImage(),
                    icon: imageLoading
                        ? const SmartLoader.small(customSize: 18)
                        : const Icon(Icons.image_outlined, size: 20),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}

/// Five web image candidates, tappable to insert into the section.
class _WebImagePickerDialog extends StatelessWidget {
  const _WebImagePickerDialog({required this.images});

  final List<SectionImageCandidate> images;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('ai_image_search_title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 560 ? 3 : 2;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.86,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final image = images[index];
                      return Material(
                        color: colorScheme.surfaceContainerLowest,
                        clipBehavior: Clip.antiAlias,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(image),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Image.network(
                                  image.url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => ColoredBox(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  image.caption.isNotEmpty
                                      ? image.caption
                                      : image.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Result of the "no image found" dialog: either a plain regenerate retry
/// or a refined query built from the teacher's text input.
class _ImageRetry {
  final bool regenerate;
  final String? query;

  const _ImageRetry.regenerate()
      : regenerate = true,
        query = null;

  const _ImageRetry.refine(this.query) : regenerate = false;
}

/// Shown when the web image search returns no candidate for a section.
/// Offers two honest escapes: regenerate the search as-is, or refine the
/// query (e.g. "diagramme base de données") and search again.
class _NoImageFoundDialog extends StatefulWidget {
  const _NoImageFoundDialog();

  @override
  State<_NoImageFoundDialog> createState() => _NoImageFoundDialogState();
}

class _NoImageFoundDialogState extends State<_NoImageFoundDialog> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      scrollable: true,
      title: Row(
        children: [
          Icon(Icons.image_not_supported_outlined, color: colorScheme.error),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              context.tr('ai_image_no_result_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('ai_image_search_empty'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: context.tr('ai_image_refine_hint'),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                final trimmed = value.trim();
                Navigator.of(context).pop(
                  trimmed.isEmpty
                      ? const _ImageRetry.regenerate()
                      : _ImageRetry.refine(trimmed),
                );
              },
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(const _ImageRetry.regenerate()),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(context.tr('ai_image_retry_regenerate')),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _queryController,
          builder: (context, value, _) {
            final trimmed = value.text.trim();
            return FilledButton.icon(
              onPressed: trimmed.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(
                        _ImageRetry.refine(trimmed),
                      ),
              icon: const Icon(Icons.travel_explore_rounded, size: 18),
              label: Text(context.tr('ai_image_retry_refine')),
            );
          },
        ),
      ],
    );
  }
}

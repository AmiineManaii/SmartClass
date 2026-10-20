import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../application/providers/course_section_build_provider.dart';
import '../../domain/entities/course_section.dart';
import '../widgets/markdown_course_view.dart';

void _showBuildFailure(BuildContext context, Object error) {
  // ComfyUI is not wired yet: honest "coming soon" instead of a raw 503.
  if (error is ApiException &&
      error.code == 'IMAGE_SERVICE_UNAVAILABLE') {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('ai_build_image_soon')),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.tr(key, args: args)),
      behavior: SnackBarBehavior.floating,
    ),
  );
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

  void _showSnack(String key, {Map<String, String>? args}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(key, args: args)),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  Future<void> _generateImage(CourseSectionEntry section) async {
    if (_imageLoadingKey != null) return;
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
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(ctx).colorScheme.surfaceContainerHighest,
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
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(context.tr('close')),
            ),
          ],
        ),
      );
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

    final bool allValidated =
        state.sections.isNotEmpty && state.remainingToValidate == 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

    if (state.loading &&
        state.sections.isEmpty &&
        state.error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 44, color: colorScheme.outline),
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
                onPressed: () =>
                    ref.read(courseSectionBuildProvider(widget.courseId).notifier).load(),
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
              Icon(Icons.list_alt_rounded,
                  size: 44, color: colorScheme.outline),
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

    final allValidated = state.remainingToValidate == 0;
    final notifier =
        ref.read(courseSectionBuildProvider(widget.courseId).notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // Publication gate banner.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: allValidated
                ? colorScheme.secondaryContainer
                : colorScheme.primaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (allValidated
                      ? colorScheme.secondary
                      : colorScheme.primary)
                  .withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                allValidated
                    ? Icons.verified_rounded
                    : Icons.rule_rounded,
                size: 22,
                color: allValidated
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  allValidated
                      ? context.tr('ai_build_all_validated')
                      : context.tr(
                          'ai_build_remaining',
                          args: {
                            'count': '${state.remainingToValidate}',
                          },
                        ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: allValidated
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onPrimaryContainer,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < state.sections.length; index++) ...[
          _SectionCard(
            index: index,
            section: state.sections[index],
            state: state,
            imageLoading: _imageLoadingKey ==
                state.sections[index].sectionKey,
            onGenerate: () => ref
                .read(courseSectionBuildProvider(widget.courseId).notifier)
                .generate(
              sectionKey: state.sections[index].sectionKey,
              regenerate: false,
            ),
            onRegenerate: () =>
                _confirmRegenerate(state.sections[index]),
            onValidate: () => _validate(state.sections[index]),
            onImage: () => _generateImage(state.sections[index]),
            onCancel: () => notifier.cancel(),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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

  Color _statusColor(ColorScheme colors) {
    switch (section.status) {
      case CourseSectionStatus.validated:
        return colors.secondaryContainer;
      case CourseSectionStatus.generated:
        return colors.primaryContainer;
      case CourseSectionStatus.pending:
        return colors.surfaceContainerHighest;
    }
  }

  Color _statusTextColor(ColorScheme colors) {
    switch (section.status) {
      case CourseSectionStatus.validated:
        return colors.onSecondaryContainer;
      case CourseSectionStatus.generated:
        return colors.onPrimaryContainer;
      case CourseSectionStatus.pending:
        return colors.onSurfaceVariant;
    }
  }

  IconData _statusIcon() {
    switch (section.status) {
      case CourseSectionStatus.validated:
        return Icons.check_circle_rounded;
      case CourseSectionStatus.generated:
        return Icons.rate_review_outlined;
      case CourseSectionStatus.pending:
        return Icons.pending_actions_outlined;
    }
  }

  String _statusLabel(BuildContext context) {
    switch (section.status) {
      case CourseSectionStatus.validated:
        return context.tr('ai_build_status_validated');
      case CourseSectionStatus.generated:
        return context.tr('ai_build_status_generated');
      case CourseSectionStatus.pending:
        return context.tr('ai_build_status_pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isStreaming = state.streamingKey == section.sectionKey;
    final otherBusy = state.isStreaming && !isStreaming;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStreaming
              ? colorScheme.primary.withValues(alpha: 0.55)
              : colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: isStreaming ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          context.tr(
                            'ai_build_section_num',
                            args: {
                              'n': (index + 1).toString().padLeft(2, '0'),
                            },
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(colorScheme),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(),
                                size: 13,
                                color: _statusTextColor(colorScheme)),
                            const SizedBox(width: 4),
                            Text(
                              _statusLabel(context),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _statusTextColor(colorScheme),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 12,
                                color: colorScheme.onSurfaceVariant),
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
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.35),
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
                  color: colorScheme.primaryContainer
                      .withValues(alpha: 0.45),
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
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
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
                          Icon(Icons.description_outlined,
                              size: 16, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('ai_build_preview'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      children: [
                        MarkdownCourseView(data: section.content!),
                      ],
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
                      onPressed: otherBusy
                          ? null
                          : () => onGenerate(),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text(context.tr('ai_build_generate')),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  if (section.status == CourseSectionStatus.generated)
                    FilledButton.icon(
                      onPressed: otherBusy
                          ? null
                          : () => onValidate(),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(context.tr('ai_build_validate')),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  if (section.status != CourseSectionStatus.pending)
                    OutlinedButton.icon(
                      onPressed: otherBusy
                          ? null
                          : () => onRegenerate(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(context.tr('ai_build_regenerate')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  IconButton(
                    tooltip: context.tr('ai_build_image'),
                    onPressed: otherBusy || imageLoading
                        ? null
                        : () => onImage(),
                    icon: imageLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Icon(Icons.image_outlined, size: 20),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

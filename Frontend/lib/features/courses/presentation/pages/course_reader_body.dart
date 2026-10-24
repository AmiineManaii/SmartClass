import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/course_section_build_provider.dart';
import '../../application/providers/courses_provider.dart';
import '../../domain/entities/course_outline.dart';
import '../../domain/entities/generated_course.dart';
import '../widgets/ai_section_refine_dialog.dart';
import '../widgets/course_image_search_dialog.dart';
import '../widgets/course_reader_actions.dart';
import '../widgets/course_section_card.dart';
import '../widgets/markdown_course_view.dart';

/// Corps du lecteur de cours : affiche le contenu, les sections et les actions.
///
/// Séparé de `CourseReaderPage` pour respecter la limite de taille de fichier
/// (PROJECT_CONTEXT §7 : fichiers courts, un widget par responsabilité).
class CourseReaderBody extends ConsumerStatefulWidget {
  final GeneratedCourse course;
  final String courseId;
  final VoidCallback onCopy;

  const CourseReaderBody({
    super.key,
    required this.course,
    required this.courseId,
    required this.onCopy,
  });

  @override
  ConsumerState<CourseReaderBody> createState() => _CourseReaderBodyState();
}

class _CourseReaderBodyState extends ConsumerState<CourseReaderBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(courseSectionBuildProvider(widget.courseId).notifier).load();
      }
    });
  }

  bool _canModerate(String? role, String? userId) {
    if (role == 'admin') return true;
    return role == 'teacher' && userId != null && userId == widget.course.authorId;
  }

  void _showCourseFailure(BuildContext context, Object error) {
    final Failure failure =
        error is ApiException ? apiExceptionToFailure(error) : error as Failure;
    final l10n = failureL10n(failure);
    context.showErrorToast(context.tr(l10n.key, args: l10n.args));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    final canModerate = _canModerate(auth?.role, auth?.userId);

    final content = widget.course.content ?? '';
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final readingMin = (words / 200).ceil().clamp(1, 180);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Meta strip : auteur, statut (Brouillon/Publié), durée de lecture
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _CourseMetaStrip(
              course: widget.course,
              readingMin: readingMin,
            ),
          ),
          const Divider(height: 1),

          // Sommaire (extraits des titres Markdown)
          if (content.contains('#')) _SommaireChip(content: content),

          // Lecture du contenu Markdown
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.course.content?.isNotEmpty == true)
                    MarkdownCourseView(data: widget.course.content!),

                  // Afficher le plan détaillé pour les brouillons avec outline
                  if (widget.course.isDraft && widget.course.outline != null)
                    _OutlinePreview(
                      outline: widget.course.outline!,
                      courseId: widget.courseId,
                    ),

                  const SizedBox(height: 24),

                  // Construction par sections (brouillons uniquement)
                  if (widget.course.isDraft)
                    _SectionBuildPanel(courseId: widget.courseId),

                  const SizedBox(height: 24),

                  // Actions modérateur (enseignant auteur ou admin)
                  if (canModerate)
                    CourseReaderActions(
                      course: widget.course,
                      onRefine: () => _refineWithAi(context),
                      onPublish: () => _publish(context),
                      onUnpublish: () => _unpublish(context),
                      onDelete: () => _delete(context),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refineWithAi(BuildContext context) async {
    final fullContent = widget.course.content ?? '';
    await AiSectionRefineDialog.show(
      context: context,
      fullCourseContent: fullContent,
      level: widget.course.level,
      difficulty: widget.course.difficulty,
      onApply: (oldText, newText) async {
        String updated;
        if (fullContent.contains(oldText)) {
          updated = fullContent.replaceFirst(oldText, newText);
        } else {
          updated = fullContent.replaceAll(oldText.trim(), newText);
        }

        await ref.read(generatedCoursesDataSourceProvider).updateCourse(
              id: widget.course.id,
              content: updated,
            );
        ref
          ..invalidate(generatedCourseProvider(widget.course.id))
          ..invalidate(myGeneratedCoursesProvider)
          ..invalidate(publishedCoursesProvider);
      },
    );
  }

  Future<void> _publish(BuildContext context) async {
    try {
      await ref.read(generatedCoursesDataSourceProvider).publish(widget.course.id);
      ref
        ..invalidate(generatedCourseProvider(widget.course.id))
        ..invalidate(myGeneratedCoursesProvider)
        ..invalidate(publishedCoursesProvider);
      if (!context.mounted) return;
      context.showSuccessToast(context.tr('published'));
    } catch (e) {
      if (!context.mounted) return;
      _showCourseFailure(context, e);
    }
  }

  Future<void> _unpublish(BuildContext context) async {
    try {
      await ref.read(generatedCoursesDataSourceProvider).unpublish(widget.course.id);
      ref
        ..invalidate(generatedCourseProvider(widget.course.id))
        ..invalidate(myGeneratedCoursesProvider)
        ..invalidate(publishedCoursesProvider);
      if (!context.mounted) return;
      context.showInfoToast(context.tr('draft'));
    } catch (e) {
      if (!context.mounted) return;
      _showCourseFailure(context, e);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete')),
        content: Text(context.tr('delete_course_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(generatedCoursesDataSourceProvider).deleteCourse(widget.course.id);
      ref
        ..invalidate(myGeneratedCoursesProvider)
        ..invalidate(publishedCoursesProvider);
      if (!context.mounted) return;
      context.showInfoToast(context.tr('course_deleted'));
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      _showCourseFailure(context, e);
    }
  }
}

/// Bandeau méta : auteur, statut (Brouillon/Publié), durée de lecture.
class _CourseMetaStrip extends StatelessWidget {
  final GeneratedCourse course;
  final int readingMin;

  const _CourseMetaStrip({
    required this.course,
    required this.readingMin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            course.authorName.isNotEmpty
                ? course.authorName[0].toUpperCase()
                : 'P',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Prof. ${course.authorName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: (course.isPublished
                              ? colorScheme.primary
                              : colorScheme.tertiary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      context.tr(course.isPublished ? 'published' : 'draft'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: course.isPublished
                            ? colorScheme.primary
                            : colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '~$readingMin min de lecture • ${_levelName(context, course.level)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _levelName(BuildContext context, String level) {
    return switch (level) {
      'concis' => context.tr('level_licence'),
      'detaille' => context.tr('level_doctorat'),
      _ => context.tr('level_master'),
    };
  }
}

/// Sommaire extrait des titres Markdown du cours.
class _SommaireChip extends StatelessWidget {
  final String content;

  const _SommaireChip({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headings = _extractHeadings(content);

    if (headings.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ActionChip(
        avatar: const Icon(Icons.list_alt_rounded, size: 14),
        label: Text(
          '${context.tr('course_sommaire')} (${headings.length})',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        side: BorderSide.none,
        onPressed: () => _showSommaire(context, headings),
      ),
    );
  }

  List<_HeadingItem> _extractHeadings(String content) {
    final lines = content.split('\n');
    final result = <_HeadingItem>[];
    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.startsWith('# ')) {
        result.add(_HeadingItem(
          title: trimmed.substring(2).trim(),
          level: 1,
          lineIndex: i,
        ));
      } else if (trimmed.startsWith('## ')) {
        result.add(_HeadingItem(
          title: trimmed.substring(3).trim(),
          level: 2,
          lineIndex: i,
        ));
      } else if (trimmed.startsWith('### ')) {
        result.add(_HeadingItem(
          title: trimmed.substring(4).trim(),
          level: 3,
          lineIndex: i,
        ));
      }
    }
    return result;
  }

  void _showSommaire(BuildContext context, List<_HeadingItem> headings) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${context.tr('course_sommaire')} (${headings.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: headings.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final h = headings[index];
                      final indent = (h.level - 1) * 16.0;
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(indent + 8, 10, 8, 10),
                          child: Row(
                            children: [
                              Icon(
                                _buildHeadingIcon(h, theme),
                                size: h.level == 3 ? 6 : 16,
                                color: h.level == 1
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  h.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: h.level == 1
                                        ? FontWeight.bold
                                        : h.level == 2
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

IconData _buildHeadingIcon(_HeadingItem h, ThemeData theme) {
  return switch (h.level) {
    1 => Icons.folder_rounded,
    2 => Icons.subdirectory_arrow_right_rounded,
    _ => Icons.circle,
  };
}

class _HeadingItem {
  final String title;
  final int level;
  final int lineIndex;

  const _HeadingItem({
    required this.title,
    required this.level,
    required this.lineIndex,
  });
}

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

    if (state.loading) {
      return const SmartLoader.medium(message: 'Chargement des sections...');
    }
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          context.tr('ai_build_error'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.error,
          ),
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
                          context.tr('ai_build_remaining', args: {'count': state.remainingToValidate.toString()}),
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
                                  .read(courseSectionBuildProvider(courseId).notifier)
                                  .cancel()
                              : () => ref
                                  .read(courseSectionBuildProvider(courseId).notifier)
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
              return CourseSectionCard(
                key: ValueKey(section.sectionKey),
                sectionNumber: index + 1,
                section: section,
                onGenerate: () =>
                    _generateSection(context, ref, section.sectionKey, false),
                onRegenerate: () =>
                    _generateSection(context, ref, section.sectionKey, true),
                onValidate: () => _validateSection(context, ref, section.sectionKey),
                onImageSearch: () =>
                    _searchImages(context, ref, section.sectionKey),
              );
            }).toList(),
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

    await ref.read(courseSectionBuildProvider(courseId).notifier).generate(
          sectionKey: sectionKey,
          regenerate: regenerate,
        );
  }

  Future<void> _validateSection(
    BuildContext context,
    WidgetRef ref,
    String sectionKey,
  ) async {
    try {
      await ref.read(courseSectionBuildProvider(courseId).notifier).validate(sectionKey);
      if (!context.mounted) return;
      context.showSuccessToast(context.tr('ai_build_validated_snack', args: {'count': '0'}));
    } catch (e) {
      if (!context.mounted) return;
      _showCourseFailure(context, e);
    }
  }

  void _showCourseFailure(BuildContext context, Object error) {
    final Failure failure =
        error is ApiException ? apiExceptionToFailure(error) : error as Failure;
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

        context.showInfoToast('Recherche de 5 images sur le web via le modèle IA...');
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

/// Aperçu du plan (outline) quand le contenu n'est pas encore généré.
///
/// Affiche les chapitres du plan validé par l'enseignant.
class _OutlinePreview extends StatelessWidget {
  final CourseOutline outline;
  final String courseId;

  const _OutlinePreview({required this.outline, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schema_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Plan du cours validé",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      "${outline.sections.length} chapitres prêts à être construits",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton modifier le plan
              IconButton(
                onPressed: () =>
                    GoRouter.of(context).push('/courses/$courseId/build'),
                icon: Icon(
                  Icons.edit_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                tooltip: 'Modifier le plan',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...outline.sections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (section.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            section.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (section.subtopics.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: section.subtopics
                                .take(4)
                                .map((topic) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        topic,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSecondaryContainer,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Les sections seront générées une par une via \"Construire section par section\".",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
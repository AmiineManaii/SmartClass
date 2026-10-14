import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../application/providers/courses_provider.dart';
import '../../domain/entities/generated_course.dart';
import '../widgets/ai_section_refine_dialog.dart';
import '../widgets/markdown_course_view.dart';

void _showCourseFailure(BuildContext context, Object error) {
  final Failure failure =
      error is ApiException ? apiExceptionToFailure(error) : error as Failure;
  final l10n = failureL10n(failure);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.tr(l10n.key, args: l10n.args)),
      behavior: SnackBarBehavior.floating,
    ),
  );
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

/// Reader for one generated course (`GET /api/v1/courses/:id`).
///
/// Published courses open for every authenticated user; drafts only for
/// their author (or an admin), who also gets validate/unpublish/delete
/// and in-line AI modification actions here.
class CourseReaderPage extends ConsumerWidget {
  final String courseId;

  const CourseReaderPage({super.key, required this.courseId});

  Future<void> _copyContent(BuildContext context, String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('ai_copied')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(generatedCourseProvider(courseId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          courseAsync.valueOrNull?.title ?? context.tr('course_details'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (courseAsync.valueOrNull != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: context.tr('course_export'),
              onSelected: (val) {
                if (val == 'copy') {
                  _copyContent(context, courseAsync.valueOrNull?.content ?? '');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      const Icon(Icons.copy_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(context.tr('course_export_copy')),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: courseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ReaderError(
          error: error,
          onRetry: () => ref.invalidate(generatedCourseProvider(courseId)),
        ),
        data: (course) => _ReaderBody(course: course),
      ),
    );
  }
}

class _ReaderBody extends ConsumerStatefulWidget {
  final GeneratedCourse course;

  const _ReaderBody({required this.course});

  @override
  ConsumerState<_ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends ConsumerState<_ReaderBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _canModerate(String? role, String? userId) {
    if (role == 'admin') return true;
    return role == 'teacher' && userId != null && userId == widget.course.authorId;
  }

  void _scrollToHeading(_HeadingItem item, int totalLines) {
    if (!_scrollController.hasClients || totalLines == 0) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final fraction = item.lineIndex / totalLines;
    final target = (maxScroll * fraction).clamp(0.0, maxScroll);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _showSommaire(BuildContext context, List<_HeadingItem> headings, int totalLines) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
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
                      Icon(Icons.list_alt_rounded, color: colorScheme.primary),
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
                if (headings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Aucun sous-titre détecté',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: headings.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final h = headings[index];
                        final indent = (h.level - 1) * 16.0;
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            _scrollToHeading(h, totalLines);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(indent + 8, 10, 8, 10),
                            child: Row(
                              children: [
                                Icon(
                                  h.level == 1
                                      ? Icons.folder_rounded
                                      : h.level == 2
                                          ? Icons.subdirectory_arrow_right_rounded
                                          : Icons.circle,
                                  size: h.level == 3 ? 6 : 16,
                                  color: h.level == 1
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('published')),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('draft')),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('course_deleted')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      _showCourseFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final canModerate = _canModerate(auth?.role, auth?.userId);

    final content = widget.course.content ?? '';
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final readingMin = (words / 200).ceil().clamp(1, 180);
    final headings = _extractHeadings(content);
    final totalLines = content.split('\n').length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(
                    context.tr(widget.course.isPublished ? 'published' : 'draft'),
                  ),
                  backgroundColor: (widget.course.isPublished
                          ? colorScheme.primary
                          : colorScheme.tertiary)
                      .withValues(alpha: 0.1),
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: widget.course.isPublished
                        ? colorScheme.primary
                        : colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '~$readingMin min',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _levelName(widget.course.level),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (headings.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.list_alt_rounded, size: 14),
                    label: Text('Sommaire (${headings.length})'),
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    side: BorderSide.none,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onPressed: () => _showSommaire(context, headings, totalLines),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Par ${widget.course.authorName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Course content body with scroll
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: MarkdownCourseView(data: content),
            ),
          ),

          // Moderator / Teacher actions bar
          if (canModerate)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Prominent In-line AI Refine button
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _refineWithAi(context),
                          icon: const Icon(Icons.auto_fix_high, size: 18),
                          label: Text(context.tr('ai_refine_btn')),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.tertiary,
                            foregroundColor: colorScheme.onTertiary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.course.isDraft)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _publish(context),
                            icon: const Icon(Icons.verified_outlined, size: 18),
                            label: Text(context.tr('validate_course')),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _unpublish(context),
                            icon: const Icon(Icons.visibility_off_outlined, size: 18),
                            label: Text(context.tr('unpublish_course')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            color: colorScheme.error),
                        tooltip: context.tr('delete'),
                        onPressed: () => _delete(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _levelName(String level) {
    return switch (level) {
      'concis' => 'Cours court',
      'detaille' => 'Cours complet',
      _ => 'Cours normal',
    };
  }
}

class _ReaderError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ReaderError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Failure failure = error is ApiException
        ? apiExceptionToFailure(error as ApiException)
        : error is Failure
            ? error as Failure
            : ServerFailure(error.toString());
    final l10n = failureL10n(failure);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(l10n.key, args: l10n.args),
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

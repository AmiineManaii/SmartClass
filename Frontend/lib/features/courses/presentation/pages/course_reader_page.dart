import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../application/providers/courses_provider.dart';
import '../../domain/entities/generated_course.dart';
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

/// Reader for one generated course (`GET /api/v1/courses/:id`).
///
/// Published courses open for every authenticated user; drafts only for
/// their author (or an admin), who also gets validate/unpublish/delete
/// actions here.
class CourseReaderPage extends ConsumerWidget {
  final String courseId;

  const CourseReaderPage({super.key, required this.courseId});

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

class _ReaderBody extends ConsumerWidget {
  final GeneratedCourse course;

  const _ReaderBody({required this.course});

  bool _canModerate(String? role, String? userId) {
    if (role == 'admin') return true;
    return role == 'teacher' && userId != null && userId == course.authorId;
  }

  Future<void> _publish(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(generatedCoursesDataSourceProvider).publish(course.id);
      ref
        ..invalidate(generatedCourseProvider(course.id))
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

  Future<void> _unpublish(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(generatedCoursesDataSourceProvider).unpublish(course.id);
      ref
        ..invalidate(generatedCourseProvider(course.id))
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

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
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
      await ref.read(generatedCoursesDataSourceProvider).deleteCourse(course.id);
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final canModerate = _canModerate(auth?.role, auth?.userId);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(context.tr(
                      course.isPublished ? 'published' : 'draft')),
                  backgroundColor: (course.isPublished
                          ? colorScheme.primary
                          : colorScheme.tertiary)
                      .withValues(alpha: 0.1),
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: course.isPublished
                        ? colorScheme.primary
                        : colorScheme.tertiary,
                  ),
                  side: BorderSide.none,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Text(
                  '${course.authorName} • ${_levelName(course.level)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: MarkdownCourseView(data: course.content ?? ''),
            ),
          ),
          if (canModerate)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (course.isDraft)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _publish(context, ref),
                        icon: const Icon(Icons.verified_outlined, size: 18),
                        label: Text(context.tr('validate_course')),
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _unpublish(context, ref),
                        icon: const Icon(Icons.visibility_off_outlined,
                            size: 18),
                        label: Text(context.tr('unpublish_course')),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: colorScheme.error),
                    tooltip: context.tr('delete'),
                    onPressed: () => _delete(context, ref),
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

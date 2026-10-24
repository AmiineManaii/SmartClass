import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../application/providers/courses_provider.dart';
import '../../domain/entities/generated_course.dart';

/// Carte d'un cours généré (brouillon ou publié).
///
/// - Affiche le badge brouillon/publié, le titre, l'auteur et la matière.
/// - Si `showValidate` est vrai et que le cours est un brouillon, affiche un
///   bouton de validation (publication) ainsi qu'un bouton de suppression.
/// - Le tap ouvre le lecteur de cours à `/courses/:courseId`.
class GeneratedCourseCard extends ConsumerWidget {
  final GeneratedCourse course;
  final bool showValidate;

  const GeneratedCourseCard({
    super.key,
    required this.course,
    required this.showValidate,
  });

  void _showFailure(BuildContext context, Object error) {
    final Failure failure = error is ApiException
        ? apiExceptionToFailure(error)
        : error as Failure;
    final l10n = failureL10n(failure);
    context.showErrorToast(context.tr(l10n.key, args: l10n.args));
  }

  Future<void> _validate(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(generatedCoursesDataSourceProvider).publish(course.id);
      ref
        ..invalidate(myGeneratedCoursesProvider)
        ..invalidate(publishedCoursesProvider);
      if (!context.mounted) return;
      context.showSuccessToast(context.tr('published'));
    } catch (e) {
      if (!context.mounted) return;
      _showFailure(context, e);
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
      await ref
          .read(generatedCoursesDataSourceProvider)
          .deleteCourse(course.id);
      ref
        ..invalidate(myGeneratedCoursesProvider)
        ..invalidate(publishedCoursesProvider);
      if (!context.mounted) return;
      context.showInfoToast(context.tr('course_deleted'));
    } catch (e) {
      if (!context.mounted) return;
      _showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = [
      if (course.subject != null && course.subject!.isNotEmpty)
        course.subject!,
      course.authorName,
    ].join(' • ');

    return InkWell(
      onTap: () => context.push('/courses/${course.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              offset: const Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(
                    context.tr(course.isPublished ? 'published' : 'draft'),
                  ),
                  backgroundColor:
                      (course.isPublished
                              ? colorScheme.primary
                              : colorScheme.tertiary)
                          .withValues(alpha: 0.1),
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: course.isPublished
                        ? colorScheme.primary
                        : colorScheme.tertiary,
                  ),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const Spacer(),
                if (showValidate && course.isDraft)
                  TextButton.icon(
                    onPressed: () => _validate(context, ref),
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: Text(context.tr('validate_course')),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (showValidate)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    tooltip: context.tr('delete'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _delete(context, ref),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              course.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

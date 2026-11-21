part of '../pages/course_reader_body.dart';

/// Bandeau méta : auteur, statut (Brouillon/Publié), durée de lecture.
class _CourseMetaStrip extends StatelessWidget {
  final GeneratedCourse course;
  final int readingMin;

  const _CourseMetaStrip({required this.course, required this.readingMin});

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (course.isPublished
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

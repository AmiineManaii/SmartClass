import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import 'staggered_list_item.dart';
import 'generated_course_card.dart';
import '../../domain/entities/generated_course.dart';

/// Liste de cours générés avec titre, état vide et apparition échelonnée.
class GeneratedList extends StatelessWidget {
  final String titleKey;
  final String emptyKey;
  final List<GeneratedCourse> courses;
  final bool showValidate;

  const GeneratedList({
    super.key,
    required this.titleKey,
    required this.emptyKey,
    required this.courses,
    required this.showValidate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr(titleKey)} (${courses.length})',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (courses.isEmpty)
          Text(
            context.tr(emptyKey),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => StaggeredListItem(
              index: index,
              child: GeneratedCourseCard(
                course: courses[index],
                showValidate: showValidate,
              ),
            ),
          ),
      ],
    );
  }
}

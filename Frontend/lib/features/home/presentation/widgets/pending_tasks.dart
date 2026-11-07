import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';

class PendingTasks extends StatelessWidget {
  final String role;

  const PendingTasks({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tasks = role == 'teacher'
        ? [
            {
              'title': 'Corriger les examens du groupe A',
              'count': 12,
              'icon': Icons.assignment_turned_in_rounded,
              'color': colorScheme.error,
            },
            {
              'title': 'Valider les cours en attente',
              'count': 3,
              'icon': Icons.pending_actions_rounded,
              'color': Colors.orange,
            },
            {
              'title': 'Répondre aux questions étudiants',
              'count': 5,
              'icon': Icons.question_answer_rounded,
              'color': colorScheme.primary,
            },
          ]
        : [
            {
              'title': 'Rendre le devoir de mathématiques',
              'count': 1,
              'icon': Icons.assignment_late_rounded,
              'color': colorScheme.error,
            },
            {
              'title': 'Réviser pour l\'examen de vendredi',
              'count': 3,
              'icon': Icons.schedule_rounded,
              'color': Colors.orange,
            },
            {
              'title': 'Participer au forum de discussion',
              'count': 2,
              'icon': Icons.forum_rounded,
              'color': colorScheme.primary,
            },
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'À faire',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return AppCard(
              onTap: () {},
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (task['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      task['icon'] as IconData,
                      color: task['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task['title'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (task['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      '${task['count']}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: task['color'] as Color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

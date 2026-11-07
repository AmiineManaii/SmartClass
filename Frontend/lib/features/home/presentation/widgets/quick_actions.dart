import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickActions extends StatelessWidget {
  final String role;

  const QuickActions({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final actions = role == 'teacher'
        ? [
            QuickAction(
              icon: Icons.add_circle_outline_rounded,
              label: 'Créer un cours',
              color: colorScheme.primary,
              onTap: () => context.go('/courses?action=create'),
            ),
            QuickAction(
              icon: Icons.quiz_outlined,
              label: 'Créer un examen',
              color: colorScheme.secondary,
              onTap: () => context.go('/exams?action=create'),
            ),
            QuickAction(
              icon: Icons.videocam_rounded,
              label: 'Nouvelle session',
              color: colorScheme.tertiary,
              onTap: () => context.go('/videoconference?action=create'),
            ),
            QuickAction(
              icon: Icons.group_add_rounded,
              label: 'Gérer groupes',
              color: Colors.orange,
              onTap: () => context.go('/groups'),
            ),
          ]
        : [
            QuickAction(
              icon: Icons.menu_book_rounded,
              label: 'Mes cours',
              color: colorScheme.primary,
              onTap: () => context.go('/courses'),
            ),
            QuickAction(
              icon: Icons.quiz_outlined,
              label: 'Examens',
              color: colorScheme.secondary,
              onTap: () => context.go('/exams'),
            ),
            QuickAction(
              icon: Icons.videocam_rounded,
              label: 'Replays',
              color: colorScheme.tertiary,
              onTap: () => context.go('/videoconference'),
            ),
            QuickAction(
              icon: Icons.group_rounded,
              label: 'Groupes',
              color: Colors.orange,
              onTap: () => context.go('/groups'),
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) => actions[index],
        ),
      ],
    );
  }
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

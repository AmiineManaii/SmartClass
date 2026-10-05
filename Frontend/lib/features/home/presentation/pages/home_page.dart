import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../app/app_providers.dart';
import '../widgets/student_dashboard_view.dart';
import '../widgets/teacher_dashboard_view.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final role = user?.role ?? 'student';

    if (role == 'teacher') {
      return const TeacherDashboardView();
    }

    if (role == 'student' || role.isEmpty) {
      return const StudentDashboardView();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${context.tr('home')} • ${_getRoleDisplayName(role)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WelcomeSection(user: user),
                    const SizedBox(height: 24),
                    _QuickActions(role: role),
                    const SizedBox(height: 24),
                    _UpcomingSessions(),
                    const SizedBox(height: 24),
                    _RecentCourses(),
                    const SizedBox(height: 24),
                    _PendingTasks(role: role),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'teacher':
        return 'Enseignant';
      case 'admin':
        return 'Administrateur';
      default:
        return 'Étudiant';
    }
  }
}

class _WelcomeSection extends StatelessWidget {
  final AuthState? user;
  
  const _WelcomeSection({this.user});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = user?.displayName ?? 'Utilisateur';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $name',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prêt à apprendre quelque chose de nouveau aujourd\'hui ?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.school_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final String role;
  
  const _QuickActions({required this.role});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final actions = role == 'teacher'
        ? [
            _QuickAction(
              icon: Icons.add_circle_outline_rounded,
              label: 'Créer un cours',
              color: colorScheme.primary,
              onTap: () => context.go('/courses?action=create'),
            ),
            _QuickAction(
              icon: Icons.quiz_outlined,
              label: 'Créer un examen',
              color: colorScheme.secondary,
              onTap: () => context.go('/exams?action=create'),
            ),
            _QuickAction(
              icon: Icons.videocam_rounded,
              label: 'Nouvelle session',
              color: colorScheme.tertiary,
              onTap: () => context.go('/videoconference?action=create'),
            ),
            _QuickAction(
              icon: Icons.group_add_rounded,
              label: 'Gérer groupes',
              color: Colors.orange,
              onTap: () => context.go('/groups'),
            ),
          ]
        : [
            _QuickAction(
              icon: Icons.menu_book_rounded,
              label: 'Mes cours',
              color: colorScheme.primary,
              onTap: () => context.go('/courses'),
            ),
            _QuickAction(
              icon: Icons.quiz_outlined,
              label: 'Examens',
              color: colorScheme.secondary,
              onTap: () => context.go('/exams'),
            ),
            _QuickAction(
              icon: Icons.videocam_rounded,
              label: 'Replays',
              color: colorScheme.tertiary,
              onTap: () => context.go('/videoconference'),
            ),
            _QuickAction(
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
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  const _QuickAction({
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

class _UpcomingSessions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final sessions = [
      {
        'title': 'Introduction à la programmation',
        'time': '14:00 - 15:30',
        'teacher': 'Prof. Martin',
        'isLive': true,
      },
      {
        'title': 'Algèbre linéaire - Chapitre 3',
        'time': '16:00 - 17:30',
        'teacher': 'Prof. Dubois',
        'isLive': false,
      },
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sessions à venir',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () => context.go('/videoconference'),
              child: Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final session = sessions[index];
            return AppCard(
              onTap: () {},
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: session['isLive'] == true
                          ? colorScheme.error.withValues(alpha: 0.1)
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.videocam_rounded,
                      color: session['isLive'] == true
                          ? colorScheme.error
                          : colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session['title'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${session['time']} • ${session['teacher']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (session['isLive'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'EN DIRECT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.error,
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

class _RecentCourses extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final courses = [
      {'title': 'Programmation orientée objet', 'progress': 0.65, 'status': 'En cours'},
      {'title': 'Base de données relationnelles', 'progress': 0.30, 'status': 'En cours'},
      {'title': 'Algorithmique et structures de données', 'progress': 1.0, 'status': 'Terminé'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cours récents',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () => context.go('/courses'),
              child: Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final course = courses[index];
            final progress = course['progress'] as double;
            final isCompleted = progress >= 1.0;
            
            return AppCard(
              onTap: () {},
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? colorScheme.tertiary.withValues(alpha: 0.1)
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle_rounded : Icons.menu_book_rounded,
                      color: isCompleted
                          ? colorScheme.tertiary
                          : colorScheme.onPrimaryContainer,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['title'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isCompleted ? colorScheme.tertiary : colorScheme.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(progress * 100).round()}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? colorScheme.tertiary.withValues(alpha: 0.1)
                          : colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      course['status'] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isCompleted ? colorScheme.tertiary : colorScheme.primary,
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

class _PendingTasks extends StatelessWidget {
  final String role;
  
  const _PendingTasks({required this.role});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final tasks = role == 'teacher'
        ? [
            {'title': 'Corriger les examens du groupe A', 'count': 12, 'icon': Icons.assignment_turned_in_rounded, 'color': colorScheme.error},
            {'title': 'Valider les cours en attente', 'count': 3, 'icon': Icons.pending_actions_rounded, 'color': Colors.orange},
            {'title': 'Répondre aux questions étudiants', 'count': 5, 'icon': Icons.question_answer_rounded, 'color': colorScheme.primary},
          ]
        : [
            {'title': 'Rendre le devoir de mathématiques', 'count': 1, 'icon': Icons.assignment_late_rounded, 'color': colorScheme.error},
            {'title': 'Réviser pour l\'examen de vendredi', 'count': 3, 'icon': Icons.schedule_rounded, 'color': Colors.orange},
            {'title': 'Participer au forum de discussion', 'count': 2, 'icon': Icons.forum_rounded, 'color': colorScheme.primary},
          ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'À faire',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
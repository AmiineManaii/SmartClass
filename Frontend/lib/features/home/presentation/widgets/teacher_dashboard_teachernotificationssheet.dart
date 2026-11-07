part of '../widgets/teacher_dashboard_view.dart';
class _TeacherNotificationsSheet extends StatelessWidget {
  final TeacherDashboardData? data;

  const _TeacherNotificationsSheet({this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications & Activités',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Flux d\'actualités et alertes pédagogiques',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.showSuccessToast(
                          'Toutes les notifications sont marquées comme lues');
                    },
                    child: const Text('Tout lire'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (data?.nextSlot != null) ...[
                    _NotificationItem(
                      icon: Icons.alarm_rounded,
                      iconBg: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFEF4444),
                      title: 'Séance imminente',
                      body:
                          '${data!.nextSlot!.title} avec ${data!.nextSlot!.className} commence ${data!.nextSlot!.dayLabel} à ${data!.nextSlot!.start}.',
                      time: 'À venir',
                      actionLabel: 'Rejoindre',
                      onAction: () {
                        Navigator.pop(context);
                        context.push('/videoconference');
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  _NotificationItem(
                    icon: Icons.people_alt_rounded,
                    iconBg: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF2563EB),
                    title: '${data?.classes.length ?? 0} Classes actives',
                    body:
                        'Vos ${data?.totalStudents ?? 0} étudiants sont synchronisés avec la base académique institutionnelle.',
                    time: 'Aujourd\'hui',
                    actionLabel: 'Gérer',
                    onAction: () {
                      Navigator.pop(context);
                      context.push('/groups');
                    },
                  ),
                  const SizedBox(height: 12),
                  _NotificationItem(
                    icon: Icons.auto_awesome_rounded,
                    iconBg: const Color(0xFFEDE9FE),
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Générateur de cours IA prêt',
                    body:
                        'Générez des plans détaillés, QCM interactifs et fiches d\'exercices en quelques secondes.',
                    time: 'Nouveau',
                    actionLabel: 'Générer',
                    onAction: () {
                      Navigator.pop(context);
                      context.push('/courses/ai-create');
                    },
                  ),
                  const SizedBox(height: 12),
                  _NotificationItem(
                    icon: Icons.assignment_turned_in_rounded,
                    iconBg: const Color(0xFFD1FAE5),
                    iconColor: const Color(0xFF059669),
                    title: 'Examens & Évaluations',
                    body:
                        'Configurez vos examens surveillés et vos barèmes de correction automatisée.',
                    time: 'Rappel',
                    actionLabel: 'Ouvrir',
                    onAction: () {
                      Navigator.pop(context);
                      context.push('/exams');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


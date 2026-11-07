part of '../widgets/teacher_dashboard_view.dart';
class _QuickToolsGrid extends StatelessWidget {
  final int classesCount;
  final VoidCallback onNewVirtualClass;
  final VoidCallback onOpenCalendar;

  const _QuickToolsGrid({
    required this.classesCount,
    required this.onNewVirtualClass,
    required this.onOpenCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tools = [
      _QuickToolItem(
        icon: Icons.videocam_rounded,
        title: 'Directs & Réunions',
        subtitle: 'LiveKit HD • Émargement',
        gradientColors: const [Color(0xFFE11D48), Color(0xFFBE123C)],
        badgeText: 'LIVE',
        badgeColor: const Color(0xFFEF4444),
        onTap: () => context.push('/videoconference'),
      ),
      _QuickToolItem(
        icon: Icons.auto_awesome_rounded,
        title: 'Créateur IA',
        subtitle: 'Cours, quiz & fiches',
        gradientColors: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        badgeText: 'IA +',
        badgeColor: const Color(0xFF8B5CF6),
        onTap: () => context.push('/courses/ai-create'),
      ),
      _QuickToolItem(
        icon: Icons.assignment_turned_in_rounded,
        title: 'Examens & Notes',
        subtitle: 'Corrections & barèmes',
        gradientColors: const [Color(0xFF059669), Color(0xFF047857)],
        badgeText: null,
        badgeColor: null,
        onTap: () => context.push('/exams'),
      ),
      _QuickToolItem(
        icon: Icons.calendar_month_rounded,
        title: 'Planning & Séances',
        subtitle: 'Emploi du temps & agenda',
        gradientColors: const [Color(0xFFD97706), Color(0xFFB45309)],
        badgeText: null,
        badgeColor: null,
        onTap: onOpenCalendar,
      ),
      _QuickToolItem(
        icon: Icons.school_rounded,
        title: 'Mes Classes',
        subtitle: '$classesCount classes actives',
        gradientColors: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        badgeText: null,
        badgeColor: null,
        onTap: () => context.push('/groups'),
      ),
      _QuickToolItem(
        icon: Icons.add_circle_outline_rounded,
        title: '+ Classe Virtuelle',
        subtitle: 'Créer un nouvel espace',
        gradientColors: const [Color(0xFF4338CA), Color(0xFF312E81)],
        badgeText: 'NOUVEAU',
        badgeColor: const Color(0xFF6366F1),
        onTap: onNewVirtualClass,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Outils & Services Pédagogiques',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(9999),
                      border:
                          Border.all(color: const Color(0xFFC7D2FE), width: 0.8),
                    ),
                    child: const Text(
                      'Web & Mobile',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF4338CA),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 480;
            final crossAxisCount = isSmall ? 2 : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 80,
              ),
              itemCount: tools.length,
              itemBuilder: (context, index) {
                final tool = tools[index];
                return _ToolCard(tool: tool);
              },
            );
          },
        ),
      ],
    );
  }
}


part of '../pages/class_detail_page.dart';
class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic>? group;
  final int memberCount;
  final int teacherCount;
  final int capacity;
  final String className;

  const _OverviewTab({
    required this.group,
    required this.memberCount,
    required this.teacherCount,
    required this.capacity,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Grid
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.groups_rounded,
                  iconColor: colorScheme.primary,
                  value: '$memberCount',
                  label: 'Étudiants',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  icon: Icons.school_rounded,
                  iconColor: colorScheme.secondary,
                  value: '$teacherCount',
                  label: 'Professeurs',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  icon: Icons.event_seat_rounded,
                  iconColor: colorScheme.tertiary,
                  value: '$capacity',
                  label: 'Places max',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AI Pedagogical Diagnostic Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.35),
                  colorScheme.surfaceContainerLow,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.15),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Diagnostic Pédagogique SmartClass',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'La promotion $className maintient une assiduité constante. Aucun décrochage académique détecté sur le tronc commun. Recommandation : planifier les sessions de révision IA avant les examens partiels.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _FeatureBadge(
                      icon: Icons.check_circle_outline_rounded,
                      text: 'Taux de présence : 92%',
                      color: colorScheme.tertiary,
                    ),
                    _FeatureBadge(
                      icon: Icons.trending_up_rounded,
                      text: 'Progression active',
                      color: colorScheme.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Administrative Details
          Text(
            'Informations administratives',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Column(
              children: [
                _AdminRow(
                  icon: Icons.business_outlined,
                  label: 'Département',
                  value: (group?['department'] as String?)?.isNotEmpty == true
                      ? group!['department'] as String
                      : 'Non spécifié',
                ),
                const Divider(height: 16),
                _AdminRow(
                  icon: Icons.grade_outlined,
                  label: 'Cycle d\'études',
                  value: group?['level'] as String? ?? 'Master',
                ),
                const Divider(height: 16),
                _AdminRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Année universitaire',
                  value: group?['academicYear'] as String? ?? '2026–2027',
                ),
                const Divider(height: 16),
                _AdminRow(
                  icon: Icons.forum_outlined,
                  label: 'Forum de promotion',
                  value: group?['forumEnabled'] == false
                      ? 'Désactivé'
                      : 'Actif & Surveillé',
                ),
                const Divider(height: 16),
                _AdminRow(
                  icon: Icons.sync_outlined,
                  label: 'Synchronisation ENT',
                  value: group?['entSyncEnabled'] == false
                      ? 'Manuelle'
                      : 'Automatique (quotidienne)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/providers/admin_providers.dart';
import '../widgets/web_admin_scaffold.dart';

typedef WebAdminDashboardView = WebAdminDashboardPage;

class WebAdminDashboardPage extends ConsumerWidget {
  const WebAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(adminOverviewProvider);
    final overview = overviewAsync.valueOrNull;

    final stats = overview?.stats;
    String findStat(String id, String fallback) {
      if (stats == null) return fallback;
      try {
        return stats.firstWhere((s) => s.id == id).value;
      } catch (_) {
        return fallback;
      }
    }

    final totalStudents = findStat('students', '1250');
    final totalTeachers = findStat('teachers', '48');
    final totalGroups = findStat('classes', '18');
    final pendingFrauds = findStat('frauds', '3');

    return WebAdminScaffold(
      activePath: 'tableau-de-bord',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // 1. TOP HEADER & CONTEXT
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle,
                                    color: AppTheme.primary, size: 7),
                                SizedBox(width: 6),
                                Text(
                                  'SUPERVISION ACADÉMIQUE',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            '•  Session Hiver-Printemps',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tableau de Bord Administrateur',
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Vue d\'ensemble et supervision de l\'établissement académique • Année 2024-2025',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Top Action Buttons
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(adminOverviewProvider),
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Actualiser les données'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.onSurface,
                        backgroundColor: AppTheme.surfaceContainerLowest,
                        side: BorderSide(
                          color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.showInfoToast(
                          'Génération du rapport d\'audit PDF en cours...',
                        );
                      },
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Exporter le rapport'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==========================================
            // 2. KEY METRICS ROW (4 COLUMNS GRID)
            // ==========================================
            Row(
              children: [
                // Card 1: Effectif Total
                Expanded(
                  child: _buildMetricCard(
                    title: 'EFFECTIF TOTAL',
                    value: totalStudents,
                    icon: Icons.school_rounded,
                    iconColor: AppTheme.primary,
                    iconBg: AppTheme.surfaceContainer,
                    footerWidget: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up_rounded,
                                color: AppTheme.success, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '+8.4%',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        CustomPaint(
                          size: const Size(40, 16),
                          painter: _SparklinePainter(color: AppTheme.success),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),

                // Card 2: Corps Enseignant
                Expanded(
                  child: _buildMetricCard(
                    title: 'CORPS ENSEIGNANT',
                    value: totalTeachers,
                    icon: Icons.assignment_ind_rounded,
                    iconColor: AppTheme.secondary,
                    iconBg: AppTheme.secondaryFixed.withValues(alpha: 0.4),
                    footerWidget: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Enseignants actifs',
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryFixed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '100% assignés',
                            style: TextStyle(
                              color: AppTheme.onPrimaryFixed,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),

                // Card 3: Groupes Pédagogiques
                Expanded(
                  child: _buildMetricCard(
                    title: 'GROUPES PÉDAGOGIQUES',
                    value: totalGroups,
                    icon: Icons.hub_rounded,
                    iconColor: AppTheme.secondary,
                    iconBg: AppTheme.surfaceContainer,
                    footerWidget: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Classes gérées',
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryFixed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Actif',
                            style: TextStyle(
                              color: AppTheme.onSecondaryFixed,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),

                // Card 4: Intégrité & Fraude
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F0), // Soft Coral Alert Card
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.15),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'INTÉGRITÉ & FRAUDE',
                                style: TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: AppTheme.error,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              pendingFrauds,
                              style: const TextStyle(
                                color: AppTheme.error,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'En attente',
                              style: TextStyle(
                                color: AppTheme.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Action requise sous 24h',
                              style: TextStyle(
                                color: AppTheme.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            InkWell(
                              onTap: () => context.go('/admin/frauds'),
                              child: const Text(
                                'Traiter >',
                                style: TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==========================================
            // 3. MAIN DUAL-COLUMN SECTION (60% / 40%)
            // ==========================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Derniers incidents de fraude signalés
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A1D2338),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header & Tabs
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Derniers incidents de fraude signalés',
                                  style: TextStyle(
                                    color: AppTheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Surveillance biométrique et comportementale SmartClass IA',
                                  style: TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTabPill('Tous', false),
                                  _buildTabPill('Non traités (3)', true),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Incidents List / Table
                        _buildIncidentRow(
                          initials: 'SM',
                          avatarColor: Colors.blue.shade100,
                          avatarTextColor: Colors.blue.shade900,
                          name: 'Salma M.',
                          code: '#ETU-8921 • L3 Info',
                          exam: 'QCM Mathématiques',
                          examPeriod: 'Semestre 6',
                          severity: 'Critique',
                          severityColor: AppTheme.error,
                          diagnostic: 'Perte focus x5, Copier-coller',
                          actionLabel: 'Sanctionner',
                          onAction: () => context.go('/admin/frauds'),
                        ),
                        const Divider(height: 22, color: AppTheme.surfaceContainer),

                        _buildIncidentRow(
                          initials: 'YB',
                          avatarColor: Colors.purple.shade100,
                          avatarTextColor: Colors.purple.shade900,
                          name: 'Yassine B.',
                          code: '#ETU-4102 • M1 Info',
                          exam: 'Algorithmique Avancée',
                          examPeriod: 'Théorie des Graphes',
                          severity: 'Moyen',
                          severityColor: Colors.amber.shade800,
                          diagnostic: 'Double écran & Flux IP',
                          actionLabel: 'Contrôler',
                          onAction: () => context.go('/admin/frauds'),
                        ),
                        const Divider(height: 22, color: AppTheme.surfaceContainer),

                        _buildIncidentRow(
                          initials: 'KT',
                          avatarColor: Colors.grey.shade200,
                          avatarTextColor: Colors.grey.shade800,
                          name: 'Karim T.',
                          code: '#ETU-3329 • L3 Info',
                          exam: 'Bases de Données',
                          examPeriod: 'Architecture NoSQL',
                          severity: 'Classé sans suite',
                          severityColor: AppTheme.outline,
                          diagnostic: 'Coupure Wi-Fi justifiée',
                          actionLabel: 'Dossier',
                          onAction: () => context.go('/admin/frauds'),
                        ),

                        const SizedBox(height: 18),

                        // Footer CTA
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Intégrité académique certifiée par consensus IA',
                              style: TextStyle(
                                color: AppTheme.outline,
                                fontSize: 11,
                              ),
                            ),
                            InkWell(
                              onTap: () => context.go('/admin/frauds'),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Voir tous les rapports d\'intégrité (15)',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded,
                                      color: AppTheme.primary, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Right Column: Activité récente du système & Plannings
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A1D2338),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Activité récente du système',
                                  style: TextStyle(
                                    color: AppTheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Sessions & plannings du jour',
                                  style: TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Aujourd\'hui',
                                style: TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Timeline Items
                        _buildTimelineItem(
                          time: '08:00 — 10:00',
                          title: 'CM Développement Mobile & Cross-Platform',
                          subtitle: 'Salle 102 • Prof. Amine M. (34/35 présents)',
                          statusLabel: 'Appel validé',
                          statusColor: AppTheme.success,
                          statusBg: AppTheme.tertiaryFixed.withValues(alpha: 0.3),
                          isCurrent: false,
                        ),
                        const SizedBox(height: 14),

                        _buildTimelineItem(
                          time: '10:15 — 12:15',
                          title: 'TP Bases de Données Réparties',
                          subtitle: 'Salle 204 • Dr. Sarah Benali',
                          statusLabel: 'En cours',
                          statusColor: AppTheme.secondary,
                          statusBg: AppTheme.secondaryFixed.withValues(alpha: 0.5),
                          isCurrent: true,
                        ),
                        const SizedBox(height: 14),

                        _buildTimelineItem(
                          time: '13:45 — 15:45',
                          title: 'TD Architecture Réseaux & Sécurité',
                          subtitle: 'Amphi B • Prof. L. Valette',
                          statusLabel: 'À venir',
                          statusColor: AppTheme.outline,
                          statusBg: AppTheme.surfaceContainerLow,
                          isCurrent: false,
                        ),

                        const SizedBox(height: 20),

                        // IA Telemetry Health Box (Stitch Design)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle,
                                      color: AppTheme.success, size: 9),
                                  SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Surveillance IA SmartClass',
                                        style: TextStyle(
                                          color: AppTheme.onSurface,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Moteur télémétrique opérationnel',
                                        style: TextStyle(
                                          color: AppTheme.onSurfaceVariant,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                '42ms Latence',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==========================================
            // 4. QUICK ACTIONS RIBBON (BOTTOM)
            // ==========================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt_rounded,
                              color: AppTheme.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Actions rapides & Opérations en masse',
                            style: TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Raccourcis administratifs certifiés',
                        style: TextStyle(
                          color: AppTheme.outline,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/admin/classes/new'),
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              size: 18),
                          label: const Text('Créer une nouvelle classe'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryContainer,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.showSuccessToast('Import CSV activé.');
                          },
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Importer des comptes CSV'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.onSurface,
                            side: const BorderSide(
                              color: AppTheme.surfaceContainerHighest,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/admin/planning'),
                          icon:
                              const Icon(Icons.calendar_month_rounded, size: 18),
                          label: const Text('Générer plannings auto'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.onSurface,
                            side: const BorderSide(
                              color: AppTheme.surfaceContainerHighest,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.showInfoToast('Audit de sécurité initialisé.');
                          },
                          icon: const Icon(Icons.shield_outlined,
                              color: AppTheme.error, size: 18),
                          label: const Text(
                            'Déclencher audit sécurité',
                            style: TextStyle(color: AppTheme.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppTheme.error.withValues(alpha: 0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Widget footerWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1D2338),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          footerWidget,
        ],
      ),
    );
  }

  Widget _buildTabPill(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isSelected
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildIncidentRow({
    required String initials,
    required Color avatarColor,
    required Color avatarTextColor,
    required String name,
    required String code,
    required String exam,
    required String examPeriod,
    required String severity,
    required Color severityColor,
    required String diagnostic,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: avatarColor,
          child: Text(
            initials,
            style: TextStyle(
              color: avatarTextColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                code,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exam,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                examPeriod,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  severity,
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                diagnostic,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onAction,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String title,
    required String subtitle,
    required String statusLabel,
    required Color statusColor,
    required Color statusBg,
    required bool isCurrent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent ? AppTheme.secondary : AppTheme.outlineVariant,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;

  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..lineTo(size.width * 0.25, size.height * 0.55)
      ..lineTo(size.width * 0.5, size.height * 0.65)
      ..lineTo(size.width * 0.75, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.1);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/web_admin_scaffold.dart';

typedef WebAdminReportsView = WebAdminReportsPage;

class WebAdminReportsPage extends ConsumerStatefulWidget {
  const WebAdminReportsPage({super.key});

  @override
  ConsumerState<WebAdminReportsPage> createState() =>
      _WebAdminReportsPageState();
}

class _WebAdminReportsPageState extends ConsumerState<WebAdminReportsPage> {
  String _selectedDossierId = 'FR-402';
  final _decisionController = TextEditingController();

  final List<Map<String, dynamic>> _alerts = [
    {
      'id': 'FR-402',
      'name': 'Salma Mansouri',
      'code': '#ETU-8921',
      'exam': 'Algorithmique S1',
      'promo': 'Informatique 3A',
      'time': '12 Oct 2026, 10:45',
      'type': 'Perte de focus (x5)',
      'desc': 'Plein écran quitté, double écran suspect',
      'icon': Icons.tab_unselected_rounded,
      'riskScore': 94,
      'riskLabel': 'Critique',
      'riskColor': AppTheme.error,
      'room': 'Salle Exam-Alpha-04',
      'angle': '-48°',
      'confidence': '98.2%',
    },
    {
      'id': 'FR-401',
      'name': 'Yassine Berrada',
      'code': '#ETU-4102',
      'exam': 'Théorie des Graphes',
      'promo': 'Maths & Info 2A',
      'time': '12 Oct 2026, 09:12',
      'type': 'Multi-visages',
      'desc': '2 personnes face à la webcam',
      'icon': Icons.people_outline_rounded,
      'riskScore': 78,
      'riskLabel': 'Élevé',
      'riskColor': Color(0xFF6B21A8),
      'room': 'Salle Exam-Beta-02',
      'angle': '0°',
      'confidence': '95.4%',
    },
    {
      'id': 'FR-398',
      'name': 'Karim Tazi',
      'code': '#ETU-3329',
      'exam': 'Architecture NoSQL',
      'promo': 'Génie Logiciel 3A',
      'time': '11 Oct 2026, 16:30',
      'type': 'Rupture de flux',
      'desc': 'Reconnexion sur IP externe',
      'icon': Icons.wifi_off_rounded,
      'riskScore': 45,
      'riskLabel': 'Modéré',
      'riskColor': Color(0xFF1E40AF),
      'room': 'Amphi C',
      'angle': '0°',
      'confidence': '88.0%',
    },
    {
      'id': 'FR-395',
      'name': 'Leila Amrani',
      'code': '#ETU-6743',
      'exam': 'Probabilités & Stats',
      'promo': 'Master M1 Data',
      'time': '10 Oct 2026, 14:15',
      'type': 'Presse-papiers',
      'desc': 'Copier-coller massif via invite IA',
      'icon': Icons.content_paste_rounded,
      'riskScore': 82,
      'riskLabel': 'Élevé',
      'riskColor': Color(0xFF6B21A8),
      'room': 'Salle 204',
      'angle': '0°',
      'confidence': '97.1%',
    },
  ];

  @override
  void dispose() {
    _decisionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dossier = _alerts.firstWhere(
      (a) => a['id'] == _selectedDossierId,
      orElse: () => _alerts.first,
    );

    return WebAdminScaffold(
      activePath: 'rapports-de-fraude',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // 1. BREADCRUMBS & TOP HEADER
            // ==========================================
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 12,
              spacing: 12,
              children: [
                const Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'SUPERVISION ACADÉMIQUE',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text('  /  ',
                        style: TextStyle(color: AppTheme.outlineVariant)),
                    Text(
                      'SÉCURITÉ & EXAMENS',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('  /  ',
                        style: TextStyle(color: AppTheme.outlineVariant)),
                    Text(
                      'AUDIT D\'INTÉGRITÉ',
                      style: TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.file_download_outlined, size: 17),
                      label: const Text('Exporter l\'audit (PDF/CSV)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(
                            color: AppTheme.surfaceContainerHighest),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.gavel_rounded, size: 17),
                      label: const Text('Session d\'arbitrage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryContainer,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              'Rapports de Fraude & Intégrité des Examens',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Supervision télémétrique anti-triche assistée par consensus IA, analyse biométrique faciale et journaux d\'infractions en temps réel.',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 2. 4 METRIC STATS ROW
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    statusDot: AppTheme.error,
                    title: 'Non traités',
                    badge: '3 critiques',
                    badgeBg: const Color(0xFFFFDAD6),
                    badgeColor: AppTheme.error,
                    value: '03',
                    subtitle: 'dossiers en attente d\'arbitrage',
                    footnote: '3 alertes rouges nécessitant clôture',
                    footnoteColor: AppTheme.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    statusDot: AppTheme.secondary,
                    title: 'En cours d\'examen',
                    badge: '2 en cours',
                    badgeBg: AppTheme.secondaryFixed,
                    badgeColor: AppTheme.secondary,
                    value: '02',
                    subtitle: 'auditions planifiées',
                    footnote: 'Commissions de discipline convoquées',
                    footnoteColor: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    statusDot: AppTheme.success,
                    title: 'Clôturés',
                    badge: '12 archivés',
                    badgeBg: AppTheme.tertiaryFixed.withValues(alpha: 0.35),
                    badgeColor: AppTheme.success,
                    value: '12',
                    subtitle: 'sanctions / classements',
                    footnote: '100% avec horodatage scellé',
                    footnoteColor: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            const Text(
                              'Taux d\'intégrité',
                              style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.tertiaryFixed
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '↗ +0.4%',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '98.8%',
                              style: TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            CustomPaint(
                              size: const Size(60, 20),
                              painter: _SparklinePainter(color: AppTheme.success),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sur 2 450 épreuves passées ce trimestre',
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 3. FILTER BAR
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Container(
                  width: 320,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded,
                          size: 18, color: AppTheme.outline),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText:
                                'Rechercher des étudiants, classes, cours...',
                            hintStyle: TextStyle(
                                color: AppTheme.outline, fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDropdownBadge('Gravité : Tous niveaux'),
                _buildDropdownBadge('Type d\'incident : Tous'),
                _buildDropdownBadge('Période : Ce semestre (S1 2026)'),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.sync_rounded,
                      color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 4. MAIN SPLIT (TABLE + DOSSIER ARBITRAGE)
            // ==========================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Table: Alertes Actives (55%)
                Expanded(
                  flex: 55,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Ribbon
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 8,
                            spacing: 8,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  const Icon(Icons.shield_outlined,
                                      color: AppTheme.primary, size: 18),
                                  const Text(
                                    'Registre des Alertes Actives',
                                    style: TextStyle(
                                      color: AppTheme.onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFDAD6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '4 requêtes prioritaires',
                                      style: TextStyle(
                                        color: AppTheme.error,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle,
                                      color: AppTheme.tertiaryFixed, size: 7),
                                  SizedBox(width: 5),
                                  Text(
                                    'Vue synchronisée',
                                    style: TextStyle(
                                      color: AppTheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Columns Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: AppTheme.surfaceContainer),
                            ),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 26),
                              Expanded(
                                flex: 4,
                                child: Text('DOSSIER / ÉTUDIANT',
                                    style: TextStyle(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text('ÉPREUVE',
                                    style: TextStyle(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                flex: 5,
                                child: Text('TYPE D\'INFRACTION',
                                    style: TextStyle(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('INDICE DE RISQUE',
                                    style: TextStyle(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),

                        // Table Rows
                        ..._alerts.map((alert) {
                          final isSelected =
                              _selectedDossierId == alert['id'];

                          return InkWell(
                            onTap: () => setState(
                                () => _selectedDossierId = alert['id']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary.withValues(alpha: 0.05)
                                    : Colors.transparent,
                                border: const Border(
                                  bottom: BorderSide(
                                      color: AppTheme.surfaceContainer),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_box_rounded
                                        : Icons.check_box_outline_blank_rounded,
                                    size: 18,
                                    color: isSelected
                                        ? AppTheme.primaryContainer
                                        : AppTheme.outline,
                                  ),
                                  const SizedBox(width: 8),

                                  // Student
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert['name'],
                                          style: const TextStyle(
                                            color: AppTheme.onSurface,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Matr. ${alert['code']}',
                                          style: const TextStyle(
                                            color: AppTheme.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          '#${alert['id']}',
                                          style: const TextStyle(
                                            color: AppTheme.secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Exam
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert['exam'],
                                          style: const TextStyle(
                                            color: AppTheme.onSurface,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          alert['promo'],
                                          style: const TextStyle(
                                            color: AppTheme.onSurfaceVariant,
                                            fontSize: 10,
                                          ),
                                        ),
                                        Text(
                                          alert['time'],
                                          style: const TextStyle(
                                            color: AppTheme.outline,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Infraction
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(alert['icon'],
                                                size: 13,
                                                color: alert['riskColor']),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                alert['type'],
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: alert['riskColor'],
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          alert['desc'],
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppTheme.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Score
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (alert['riskColor'] as Color)
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            alert['riskLabel'],
                                            style: TextStyle(
                                              color: alert['riskColor'],
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${alert['riskScore']}/100',
                                            style: TextStyle(
                                              color: alert['riskColor'],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Right Panel: Dossier d'Arbitrage #FR-402 (45% - Stitch Design)
                Expanded(
                  flex: 45,
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
                          color: Color(0x0C1D2338),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Dossier Header
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDAD6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Non Traité • Critique',
                                style: TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Dossier #${dossier['id']}',
                                  style: const TextStyle(
                                    color: AppTheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.print_outlined,
                                      size: 18),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Student Profile & Anomaly Score
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primaryFixed,
                                child: Text(
                                  (dossier['name'] as String)
                                      .split(' ')
                                      .map((s) => s.isNotEmpty ? s[0] : '')
                                      .join(),
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dossier['name'],
                                      style: const TextStyle(
                                        color: AppTheme.onSurface,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${dossier['promo']} • ${dossier['room']}',
                                      style: const TextStyle(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Matricule : ${dossier['code']}',
                                      style: const TextStyle(
                                        color: AppTheme.outline,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'INDICE ANOMALIE IA',
                                    style: TextStyle(
                                      color: AppTheme.error,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '${dossier['riskScore']}',
                                        style: const TextStyle(
                                          color: AppTheme.error,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const Text(
                                        ' /100',
                                        style: TextStyle(
                                          color: AppTheme.outline,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Preuves biométriques & Captures (3 instantanés)
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 8,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_outlined,
                                    size: 16, color: AppTheme.primary),
                                SizedBox(width: 6),
                                Text(
                                  'Preuves biométriques & Captures',
                                  style: TextStyle(
                                    color: AppTheme.onSurface,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                'Télécharger l\'archive ZIP',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Two Proof Cards Side-by-side (Stitch Design)
                        Row(
                          children: [
                            // Proof 1: Webcam Head Turned
                            Expanded(
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 124),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.error.withValues(alpha: 0.6),
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.error,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Tête détournée (${dossier['angle']})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Center(
                                      child: Icon(Icons.face_retouching_off,
                                          color: Colors.white54, size: 28),
                                    ),
                                    Wrap(
                                      alignment:
                                          WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          'Confiance ${dossier['confidence']}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 9,
                                          ),
                                        ),
                                        const Text(
                                          'Instantané #1',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Proof 2: Browser Screen Capture
                            Expanded(
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 124),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.error.withValues(alpha: 0.6),
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.error,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Non Autorisé • Alt+Tab',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'chatgpt.com/c/68...\nRequête: "Résoudre algo tri..."',
                                      style: TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontSize: 9,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const Text(
                                      'Page d\'IA conversationnelle ouverte',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Chronologie Télémétrique de la Session
                        const Text(
                          'Chronologie Télémétrique de la Session',
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTimelineRow('10:00:00',
                            'Début de l\'épreuve (Biométrie validée 99.8%)', AppTheme.success),
                        _buildTimelineRow('10:32:15',
                            'Avertissement acoustique (Bruit suspect 28 dB)', Colors.amber.shade800),
                        _buildTimelineRow('10:45:12',
                            'Décrochage visuel majeur (>14 secondes)', AppTheme.error),
                        _buildTimelineRow('10:45:18',
                            'Infraction critique confirmée (Alt+Tab vers IA)', AppTheme.error),

                        const SizedBox(height: 16),

                        // Formulaire d'Arbitrage & Décision
                        const Text(
                          'Arbitrage & Décision Disciplinaire',
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _decisionController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText:
                                'Saisir la notification de décision transmise au jury d\'examen et à l\'étudiant...',
                            hintStyle: const TextStyle(
                                color: AppTheme.outline, fontSize: 11),
                            filled: true,
                            fillColor: AppTheme.surfaceContainerLow,
                            contentPadding: const EdgeInsets.all(10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Sanction Button
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppTheme.error,
                                content: Text(
                                  'Sanction appliquée : Note 0/20 & Épreuve annulée.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.cancel_outlined,
                              color: Colors.white, size: 16),
                          label: const Text(
                            'Sanctionner & Annuler l\'épreuve (Note 0/20)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Commission disciplinaire',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Classer sans suite',
                                  style: TextStyle(
                                    color: AppTheme.outline,
                                    fontSize: 11,
                                  ),
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

            const SizedBox(height: 24),

            // ==========================================
            // 5. FOOTER COMPLIANCE BANNER
            // ==========================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.lock_person_outlined,
                            color: AppTheme.success, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Conformité RGPD & Intégrité Académique',
                                style: TextStyle(
                                  color: AppTheme.onSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Données biométriques chiffrées de bout en bout • Journaux scellés par certificat SHA-256 inviolable.',
                                style: TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Audit Hash: 9f82...da31',
                          style: TextStyle(
                            color: AppTheme.outline,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Délai de recours : 48h ouvrées',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 11,
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
    required Color statusDot,
    required String title,
    required String badge,
    required Color badgeBg,
    required Color badgeColor,
    required String value,
    required String subtitle,
    required String footnote,
    required Color footnoteColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: statusDot, size: 7),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            footnote,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: footnoteColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceContainerHighest),
      ),
      child: Row(
        children: [
          Text(text,
              style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_drop_down,
              size: 18, color: AppTheme.outline),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String time, String event, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.circle, color: dotColor, size: 7),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              event,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
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
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.25, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height * 0.6)
      ..lineTo(size.width * 0.75, size.height * 0.25)
      ..lineTo(size.width, size.height * 0.1);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

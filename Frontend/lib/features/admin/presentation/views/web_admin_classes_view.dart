import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/web_admin_scaffold.dart';

typedef WebAdminClassesView = WebAdminClassesPage;

class WebAdminClassesPage extends ConsumerStatefulWidget {
  const WebAdminClassesPage({super.key});

  @override
  ConsumerState<WebAdminClassesPage> createState() =>
      _WebAdminClassesPageState();
}

class _WebAdminClassesPageState extends ConsumerState<WebAdminClassesPage> {
  final Set<String> _selectedClassIds = {};

  final List<Map<String, dynamic>> _classes = [
    {
      'id': '1',
      'codeBadge': '3A',
      'name': 'Informatique 3A',
      'code': '#INFO-L3A',
      'level': 'Licence 3',
      'specialty': 'Génie Logiciel',
      'current': 35,
      'capacity': 40,
      'teachersCount': 4,
      'referent': 'Prof. Amine M., Dr. Sarah B.',
      'room': 'Amphi B & Salle 102',
      'campus': 'Campus Centre',
      'status': 'Active',
    },
    {
      'id': '2',
      'codeBadge': '1B',
      'name': 'Mathématiques 1B',
      'code': '#MATH-L1B',
      'level': 'Licence 1',
      'specialty': 'Tronc Commun',
      'current': 42,
      'capacity': 45,
      'teachersCount': 2,
      'referent': 'Dr. K. Idrissi, Mme N. Cherkaoui',
      'room': 'Amphi A',
      'campus': 'Bâtiment Descartes',
      'status': 'Active',
    },
    {
      'id': '3',
      'codeBadge': 'M1',
      'name': 'Systèmes & Réseaux M1',
      'code': '#SR-M1',
      'level': 'Master 1',
      'specialty': 'Cybersécurité',
      'current': 28,
      'capacity': 30,
      'teachersCount': 3,
      'referent': 'Prof. Amine M., M. Tariq F.',
      'room': 'Labo Réseau 204',
      'campus': 'Aile Numérique',
      'status': 'Active',
    },
    {
      'id': '4',
      'codeBadge': 'M2',
      'name': 'Data Science & IA M2',
      'code': '#DSIA-M2',
      'level': 'Master 2',
      'specialty': 'Intelligence Artificielle',
      'current': 24,
      'capacity': 25,
      'teachersCount': 5,
      'referent': 'Dr. Sarah B., Prof. T. Alami',
      'room': 'Salle 305 IA',
      'campus': 'Centre de Recherche',
      'status': 'Active',
    },
    {
      'id': '5',
      'codeBadge': '2A',
      'name': 'Physique Fondamentale 2A',
      'code': '#PHYS-L2A',
      'level': 'Licence 2',
      'specialty': 'Sciences Exactes',
      'current': 38,
      'capacity': 40,
      'teachersCount': 3,
      'referent': 'Prof. R. Mansouri, etc.',
      'room': 'Salle 110',
      'campus': 'Pavillon Curie',
      'status': 'Active',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return WebAdminScaffold(
      activePath: 'classes',
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
              runSpacing: 8,
              spacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_outlined,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    const Text(
                      'SUPERVISION ACADÉMIQUE',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Text('  /  ',
                        style: TextStyle(color: AppTheme.outlineVariant)),
                    const Text(
                      'Année 2024-2025',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const Text('  /  ',
                        style: TextStyle(color: AppTheme.outlineVariant)),
                    const Text(
                      'Structure Pédagogique',
                      style: TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle,
                          color: AppTheme.tertiaryFixedDim, size: 7),
                      SizedBox(width: 6),
                      Text(
                        'Base académique synchronisée (14:32)',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              runSpacing: 16,
              spacing: 12,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion des Classes & Groupes',
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consultez, organisez et configurez les promotions, effectifs d\'étudiants et affectations d\'enseignants.',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        context.showSuccessToast('Import CSV de structure prêt.');
                      },
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text('Importer une structure (CSV)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        backgroundColor: AppTheme.surfaceContainerLowest,
                        side: const BorderSide(
                            color: AppTheme.surfaceContainerHighest),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/admin/classes/new'),
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          size: 18),
                      label: const Text('Créer une classe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryContainer,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 2. 3 METRIC CARDS
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'PROMOTIONS',
                    value: '18 Classes actives',
                    badge: '↗ 100%',
                    badgeColor: AppTheme.success,
                    badgeBg: AppTheme.tertiaryFixed.withValues(alpha: 0.25),
                    icon: Icons.groups_3_rounded,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _buildMetricCard(
                    title: 'INSCRIPTIONS',
                    value: '1,250 Étudiants',
                    badge: 'Taux: 94.2%',
                    badgeColor: AppTheme.primary,
                    badgeBg: AppTheme.primaryFixed,
                    icon: Icons.how_to_reg_rounded,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _buildMetricCard(
                    title: 'CORPS PROFESSORAL',
                    value: '48 Enseignants',
                    badge: 'Affectés',
                    badgeColor: AppTheme.secondary,
                    badgeBg: AppTheme.secondaryFixed,
                    icon: Icons.assignment_ind_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 3. FILTER TOOLBAR
            // ==========================================
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Container(
                  width: 300,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
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
                                'Filtrer par nom, code (#INFO, #MATH)...',
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
                _buildDropdownBadge('Niveau: Tous (Licence & Master)'),
                _buildDropdownBadge('Filière / Département: Toutes'),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.surfaceContainerHighest),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 15, color: AppTheme.outline),
                      SizedBox(width: 6),
                      Text('Année: 2024-2025',
                          style: TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      SizedBox(width: 6),
                      Icon(Icons.lock_outline_rounded,
                          size: 13, color: AppTheme.outline),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Exporter (Excel / CSV)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.onSurface,
                    side: const BorderSide(
                        color: AppTheme.surfaceContainerHighest),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Selection Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Icon(Icons.checklist_rounded,
                          color: AppTheme.secondary, size: 18),
                      Text(
                        '${_selectedClassIds.length} élément sélectionné',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '|  Sélectionnez des classes pour actions groupées',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildRibbonAction('Assigner une salle', () {}),
                      _buildRibbonAction('Notifier délégués', () {}),
                      _buildRibbonAction('Archiver', () {},
                          color: Colors.red.shade400),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // 4. CLASSES DATA TABLE
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 32),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'NOM DE LA CLASSE & CODE',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'NIVEAU & SPÉCIALITÉ',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'EFFECTIF ÉTUDIANTS',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'PROFESSEURS ASSIGNÉS',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'SALLE / RÉFÉRENT',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'STATUT',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Rows
                  ..._classes.map((c) {
                    final isSelected = _selectedClassIds.contains(c['id']);
                    final pct = (c['current'] as int) / (c['capacity'] as int);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.surfaceContainer),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Checkbox(
                              value: isSelected,
                              activeColor: AppTheme.primaryContainer,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedClassIds.add(c['id']);
                                  } else {
                                    _selectedClassIds.remove(c['id']);
                                  }
                                });
                              },
                            ),
                          ),

                          // Name & Code with Badge
                          Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    c['codeBadge'],
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['name'],
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.onSurface,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        c['code'],
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Level & Specialty
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryFixed,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c['level'],
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppTheme.onPrimaryFixed,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c['specialty'],
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Headcount Bar
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  alignment:
                                      WrapAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      '${c['current']} étudiants',
                                      style: const TextStyle(
                                        color: AppTheme.onSurface,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${c['current']} / ${c['capacity']}',
                                      style: const TextStyle(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor:
                                        AppTheme.surfaceContainerLow,
                                    valueColor: const AlwaysStoppedAnimation(
                                        AppTheme.secondary),
                                    minHeight: 5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Teachers
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      '${c['teachersCount']} profs',
                                      style: const TextStyle(
                                        color: AppTheme.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.tertiaryFixed
                                            .withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'RÉFÉRENT',
                                        style: TextStyle(
                                          color: AppTheme.success,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c['referent'],
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Room / Campus
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.meeting_room_outlined,
                                        size: 14, color: AppTheme.outline),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        c['room'],
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.onSurface,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  c['campus'],
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Status
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.tertiaryFixed
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle,
                                      color: AppTheme.success, size: 6),
                                  SizedBox(width: 4),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      color: AppTheme.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Pagination Footer
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text(
                          'Affichage de 1 à 5 sur 18 classes',
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPagePill('<', false),
                            _buildPagePill('1', true),
                            _buildPagePill('2', false),
                            _buildPagePill('3', false),
                            _buildPagePill('>', false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 5. BOTTOM COHERENCE BANNER (Stitch Design)
            // ==========================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.secondary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.tertiaryFixed,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_graph_rounded,
                      color: AppTheme.tertiary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Capacité globale & Cohérence pédagogique',
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '98% des groupes respectent les jauges d\'amphithéâtres. Le module anti-fraude et de présence biométrique SmartClass est actif sur l\'ensemble de ces 18 promotions.',
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: const Text(
                      'Rapport d\'optimisation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
    required String badge,
    required Color badgeColor,
    required Color badgeBg,
    required IconData icon,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryFixed.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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

  Widget _buildRibbonAction(String text, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color ?? AppTheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPagePill(String text, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}

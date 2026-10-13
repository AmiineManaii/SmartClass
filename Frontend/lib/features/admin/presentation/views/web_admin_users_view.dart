import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/web_admin_scaffold.dart';

typedef WebAdminUsersView = WebAdminUsersPage;

class WebAdminUsersPage extends ConsumerStatefulWidget {
  const WebAdminUsersPage({super.key});

  @override
  ConsumerState<WebAdminUsersPage> createState() => _WebAdminUsersPageState();
}

class _WebAdminUsersPageState extends ConsumerState<WebAdminUsersPage> {
  String _activeTab = 'students'; // 'all' | 'students' | 'teachers' | 'staff'
  final Set<String> _selectedUserIds = {'1', '2', '3'};
  String? _inspectedUserId = '1';

  final List<Map<String, dynamic>> _users = [
    {
      'id': '1',
      'name': 'Salma Mansouri',
      'code': '#ETU-8921',
      'email': 'salma.mansouri@smartclass.edu',
      'role': 'Étudiante (L3 Info)',
      'initials': 'SM',
      'avatarColor': Color(0xFFE8EDFF),
      'avatarTextColor': Color(0xFF122675),
      'status': 'active',
      'average': '16.8',
      'attendance': '98%',
      'tests': '14/14',
      'class': 'Informatique 3A',
      'specificRole': 'Déléguée adjointe',
      'year': '2024 - 2025',
      'twoFa': true,
      'ip': '196.200.14.88 (Campus)',
      'frauds': '0 signalement',
    },
    {
      'id': '2',
      'name': 'Prof. Amine Mezzour',
      'code': '#ENS-104',
      'email': 'amine.mezzour@smartclass.edu',
      'role': 'Enseignant Référent',
      'initials': 'AM',
      'avatarColor': Color(0xFFE5F9F3),
      'avatarTextColor': Color(0xFF004F3B),
      'status': 'active',
      'average': '—',
      'attendance': '100%',
      'tests': '48 cours',
      'class': 'Informatique L3 & M1',
      'specificRole': 'Coordinateur IA',
      'year': '2024 - 2025',
      'twoFa': true,
      'ip': '196.200.14.02 (Campus)',
      'frauds': 'Audit conforme',
    },
    {
      'id': '3',
      'name': 'Yassine Berrada',
      'code': '#ETU-4102',
      'email': 'yassine.b@smartclass.edu',
      'role': 'Étudiant (M1 Info)',
      'initials': 'YB',
      'avatarColor': Color(0xFFF3E8FF),
      'avatarTextColor': Color(0xFF581C87),
      'status': 'active',
      'average': '14.2',
      'attendance': '92%',
      'tests': '12/14',
      'class': 'Systèmes & Réseaux M1',
      'specificRole': 'Étudiant',
      'year': '2024 - 2025',
      'twoFa': false,
      'ip': '196.200.15.12',
      'frauds': '1 alerte en cours',
    },
    {
      'id': '4',
      'name': 'Dr. Sarah Benali',
      'code': '#ENS-208',
      'email': 'sarah.benali@smartclass.edu',
      'role': 'Enseignante',
      'initials': 'SB',
      'avatarColor': Color(0xFFE5F9F3),
      'avatarTextColor': Color(0xFF004F3B),
      'status': 'active',
      'average': '—',
      'attendance': '99%',
      'tests': '32 cours',
      'class': 'Bases de Données',
      'specificRole': 'Enseignante Chercheuse',
      'year': '2024 - 2025',
      'twoFa': true,
      'ip': '196.200.14.45',
      'frauds': '0 signalement',
    },
    {
      'id': '5',
      'name': 'Karim Tazi',
      'code': '#ETU-3329',
      'email': 'karim.tazi@smartclass.edu',
      'role': 'Étudiant (L3 Info)',
      'initials': 'KT',
      'avatarColor': Color(0xFFF1F5F9),
      'avatarTextColor': Color(0xFF334155),
      'status': 'inactive',
      'average': '11.5',
      'attendance': '84%',
      'tests': '9/14',
      'class': 'Informatique 3A',
      'specificRole': 'Étudiant',
      'year': '2024 - 2025',
      'twoFa': false,
      'ip': '196.200.16.89',
      'frauds': 'Classé sans suite',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final inspectedUser = _users.firstWhere(
      (u) => u['id'] == _inspectedUserId,
      orElse: () => _users.first,
    );

    return WebAdminScaffold(
      activePath: 'utilisateurs',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // 1. BREADCRUMB & HEADER
            // ==========================================
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SUPERVISION ACADÉMIQUE',
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded,
                            size: 14, color: AppTheme.outline),
                        const SizedBox(width: 6),
                        const Text(
                          'Annuaire & Droits d\'accès',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gestion des Utilisateurs',
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Consultez, attribuez des rôles, gérez les accès et supervisez l\'activité des étudiants et enseignants.',
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
                      onPressed: () {},
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text('Importer un annuaire'),
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
                      onPressed: () {},
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Ajouter un utilisateur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
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
            // 2. 4 METRIC CARDS
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'TOTAL UTILISATEURS',
                    value: '1,298',
                    badgeText: '+34 ce semestre',
                    badgeColor: AppTheme.success,
                    icon: Icons.groups_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    title: 'ÉTUDIANTS ACTIFS',
                    value: '1,250',
                    badgeText: 'Taux d\'activité 96.4%',
                    badgeColor: AppTheme.primary,
                    icon: Icons.school_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    title: 'CORPS PROFESSORAL',
                    value: '48',
                    badgeText: '100% assignés aux modules',
                    badgeColor: AppTheme.secondary,
                    icon: Icons.co_present_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    title: 'COMPTES À VÉRIFIER',
                    value: '4',
                    badgeText: 'Suspensions actives',
                    badgeColor: AppTheme.error,
                    icon: Icons.person_off_rounded,
                    isAlert: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 3. TABS & FILTER BAR
            // ==========================================
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              spacing: 12,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRoleFilterTab('Tous (1,298)', 'all'),
                    _buildRoleFilterTab('Étudiants (1,250)', 'students'),
                    _buildRoleFilterTab('Enseignants (48)', 'teachers'),
                    _buildRoleFilterTab('Administrateurs & Staff (12)', 'staff'),
                  ],
                ),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: AppTheme.tertiaryFixed, size: 8),
                    SizedBox(width: 6),
                    Text(
                      'Annuaire synchronisé avec LDAP Campus Central',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Secondary Filter Controls
            Row(
              children: [
                Expanded(
                  child: Container(
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
                              hintText: 'Filtrer par nom, email, matricule...',
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
                ),
                const SizedBox(width: 12),
                _buildDropdownBadge('Département: Informatique'),
                const SizedBox(width: 12),
                _buildDropdownBadge('Statut: Tous'),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Exporter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.onSurface,
                    side: const BorderSide(
                        color: AppTheme.surfaceContainerHighest),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Multi-Selection Action Ribbon (Stitch Design)
            if (_selectedUserIds.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_selectedUserIds.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'profils sélectionnés',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.lock_reset_rounded, size: 15),
                      label: const Text('Réinitialiser MDP'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.group_add_rounded, size: 15),
                      label: const Text('Assigner groupe'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.block_rounded,
                          color: AppTheme.error, size: 15),
                      label: const Text(
                        'Suspendre',
                        style: TextStyle(color: AppTheme.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ==========================================
            // 4. MAIN DUAL VIEW (TABLE + INSPECTOR DRAWER)
            // ==========================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table (65%)
                Expanded(
                  flex: 65,
                  child: Container(
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
                                  'UTILISATEUR & MATRICULE',
                                  style: TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Text(
                                  'EMAIL ACADÉMIQUE',
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
                                  'RÔLE & PROMOTION',
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
                        ..._users.map((user) {
                          final isSelected =
                              _selectedUserIds.contains(user['id']);
                          final isInspected = _inspectedUserId == user['id'];

                          return InkWell(
                            onTap: () =>
                                setState(() => _inspectedUserId = user['id']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isInspected
                                    ? AppTheme.primary.withValues(alpha: 0.05)
                                    : Colors.transparent,
                                border: const Border(
                                  bottom: BorderSide(
                                    color: AppTheme.surfaceContainer,
                                  ),
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
                                            _selectedUserIds.add(user['id']);
                                          } else {
                                            _selectedUserIds
                                                .remove(user['id']);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 17,
                                          backgroundColor:
                                              user['avatarColor'],
                                          child: Text(
                                            user['initials'],
                                            style: TextStyle(
                                              color: user['avatarTextColor'],
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['name'],
                                                style: const TextStyle(
                                                  color: AppTheme.onSurface,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                user['code'],
                                                style: const TextStyle(
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      user['email'],
                                      style: const TextStyle(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        user['role'],
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        // Pagination
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 8,
                            children: [
                              const Text(
                                'Affichage de 1 à 5 sur 1,298 utilisateurs',
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
                                  const Text('...',
                                      style: TextStyle(
                                          color: AppTheme.onSurfaceVariant)),
                                  _buildPagePill('260', false),
                                  _buildPagePill('>', false),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Right Inspector Drawer Panel (35% - Stitch Design)
                Expanded(
                  flex: 35,
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
                        // Drawer Header Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.tertiaryFixed
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.circle,
                                      color: AppTheme.success, size: 7),
                                  SizedBox(width: 5),
                                  Text(
                                    'Compte Actif',
                                    style: TextStyle(
                                      color: AppTheme.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () =>
                                  setState(() => _inspectedUserId = null),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // User Photo & Name
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor:
                                        inspectedUser['avatarColor'],
                                    child: Text(
                                      inspectedUser['initials'],
                                      style: TextStyle(
                                        color: inspectedUser['avatarTextColor'],
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.verified_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                inspectedUser['name'],
                                style: const TextStyle(
                                  color: AppTheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Matricule: ${inspectedUser['code']}',
                                style: const TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                inspectedUser['email'],
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryFixed,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  inspectedUser['role'],
                                  style: const TextStyle(
                                    color: AppTheme.onPrimaryFixed,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 3 Key Stats Box
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  value: inspectedUser['average'],
                                  label: 'Moyenne /20',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: AppTheme.surfaceContainerHighest,
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  value: inspectedUser['attendance'],
                                  label: 'Assiduité',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: AppTheme.surfaceContainerHighest,
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  value: inspectedUser['tests'],
                                  label: 'Validés',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Cursus & Affectation Section
                        const Text(
                          'CURSUS & AFFECTATION',
                          style: TextStyle(
                            color: AppTheme.outline,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Classe:', inspectedUser['class']),
                        _buildInfoRow(
                            'Rôle spécifique:', inspectedUser['specificRole']),
                        _buildInfoRow('Année scolaire:', inspectedUser['year']),

                        const SizedBox(height: 14),

                        // Sécurité & Supervision
                        const Text(
                          'SÉCURITÉ & SUPERVISION',
                          style: TextStyle(
                            color: AppTheme.outline,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Double Auth (2FA):',
                          inspectedUser['twoFa'] == true
                              ? 'Activée'
                              : 'Désactivée',
                          valueColor: inspectedUser['twoFa'] == true
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                        _buildInfoRow('Dernière IP:', inspectedUser['ip']),
                        _buildInfoRow(
                          'Intégrité Examens:',
                          inspectedUser['frauds'],
                          valueColor: inspectedUser['frauds']
                                  .toString()
                                  .contains('alerte')
                              ? AppTheme.error
                              : AppTheme.onSurface,
                        ),

                        const SizedBox(height: 20),

                        // Action Buttons
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.folder_shared_rounded,
                              size: 16),
                          label: const Text('Voir le dossier académique'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.edit_outlined, size: 15),
                                label: const Text('Modifier'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppTheme.surfaceContainerHighest,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.key_rounded, size: 15),
                                label: const Text('Accès MDP'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppTheme.surfaceContainerHighest,
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
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isAlert
            ? const Color(0xFFFFF1F0)
            : AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert
              ? AppTheme.error.withValues(alpha: 0.2)
              : AppTheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badgeText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isAlert
                  ? Colors.white
                  : AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: isAlert ? AppTheme.error : AppTheme.primary, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterTab(String label, String key) {
    final isSelected = _activeTab == key;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryContainer
              : AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryContainer
                : AppTheme.surfaceContainerHighest,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
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

  Widget _buildStatItem({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? AppTheme.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

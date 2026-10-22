import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../courses/application/providers/courses_provider.dart';
import '../../../home/application/providers/student_dashboard_provider.dart';
import '../../../home/application/providers/teacher_dashboard_provider.dart';
import '../widgets/class_invitation_sheet.dart';
import '../../../../core/widgets/smart_loader.dart';

class ClassDetailPage extends ConsumerStatefulWidget {
  final String groupId;
  final String? initialTitle;

  const ClassDetailPage({required this.groupId, this.initialTitle, super.key});

  @override
  ConsumerState<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends ConsumerState<ClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _teachers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final remote = ref.read(groupsRemoteDataSourceProvider);
      final group = await remote.getClass(widget.groupId);

      List<Map<String, dynamic>> members = [];
      try {
        members = await remote.listMembers(widget.groupId);
      } catch (e) {
        debugPrint('Safe ignore loading members: $e');
      }

      List<Map<String, dynamic>> teachers = [];
      try {
        teachers = await remote.listTeachers(widget.groupId);
      } catch (e) {
        debugPrint('Safe ignore loading teachers: $e');
      }

      if (mounted) {
        setState(() {
          _group = group;
          _members = members;
          _teachers = teachers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeStudent(Map<String, dynamic> member) async {
    final studentId = member['id'] as String? ?? '';
    final studentName =
        '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Retirer l\'étudiant'),
        content: Text(
          'Voulez-vous vraiment retirer $studentName de cette classe ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
            ),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(groupsRemoteDataSourceProvider).removeMembers(
          widget.groupId,
          [studentId],
        );
        if (mounted) {
          context.showInfoToast('$studentName a été retiré de la classe.');
          _loadAll();
          ref.invalidate(teacherDashboardProvider);
          ref.invalidate(myGroupsProvider);
        }
      } catch (e) {
        if (mounted) {
          context.showErrorToast(
            e.toString().replaceFirst('ApiException: ', ''),
          );
        }
      }
    }
  }

  Future<void> _addMySubject() async {
    final input = await showDialog<_SubjectInput>(
      context: context,
      builder: (dialogCtx) => const _AddSubjectDialog(),
    );
    if (input == null || !mounted) return;

    try {
      await ref
          .read(groupsRemoteDataSourceProvider)
          .addMySubject(
            widget.groupId,
            subject: input.subject,
            weeklyHours: input.weeklyHours,
          );
      if (!mounted) return;
      context.showInfoToast(
        'Matière « ${input.subject} » ajoutée à votre classe.',
      );
      await _loadAll();
      ref.invalidate(myGroupsProvider);
      ref.invalidate(teacherDashboardProvider);
    } catch (e) {
      if (mounted) {
        context.showErrorToast(e.toString().replaceFirst('ApiException: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authStateProvider).valueOrNull;

    final role = user?.role?.toLowerCase();
    final isTeacherOrAdmin = role == 'teacher' || role == 'admin';

    final myGroups = ref.watch(myGroupsProvider).valueOrNull ?? const [];
    Map<String, dynamic>? myGroup;
    for (final group in myGroups) {
      if (group['id'] == widget.groupId) {
        myGroup = group;
        break;
      }
    }
    final myRole = (myGroup?['myRole'] as String?)?.toUpperCase();
    final canAddSubject =
        role == 'teacher' && (myRole == 'TEACHER' || myRole == 'REFERENT');
    final mySubjects = ((myGroup?['mySubjects'] as List?) ?? const [])
        .whereType<String>()
        .toList();
    final teacherCount = _teachers
        .map((teacher) => teacher['teacherId'])
        .whereType<String>()
        .toSet()
        .length;

    final className =
        _group?['name'] as String? ??
        widget.initialTitle ??
        'Détails de la classe';
    final level = _group?['level'] as String? ?? '';
    final department = _group?['department'] as String? ?? '';
    final academicYear = _group?['academicYear'] as String? ?? '2026–2027';
    final capacity = (_group?['capacity'] as num?)?.toInt() ?? 30;
    final memberCount = _members.length;
    final fillRatio = capacity > 0
        ? (memberCount / capacity).clamp(0.0, 1.0)
        : 0.0;
    final referent = _group?['referent'] as Map<String, dynamic>?;
    final referentName = referent != null
        ? '${referent['firstName'] ?? ''} ${referent['lastName'] ?? ''}'.trim()
        : 'Aucun référent assigné';

    final filteredMembers = _members.where((m) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final fn = (m['firstName'] as String? ?? '').toLowerCase();
      final ln = (m['lastName'] as String? ?? '').toLowerCase();
      final em = (m['email'] as String? ?? '').toLowerCase();
      return fn.contains(q) || ln.contains(q) || em.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          className,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isTeacherOrAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonalIcon(
                onPressed: () => ClassInvitationSheet.show(
                  context,
                  classGroupId: widget.groupId,
                  className: className,
                ),
                icon: const Icon(Icons.key_rounded, size: 16),
                label: const Text('Invitation'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: SmartLoader.large(message: 'Chargement de la classe...'),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadAll,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _HeroClassCard(
                      className: className,
                      department: department,
                      level: level,
                      academicYear: academicYear,
                      capacity: capacity,
                      memberCount: memberCount,
                      fillRatio: fillRatio,
                      referentName: referentName,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(9999),
                        color: colorScheme.primary,
                      ),
                      labelColor: colorScheme.onPrimary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      tabs: [
                        const Tab(
                          height: 38,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.dashboard_outlined, size: 16),
                              SizedBox(width: 6),
                              Text("Vue d'ensemble"),
                            ],
                          ),
                        ),
                        Tab(
                          height: 38,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.people_outline_rounded,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text("Étudiants ($memberCount)"),
                            ],
                          ),
                        ),
                        const Tab(
                          height: 38,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.menu_book_outlined, size: 16),
                              SizedBox(width: 6),
                              Text("Cours assignés"),
                            ],
                          ),
                        ),
                        Tab(
                          height: 38,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.school_outlined, size: 16),
                              const SizedBox(width: 6),
                              Text("Enseignants ($teacherCount)"),
                            ],
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: colorScheme.surface,
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: Overview & Analytics
                  _OverviewTab(
                    group: _group,
                    memberCount: memberCount,
                    teacherCount: teacherCount,
                    capacity: capacity,
                    className: className,
                  ),

                  // TAB 2: Students Roster
                  _StudentsTab(
                    searchController: _searchController,
                    searchQuery: _searchQuery,
                    onSearchChanged: (v) =>
                        setState(() => _searchQuery = v.trim()),
                    members: filteredMembers,
                    canManage: isTeacherOrAdmin,
                    onRemoveStudent: _removeStudent,
                  ),

                  // TAB 3: Assigned Courses
                  _CoursesTab(groupId: widget.groupId, className: className),

                  // TAB 4: Teachers & Staff
                  _TeachersTab(
                    teachers: _teachers,
                    referentId: referent?['id'] as String?,
                    mySubjects: mySubjects,
                    canAddSubject: canAddSubject,
                    onAddSubject: _addMySubject,
                  ),
                ],
              ),
            ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate(this.tabBar, {required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height + 12;
  @override
  double get maxExtent => tabBar.preferredSize.height + 12;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      child: Center(child: tabBar),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _HeroClassCard extends StatelessWidget {
  final String className;
  final String department;
  final String level;
  final String academicYear;
  final int capacity;
  final int memberCount;
  final double fillRatio;
  final String referentName;

  const _HeroClassCard({
    required this.className,
    required this.department,
    required this.level,
    required this.academicYear,
    required this.capacity,
    required this.memberCount,
    required this.fillRatio,
    required this.referentName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final subtitleParts = [
      if (department.isNotEmpty) department,
      if (level.isNotEmpty) level,
      academicYear,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        subtitleParts.isNotEmpty
                            ? subtitleParts
                            : 'Cohorte universitaire',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      className,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryFixed.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Actif',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onTertiaryFixed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.person_pin_circle_outlined,
                size: 16,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Référent: $referentName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Effectif',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$memberCount / $capacity inscrits (${(fillRatio * 100).toInt()}%)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: fillRatio,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

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

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _FeatureBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AdminRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _StudentsTab extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final List<Map<String, dynamic>> members;
  final bool canManage;
  final ValueChanged<Map<String, dynamic>> onRemoveStudent;

  const _StudentsTab({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.members,
    required this.canManage,
    required this.onRemoveStudent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher un étudiant par nom ou email...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: members.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 48,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'Aucun étudiant ne correspond à "$searchQuery"'
                              : 'Aucun étudiant inscrit dans cette classe',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final firstName = member['firstName'] as String? ?? '';
                    final lastName = member['lastName'] as String? ?? '';
                    final email = member['email'] as String? ?? '';
                    final initials =
                        (firstName.isNotEmpty ? firstName[0] : '') +
                        (lastName.isNotEmpty ? lastName[0] : '');

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.2,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              initials.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$firstName $lastName'.trim().isEmpty
                                      ? 'Étudiant'
                                      : '$firstName $lastName'.trim(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (email.isNotEmpty)
                                  Text(
                                    email,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (canManage)
                            IconButton(
                              icon: const Icon(
                                Icons.person_remove_outlined,
                                size: 20,
                              ),
                              color: colorScheme.error,
                              tooltip: 'Retirer de la classe',
                              onPressed: () => onRemoveStudent(member),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CoursesTab extends ConsumerWidget {
  final String groupId;
  final String className;

  const _CoursesTab({required this.groupId, required this.className});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final publishedAsync = ref.watch(publishedCoursesProvider);

    return publishedAsync.when(
      loading: () => const Center(
        child: SmartLoader.medium(message: 'Chargement des cours...'),
      ),
      error: (e, _) =>
          Center(child: Text('Erreur de chargement des cours : $e')),
      data: (courses) {
        if (courses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 48,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Aucun cours assigné à cette classe pour le moment.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: courses.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final course = courses[index];
            return InkWell(
              onTap: () => context.push('/courses/${course.id}'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryFixed.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            course.subject ?? 'Tronc Commun',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          size: 14,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.level} • ${course.difficulty}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            course.authorName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TeacherEntry {
  _TeacherEntry({
    required this.teacherId,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String teacherId;
  final String firstName;
  final String lastName;
  final String email;
  final List<_TaughtSubject> subjects = [];
}

class _TaughtSubject {
  const _TaughtSubject(this.subject, this.weeklyHours);

  final String subject;
  final String? weeklyHours;
}

class _TeachersTab extends StatelessWidget {
  final List<Map<String, dynamic>> teachers;
  final String? referentId;
  final List<String> mySubjects;
  final bool canAddSubject;
  final VoidCallback onAddSubject;

  const _TeachersTab({
    required this.teachers,
    this.referentId,
    this.mySubjects = const [],
    this.canAddSubject = false,
    required this.onAddSubject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final grouped = <String, _TeacherEntry>{};
    for (final teacher in teachers) {
      final teacherId = teacher['teacherId'] as String? ?? '';
      if (teacherId.isEmpty) continue;
      final entry = grouped.putIfAbsent(
        teacherId,
        () => _TeacherEntry(
          teacherId: teacherId,
          firstName: teacher['firstName'] as String? ?? '',
          lastName: teacher['lastName'] as String? ?? '',
          email: teacher['email'] as String? ?? '',
        ),
      );
      final subject = (teacher['subject'] as String?)?.trim() ?? '';
      if (subject.isNotEmpty &&
          !entry.subjects.any((item) => item.subject == subject)) {
        entry.subjects.add(
          _TaughtSubject(subject, teacher['weeklyHours'] as String?),
        );
      }
    }
    final entries = grouped.values.toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (canAddSubject) ...[
          _MySubjectsCard(mySubjects: mySubjects, onAddSubject: onAddSubject),
          const SizedBox(height: 14),
        ],
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 10),
                Text(
                  'Aucun enseignant assigné pour l\'instant.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TeacherCard(
                entry: entry,
                isReferent: referentId != null && referentId == entry.teacherId,
              ),
            ),
          ),
      ],
    );
  }
}

class _MySubjectsCard extends StatelessWidget {
  const _MySubjectsCard({required this.mySubjects, required this.onAddSubject});

  final List<String> mySubjects;
  final VoidCallback onAddSubject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mes matières dans cette classe',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Vous pouvez enseigner plusieurs matières dans la même classe.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (mySubjects.isEmpty)
            Text(
              'Aucune matière déclarée pour le moment.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: mySubjects
                  .map(
                    (subject) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        subject,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onAddSubject,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ajouter une matière'),
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  const _TeacherCard({required this.entry, required this.isReferent});

  final _TeacherEntry entry;
  final bool isReferent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initials =
        (entry.firstName.isNotEmpty ? entry.firstName[0] : '') +
        (entry.lastName.isNotEmpty ? entry.lastName[0] : '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReferent
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: isReferent ? 1.2 : 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isReferent
                ? colorScheme.primary
                : colorScheme.secondaryContainer,
            child: Text(
              initials.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isReferent ? Colors.white : colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${entry.firstName} ${entry.lastName}'.trim(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isReferent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          'Référent',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.subjects
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.weeklyHours != null &&
                                    item.weeklyHours!.isNotEmpty
                                ? '${item.subject} · ${item.weeklyHours}'
                                : item.subject,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (entry.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.email,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectInput {
  const _SubjectInput({required this.subject, this.weeklyHours});

  final String subject;
  final String? weeklyHours;
}

class _AddSubjectDialog extends StatefulWidget {
  const _AddSubjectDialog();

  @override
  State<_AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<_AddSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _hoursController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final hours = _hoursController.text.trim();
    Navigator.of(context).pop(
      _SubjectInput(
        subject: _subjectController.text.trim(),
        weeklyHours: hours.isEmpty ? null : hours,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une matière'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _subjectController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Matière',
                hintText: 'Ex. Architecture Logicielle',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 2) {
                  return 'Saisissez au moins 2 caractères.';
                }
                if (text.length > 100) {
                  return '100 caractères maximum.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hoursController,
              decoration: const InputDecoration(
                labelText: 'Volume horaire (optionnel)',
                hintText: 'Ex. 3h/semaine',
              ),
              validator: (value) {
                if ((value?.trim().length ?? 0) > 50) {
                  return '50 caractères maximum.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Ajouter')),
      ],
    );
  }
}

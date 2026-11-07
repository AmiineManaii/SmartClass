part of '../pages/class_detail_page.dart';

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


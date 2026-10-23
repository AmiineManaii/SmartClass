import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_person.dart';
import '../widgets/web_admin_scaffold.dart';

typedef WebAdminUsersView = WebAdminUsersPage;

class WebAdminUsersPage extends ConsumerStatefulWidget {
  const WebAdminUsersPage({super.key});

  @override
  ConsumerState<WebAdminUsersPage> createState() => _WebAdminUsersPageState();
}

class _WebAdminUsersPageState extends ConsumerState<WebAdminUsersPage> {
  String _activeTab = 'all'; // 'all' | 'students' | 'teachers'
  final Set<String> _selectedUserIds = {};
  String? _inspectedUserId;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateTeacherApproval(String teacherId, String status) async {
    try {
      await ref.read(adminRepositoryProvider).updateTeacherApproval(teacherId, status);
      ref.invalidate(adminTeachersProvider(null));
      ref.invalidate(adminOverviewProvider);
      if (mounted) {
        context.showSuccessToast(
          status == 'APPROVED'
              ? context.tr('admin_toast_teacher_approved')
              : context.tr('admin_toast_teacher_updated'),
        );
      }
    } catch (e) {
      if (mounted) context.showErrorToast(context.tr('admin_toast_update_error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

    final studentsAsync = ref.watch(adminStudentsProvider(null));
    final teachersAsync = ref.watch(adminTeachersProvider(null));
    final students = studentsAsync.valueOrNull ?? const [];
    final teachers = teachersAsync.valueOrNull ?? const [];

    // Filter combined list
    final List<({String id, String name, String email, String role, String detail, String status, bool isTeacher, AdminTeacher? teacherObj, AdminStudent? studentObj})> allItems = [];

    for (final s in students) {
      allItems.add((
        id: s.id,
        name: s.name,
        email: s.email,
        role: context.tr('role_student'),
        detail: s.assignedClassId != null ? context.tr('admin_status_assigned') : context.tr('admin_unassigned_badge'),
        status: s.verified ? context.tr('admin_badge_verified') : context.tr('admin_badge_pending'),
        isTeacher: false,
        teacherObj: null,
        studentObj: s,
      ));
    }

    for (final t in teachers) {
      allItems.add((
        id: t.id,
        name: t.name,
        email: t.email,
        role: context.tr('role_teacher'),
        detail: t.specialty.isNotEmpty
            ? t.specialty
            : (t.subjectLabel.isNotEmpty ? t.subjectLabel : context.tr('admin_inspector_general')),
        status: t.approvalStatus,
        isTeacher: true,
        teacherObj: t,
        studentObj: null,
      ));
    }

    // Filter by tab
    var displayList = allItems;
    if (_activeTab == 'students') {
      displayList = allItems.where((u) => !u.isTeacher).toList();
    } else if (_activeTab == 'teachers') {
      displayList = allItems.where((u) => u.isTeacher).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      displayList = displayList
          .where((u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.detail.toLowerCase().contains(q))
          .toList();
    }

    // Currently inspected user
    if (_inspectedUserId == null && displayList.isNotEmpty) {
      _inspectedUserId = displayList.first.id;
    }
    final inspected = displayList.firstWhere(
      (u) => u.id == _inspectedUserId,
      orElse: () => displayList.isNotEmpty
          ? displayList.first
          : (
              id: '',
              name: '—',
              email: '—',
              role: '—',
              detail: '—',
              status: '—',
              isTeacher: false,
              teacherObj: null,
              studentObj: null,
            ),
    );

    final totalUsersCount = students.length + teachers.length;

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
                          'ESPACE ADMINISTRATION',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF818CF8)
                                : AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded,
                            size: 14,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : AppTheme.outline),
                        const SizedBox(width: 6),
                        Text(
                          context.tr('admin_users_breadcrumb_current'),
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : AppTheme.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('admin_users_page_heading'),
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('admin_users_page_desc'),
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AppTheme.onSurfaceVariant,
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
                        ref.invalidate(adminStudentsProvider(null));
                        ref.invalidate(adminTeachersProvider(null));
                        ref.invalidate(adminOverviewProvider);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Actualiser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white : AppTheme.primary,
                        backgroundColor: cardBg,
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
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
            // 2. 3 METRIC CARDS (REAL DATA)
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    isDark: isDark,
                    title: 'TOTAL UTILISATEURS',
                    value: '$totalUsersCount',
                    badgeText: 'Comptes actifs',
                    badgeColor: const Color(0xFF10B981),
                    icon: Icons.groups_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_enrolled_students'),
                    value: '${students.length}',
                    badgeText: context.tr('admin_kpi_student_headcount'),
                    badgeColor: const Color(0xFF2563EB),
                    icon: Icons.school_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    isDark: isDark,
                    title: 'CORPS PROFESSORAL',
                    value: '${teachers.length}',
                    badgeText: 'Enseignants',
                    badgeColor: const Color(0xFF7C3AED),
                    icon: Icons.co_present_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 3. TABS & SEARCH BAR
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
                    _buildRoleFilterTab(
                      label: 'Tous ($totalUsersCount)',
                      tabKey: 'all',
                      isDark: isDark,
                    ),
                    _buildRoleFilterTab(
                      label: context.tr('admin_tab_students_count', args: {'count': students.length.toString()}),
                      tabKey: 'students',
                      isDark: isDark,
                    ),
                    _buildRoleFilterTab(
                      label: 'Enseignants (${teachers.length})',
                      tabKey: 'teachers',
                      isDark: isDark,
                    ),
                  ],
                ),

                // Live search box
                Container(
                  width: 320,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppTheme.outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : AppTheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Filtrer par nom, email...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : AppTheme.outline,
                              fontSize: 12.5,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(Icons.close_rounded,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : AppTheme.outline),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 4. MAIN SPLIT VIEW (TABLE 65% + INSPECTOR 35%)
            // ==========================================
            (studentsAsync.isLoading || teachersAsync.isLoading)
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: SmartLoader.medium()),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Table Area
                      Expanded(
                        flex: 65,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: isDark ? 0.3 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: displayList.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 48, horizontal: 24),
                                  child: Center(
                                    child: Text(
                                      context.tr('admin_no_users_match_filter'),
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    // Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E293B)
                                                .withValues(alpha: 0.6)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(15),
                                        ),
                                        border: Border(
                                            bottom:
                                                BorderSide(color: borderColor)),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 32),
                                          Expanded(
                                            flex: 4,
                                            child: Text(
                                              context.tr('admin_col_user'),
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 4,
                                            child: Text(
                                              context.tr('admin_col_academic_email'),
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              context.tr('admin_col_role_class'),
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Rows
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: displayList.length,
                                      separatorBuilder: (_, _) => Divider(
                                        height: 1,
                                        color: borderColor,
                                      ),
                                      itemBuilder: (context, index) {
                                        final user = displayList[index];
                                        final isSelected = _selectedUserIds
                                            .contains(user.id);
                                        final isInspected =
                                            _inspectedUserId == user.id;

                                        return InkWell(
                                          onTap: () => setState(
                                              () => _inspectedUserId = user.id),
                                          child: Container(
                                            color: isInspected
                                                ? (isDark
                                                    ? const Color(0xFF1E293B)
                                                    : const Color(0xFFEEF2FF))
                                                : Colors.transparent,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 18, vertical: 12),
                                            child: Row(
                                              children: [
                                                // Checkbox
                                                SizedBox(
                                                  width: 32,
                                                  child: Checkbox(
                                                    value: isSelected,
                                                    activeColor:
                                                        const Color(0xFF2563EB),
                                                    onChanged: (v) {
                                                      setState(() {
                                                        if (v == true) {
                                                          _selectedUserIds
                                                              .add(user.id);
                                                        } else {
                                                          _selectedUserIds
                                                              .remove(user.id);
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),

                                                // User Avatar & Name
                                                Expanded(
                                                  flex: 4,
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 17,
                                                        backgroundColor: user
                                                                .isTeacher
                                                            ? const Color(
                                                                    0xFF7C3AED)
                                                                .withValues(
                                                                    alpha: 0.15)
                                                            : const Color(
                                                                    0xFF2563EB)
                                                                .withValues(
                                                                    alpha:
                                                                        0.15),
                                                        child: Text(
                                                          user.name.isNotEmpty
                                                              ? user.name[0]
                                                                  .toUpperCase()
                                                              : 'U',
                                                          style: TextStyle(
                                                            color: user.isTeacher
                                                                ? const Color(
                                                                    0xFF7C3AED)
                                                                : const Color(
                                                                    0xFF2563EB),
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          user.name,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: isDark
                                                                ? Colors.white
                                                                : AppTheme
                                                                    .onSurface,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Email
                                                Expanded(
                                                  flex: 4,
                                                  child: Text(
                                                    user.email,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF94A3B8)
                                                          : AppTheme
                                                              .onSurfaceVariant,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),

                                                // Role & Class
                                                Expanded(
                                                  flex: 3,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 7,
                                                                vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: user.isTeacher
                                                              ? const Color(
                                                                      0xFF7C3AED)
                                                                  .withValues(
                                                                      alpha:
                                                                          0.12)
                                                              : const Color(
                                                                      0xFF2563EB)
                                                                  .withValues(
                                                                      alpha:
                                                                          0.12),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Text(
                                                          user.role.toUpperCase(),
                                                          style: TextStyle(
                                                            color: user
                                                                    .isTeacher
                                                                ? const Color(
                                                                    0xFF7C3AED)
                                                                : const Color(
                                                                    0xFF2563EB),
                                                            fontSize: 9.5,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        user.detail,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF94A3B8)
                                                              : AppTheme
                                                                  .onSurfaceVariant,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Inspector Panel (Right 35%)
                      Expanded(
                        flex: 35,
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: isDark ? 0.3 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: inspected.id.isEmpty
                              ? Center(
                                  child: Text(context.tr('admin_select_a_user')))
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: inspected.isTeacher
                                              ? const Color(0xFF7C3AED)
                                                  .withValues(alpha: 0.15)
                                              : const Color(0xFF2563EB)
                                                  .withValues(alpha: 0.15),
                                          child: Text(
                                            inspected.name.isNotEmpty
                                                ? inspected.name[0]
                                                    .toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              color: inspected.isTeacher
                                                  ? const Color(0xFF7C3AED)
                                                  : const Color(0xFF2563EB),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                inspected.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : AppTheme.onSurface,
                                                ),
                                              ),
                                              Text(
                                                inspected.email,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : AppTheme
                                                          .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Divider(color: borderColor),
                                    const SizedBox(height: 12),
                                    _buildInspectorRow(
                                      context.tr('admin_label_role'),
                                      inspected.role,
                                      isDark,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildInspectorRow(
                                      context.tr('admin_label_assignment'),
                                      inspected.detail,
                                      isDark,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildInspectorRow(
                                      context.tr('admin_col_status'),
                                      inspected.status.isNotEmpty
                                          ? inspected.status
                                          : 'Actif',
                                      isDark,
                                    ),
                                    const SizedBox(height: 24),

                                    // Quick action for teachers
                                    if (inspected.isTeacher) ...[
                                      Text(
                                        context.tr('admin_label_pedagogical_accreditation'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton.icon(
                                              onPressed: () =>
                                                  _updateTeacherApproval(
                                                      inspected.id, 'APPROVED'),
                                              icon: const Icon(
                                                  Icons.check_circle_outline,
                                                  size: 16),
                                              label: Text(context.tr('admin_btn_validate')),
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF10B981),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  _updateTeacherApproval(
                                                      inspected.id, 'REJECTED'),
                                              child: Text(context.tr('admin_btn_suspend')),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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

  Widget _buildInspectorRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : AppTheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleFilterTab({
    required String label,
    required String tabKey,
    required bool isDark,
  }) {
    final isSelected = _activeTab == tabKey;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabKey),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF2563EB))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required bool isDark,
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
  }) {
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: badgeColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

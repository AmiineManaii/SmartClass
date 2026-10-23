import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/repositories/admin_repository.dart';
import '../widgets/web_admin_scaffold.dart';

/// Dedicated Desktop Web view for Teacher & Professor Management.
class WebAdminTeachersView extends ConsumerStatefulWidget {
  const WebAdminTeachersView({super.key});

  @override
  ConsumerState<WebAdminTeachersView> createState() =>
      _WebAdminTeachersViewState();
}

class _WebAdminTeachersViewState extends ConsumerState<WebAdminTeachersView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // 'ALL', 'APPROVED', 'PENDING', 'REJECTED'
  String? _inspectedTeacherId;
  final Set<String> _selectedTeacherIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateTeacherApproval(
    String teacherId,
    String status,
    String teacherName,
  ) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateTeacherApproval(teacherId, status);
      ref.invalidate(adminTeachersProvider(null));
      ref.invalidate(adminOverviewProvider);
      if (mounted) {
        context.showSuccessToast(
          status == 'APPROVED'
              ? context.tr('admin_toast_accreditation_approved', args: {'name': teacherName})
              : context.tr('admin_toast_accreditation_rejected', args: {'name': teacherName}),
        );
      }
    } catch (e) {
      if (mounted) context.showErrorToast(context.tr('admin_toast_update_error'));
    }
  }

  Future<void> _confirmPromoteToAdmin(AdminTeacher teacher) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.tr('admin_btn_promote_admin'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('admin_dialog_promote_desc'),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        teacher.initials ?? 'PR',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            teacher.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('admin_dialog_promote_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              icon: const Icon(Icons.security_rounded, size: 16),
              label: Text(context.tr('admin_btn_confirm_promotion')),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref
            .read(adminRepositoryProvider)
            .updateUserRole(teacher.id, 'ADMIN');
        ref.invalidate(adminTeachersProvider(null));
        ref.invalidate(adminOverviewProvider);
        if (mounted) {
          context.showSuccessToast(
            context.tr('admin_toast_promoted_success', args: {'name': teacher.name}),
          );
        }
      } catch (e) {
        if (mounted) {
          context.showErrorToast(
            context.tr('admin_toast_promote_fail'),
          );
        }
      }
    }
  }

  Future<void> _openAssignClassDialog(AdminTeacher teacher) async {
    final classesAsync = await ref.read(adminClassesProvider.future);
    if (!mounted) return;

    if (classesAsync.isEmpty) {
      context.showInfoToast(context.tr('admin_no_classes_available'));
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    String selectedClassId = classesAsync.first.id;
    final subjectController = TextEditingController(
      text: teacher.specialty.isNotEmpty ? teacher.specialty : '',
    );
    final hoursController = TextEditingController(text: context.tr('admin_hours_per_week', args: {'hours': '4'}));

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_ind_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('admin_dialog_assign_title'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('admin_teacher_label', args: {'name': teacher.name}),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      teacher.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('admin_select_class_cohort'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedClassId,
                          dropdownColor: dialogBg,
                          items: classesAsync.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(
                                '${c.title} • ${c.promoTag}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedClassId = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('admin_dialog_subject_label'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        hintText: context.tr('admin_dialog_subject_hint'),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('admin_weekly_hours_label'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: hoursController,
                      decoration: InputDecoration(
                        hintText: context.tr('admin_dialog_hours_hint'),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: Text(context.tr('cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                  child: Text(context.tr('admin_btn_save_assignment')),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      try {
        final subject = subjectController.text.trim().isEmpty
            ? 'Enseignement'
            : subjectController.text.trim();
        final hours = hoursController.text.trim();

        await ref.read(adminRepositoryProvider).assignTeachers(
          selectedClassId,
          [
            TeacherAssignment(
              teacherId: teacher.id,
              subject: subject,
              weeklyHours: hours,
            ),
          ],
        );
        ref.invalidate(adminTeachersProvider(null));
        ref.invalidate(adminClassesProvider);
        if (mounted) {
          context.showSuccessToast(
            context.tr('admin_toast_assign_success', args: {'name': teacher.name}),
          );
        }
      } catch (e) {
        if (mounted) {
          context.showErrorToast(context.tr('admin_toast_assign_fail'));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

    final teachersAsync = ref.watch(adminTeachersProvider(null));
    final teachers = teachersAsync.valueOrNull ?? const [];

    // Filter teachers list
    var filteredTeachers = teachers.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.name.toLowerCase().contains(_searchQuery) ||
          t.email.toLowerCase().contains(_searchQuery) ||
          t.specialty.toLowerCase().contains(_searchQuery);

      if (!matchesSearch) return false;

      if (_statusFilter == 'APPROVED') return t.approvalStatus == 'APPROVED';
      if (_statusFilter == 'PENDING') return t.approvalStatus == 'PENDING';
      if (_statusFilter == 'REJECTED') return t.approvalStatus == 'REJECTED';
      return true;
    }).toList();

    final approvedCount =
        teachers.where((t) => t.approvalStatus == 'APPROVED').length;
    final pendingCount =
        teachers.where((t) => t.approvalStatus == 'PENDING').length;
    final assignedCount =
        teachers.where((t) => t.initiallyAssigned || t.specialty.isNotEmpty).length;

    AdminTeacher? inspectedTeacher;
    if (_inspectedTeacherId != null) {
      for (final t in teachers) {
        if (t.id == _inspectedTeacherId) {
          inspectedTeacher = t;
          break;
        }
      }
    }

    return WebAdminScaffold(
      activePath: '/admin/teachers',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // 1. PAGE HEADER
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
                          context.tr('admin_teachers_breadcrumb_cat'),
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
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : AppTheme.outline,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.tr('admin_teachers_breadcrumb_current'),
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
                      context.tr('admin_teachers_page_heading'),
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('admin_teachers_page_desc'),
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
                        ref.invalidate(adminTeachersProvider(null));
                        ref.invalidate(adminOverviewProvider);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(context.tr('admin_refresh_button')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white : AppTheme.primary,
                        backgroundColor: cardBg,
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
            // 2. 4 METRIC CARDS (TEACHER SPECIFIC)
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_total_teachers'),
                    value: teachers.length.toString(),
                    badgeText: context.tr('admin_kpi_badge_faculty'),
                    badgeColor: const Color(0xFF6366F1),
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_approved_accreditations'),
                    value: approvedCount.toString(),
                    badgeText: context.tr('admin_kpi_badge_verified_profiles'),
                    badgeColor: const Color(0xFF10B981),
                    icon: Icons.verified_user_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_pending_accreditation'),
                    value: pendingCount.toString(),
                    badgeText: pendingCount > 0 ? context.tr('admin_kpi_badge_to_handle') : context.tr('admin_kpi_badge_up_to_date'),
                    badgeColor: pendingCount > 0
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                    icon: Icons.pending_actions_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_assigned_teachers'),
                    value: assignedCount.toString(),
                    badgeText: context.tr('admin_kpi_badge_active_in_class'),
                    badgeColor: const Color(0xFF3B82F6),
                    icon: Icons.class_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 3. SEARCH & STATUS FILTER TABS
            // ==========================================
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterPill(
                      label: context.tr('admin_filter_all_label', args: {'count': teachers.length.toString()}),
                      filterKey: 'ALL',
                      isDark: isDark,
                    ),
                    _buildFilterPill(
                      label: context.tr('admin_filter_validated_label', args: {'count': approvedCount.toString()}),
                      filterKey: 'APPROVED',
                      isDark: isDark,
                    ),
                    _buildFilterPill(
                      label: context.tr('admin_filter_pending_label', args: {'count': pendingCount.toString()}),
                      filterKey: 'PENDING',
                      isDark: isDark,
                      highlight: pendingCount > 0,
                    ),
                    _buildFilterPill(
                      label: context.tr('admin_filter_rejected_label', args: {'count': teachers.where((t) => t.approvalStatus == 'REJECTED').length.toString()}),
                      filterKey: 'REJECTED',
                      isDark: isDark,
                    ),
                  ],
                ),
                SizedBox(
                  width: 320,
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.trim().toLowerCase()),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : AppTheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: context.tr('admin_search_teachers_placeholder'),
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : AppTheme.onSurfaceVariant,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : AppTheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: cardBg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 4. MAIN TEACHERS TABLE + INSPECTOR
            // ==========================================
            teachersAsync.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(60),
                      child: SmartLoader(size: SmartLoaderSize.medium),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Teachers Table
                      Expanded(
                        flex: inspectedTeacher != null ? 7 : 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.02)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  border: Border(
                                    bottom: BorderSide(color: borderColor),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        context.tr('admin_col_teacher'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : AppTheme.onSurfaceVariant,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        context.tr('admin_col_specialty_courses'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : AppTheme.onSurfaceVariant,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        context.tr('admin_col_accreditation'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : AppTheme.onSurfaceVariant,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        context.tr('admin_col_dedicated_actions'),
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : AppTheme.onSurfaceVariant,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Rows
                              if (filteredTeachers.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.person_search_rounded,
                                          size: 48,
                                          color: isDark
                                              ? const Color(0xFF475569)
                                              : Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          context.tr('admin_no_teachers_found'),
                                          style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : AppTheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredTeachers.length,
                                  separatorBuilder: (_, _) =>
                                      Divider(height: 1, color: borderColor),
                                  itemBuilder: (context, index) {
                                    final teacher = filteredTeachers[index];
                                    final isSelected =
                                        _selectedTeacherIds.contains(teacher.id);
                                    final isInspected =
                                        _inspectedTeacherId == teacher.id;

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _inspectedTeacherId = isInspected
                                              ? null
                                              : teacher.id;
                                        });
                                      },
                                      child: Container(
                                        color: isInspected
                                            ? (isDark
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFFF1F5F9))
                                            : null,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            // Checkbox
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedTeacherIds
                                                        .add(teacher.id);
                                                  } else {
                                                    _selectedTeacherIds
                                                        .remove(teacher.id);
                                                  }
                                                });
                                              },
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // Teacher Info (Avatar, Name, Email)
                                            Expanded(
                                              flex: 4,
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 17,
                                                    backgroundColor: AppTheme
                                                        .primary
                                                        .withValues(alpha: 0.15),
                                                    child: Text(
                                                      teacher.initials ?? 'PR',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppTheme.primary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          teacher.name,
                                                          style: TextStyle(
                                                            fontSize: 13.5,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: isDark
                                                                ? Colors.white
                                                                : AppTheme
                                                                    .onSurface,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          teacher.email,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            color: isDark
                                                                ? const Color(
                                                                    0xFF94A3B8)
                                                                : AppTheme
                                                                    .onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Specialty & Course
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    teacher.specialty.isNotEmpty
                                                        ? teacher.specialty
                                                        : (teacher.subjectLabel.isNotEmpty
                                                            ? teacher.subjectLabel
                                                            : context.tr('admin_unassigned_teacher')),
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w500,
                                                      color: teacher.specialty.isNotEmpty || teacher.subjectLabel.isNotEmpty
                                                          ? (isDark ? Colors.white : AppTheme.onSurface)
                                                          : (isDark ? const Color(0xFF64748B) : Colors.grey),
                                                    ),
                                                  ),
                                                  if (teacher.availabilityArgs.isNotEmpty)
                                                    Text(
                                                      teacher.availabilityArgs,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isDark
                                                            ? const Color(0xFF94A3B8)
                                                            : AppTheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),

                                            // Status Badge
                                            Expanded(
                                              flex: 2,
                                              child: Row(
                                                children: [
                                                  _buildStatusBadge(
                                                    teacher.approvalStatus,
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Dedicated Actions
                                            Expanded(
                                              flex: 3,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  // Promote to Admin Button
                                                  Tooltip(
                                                    message: context.tr('admin_promote_admin_tooltip'),
                                                    child: OutlinedButton.icon(
                                                      onPressed: () =>
                                                          _confirmPromoteToAdmin(
                                                              teacher),
                                                      icon: const Icon(
                                                        Icons.security_rounded,
                                                        size: 14,
                                                        color: Color(0xFF6366F1),
                                                      ),
                                                      label: const Text(
                                                        'Admin',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Color(0xFF6366F1),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        side: BorderSide(
                                                          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),

                                                  // Assign Class Button
                                                  Tooltip(
                                                    message: context.tr('admin_assign_class_tooltip'),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.group_add_outlined,
                                                        size: 18,
                                                      ),
                                                      color: isDark
                                                          ? const Color(0xFF94A3B8)
                                                          : const Color(0xFF475569),
                                                      onPressed: () =>
                                                          _openAssignClassDialog(
                                                              teacher),
                                                    ),
                                                  ),

                                                  // Quick Approval Action if pending
                                                  if (teacher.approvalStatus == 'PENDING') ...[
                                                    Tooltip(
                                                      message: context.tr('admin_validate_accreditation_tooltip'),
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.check_circle_rounded,
                                                          size: 19,
                                                          color: Color(0xFF10B981),
                                                        ),
                                                        onPressed: () =>
                                                            _updateTeacherApproval(
                                                          teacher.id,
                                                          'APPROVED',
                                                          teacher.name,
                                                        ),
                                                      ),
                                                    ),
                                                    Tooltip(
                                                      message: context.tr('admin_reject_tooltip'),
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.cancel_rounded,
                                                          size: 19,
                                                          color: Color(0xFFEF4444),
                                                        ),
                                                        onPressed: () =>
                                                            _updateTeacherApproval(
                                                          teacher.id,
                                                          'REJECTED',
                                                          teacher.name,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
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

                      // Side Inspector
                      if (inspectedTeacher != null) ...[
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 3,
                          child: _buildInspector(
                            teacher: inspectedTeacher,
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                          ),
                        ),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'APPROVED':
        bg = const Color(0xFF10B981).withValues(alpha: 0.12);
        text = const Color(0xFF10B981);
        label = context.tr('admin_badge_approved');
        break;
      case 'PENDING':
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        text = const Color(0xFFF59E0B);
        label = context.tr('admin_badge_pending');
        break;
      case 'REJECTED':
        bg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        text = const Color(0xFFEF4444);
        label = context.tr('admin_badge_rejected');
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.12);
        text = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required String filterKey,
    required bool isDark,
    bool highlight = false,
  }) {
    final isSelected = _statusFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _statusFilter = filterKey),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF2563EB))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: highlight && !isSelected
              ? Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5))
              : null,
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

  Widget _buildMetricCard({
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : AppTheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: badgeColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspector({
    required AdminTeacher teacher,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('admin_inspector_teacher_title'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : AppTheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(() => _inspectedTeacherId = null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    teacher.initials ?? 'PR',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  teacher.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.onSurface,
                  ),
                ),
                Text(
                  teacher.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: borderColor),
          const SizedBox(height: 12),
          _buildInspectorRow(context.tr('admin_inspector_accreditation_status'), teacher.approvalStatus, isDark),
          const SizedBox(height: 10),
          _buildInspectorRow(
            context.tr('admin_inspector_specialty'),
            teacher.specialty.isNotEmpty ? teacher.specialty : context.tr('admin_inspector_general'),
            isDark,
          ),
          const SizedBox(height: 10),
          _buildInspectorRow(
            context.tr('admin_inspector_hourly_load'),
            teacher.availabilityArgs.isNotEmpty ? teacher.availabilityArgs : context.tr('admin_inspector_unspecified'),
            isDark,
          ),
          const SizedBox(height: 10),
          _buildInspectorRow(
            context.tr('admin_inspector_email_verified'),
            teacher.verified ? context.tr('yes') : context.tr('no'),
            isDark,
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('admin_inspector_quick_actions'),
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _confirmPromoteToAdmin(teacher),
              icon: const Icon(Icons.admin_panel_settings_rounded, size: 16),
              label: Text(context.tr('admin_btn_promote_admin')),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openAssignClassDialog(teacher),
              icon: const Icon(Icons.school_rounded, size: 16),
              label: Text(context.tr('admin_btn_assign_to_class')),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: borderColor),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (teacher.approvalStatus != 'APPROVED')
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _updateTeacherApproval(
                  teacher.id,
                  'APPROVED',
                  teacher.name,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Valider l\'accréditation'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (teacher.approvalStatus == 'APPROVED')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _updateTeacherApproval(
                  teacher.id,
                  'REJECTED',
                  teacher.name,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Suspendre / Rejeter'),
              ),
            ),
        ],
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
}

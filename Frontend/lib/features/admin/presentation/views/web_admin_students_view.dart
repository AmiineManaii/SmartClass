import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/entities/managed_class.dart';
import '../widgets/web_admin_scaffold.dart';

/// Dedicated Desktop Web view for Student Management & Cohort Assignment.
class WebAdminStudentsView extends ConsumerStatefulWidget {
  const WebAdminStudentsView({super.key});

  @override
  ConsumerState<WebAdminStudentsView> createState() =>
      _WebAdminStudentsViewState();
}

class _WebAdminStudentsViewState extends ConsumerState<WebAdminStudentsView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedClassFilter; // null = all, or classId
  String? _inspectedStudentId;
  final Set<String> _selectedStudentIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAssignClassDialog(AdminStudent student, List<AdminClassSummary> classes) async {
    if (classes.isEmpty) {
      context.showInfoToast(context.tr('admin_no_classes_available'));
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    String selectedClassId = student.assignedClassId ?? classes.first.id;

    final confirmed = await showDialog<bool>(
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
                      Icons.school_rounded,
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
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('admin_student_label', args: {'name': student.name}),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      student.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('admin_choose_cohort_assign'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedClassId,
                          dropdownColor: dialogBg,
                          items: classes.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(
                                "${c.title} • ${c.promoTag} (${context.tr('admin_enrolled_count', args: {'count': c.students.toString()})})",
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
                    const SizedBox(height: 12),
                    Text(
                      context.tr('admin_student_assign_notice'),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                  child: Text(context.tr('admin_confirm_assign')),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref
            .read(adminRepositoryProvider)
            .assignStudents(selectedClassId, [student.id]);
        ref.invalidate(adminStudentsProvider(null));
        ref.invalidate(adminClassesProvider);
        ref.invalidate(adminOverviewProvider);
        if (mounted) {
          context.showSuccessToast(
            context.tr('admin_toast_student_assigned_success', args: {'name': student.name}),
          );
        }
      } catch (e) {
        if (mounted) {
          context.showErrorToast(context.tr('admin_toast_student_assign_fail'));
        }
      }
    }
  }

  Future<void> _removeFromClass(AdminStudent student, String classId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(context.tr('admin_dialog_remove_title')),
          content: Text(
            context.tr('admin_dialog_remove_msg', args: {'name': student.name}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              child: Text(context.tr('admin_btn_remove')),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref
            .read(adminRepositoryProvider)
            .removeStudents(classId, [student.id]);
        ref.invalidate(adminStudentsProvider(null));
        ref.invalidate(adminClassesProvider);
        ref.invalidate(adminOverviewProvider);
        if (mounted) {
          context.showSuccessToast(context.tr('admin_toast_student_removed', args: {'name': student.name}));
        }
      } catch (e) {
        if (mounted) {
          context.showErrorToast(context.tr('admin_toast_student_remove_fail'));
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

    final studentsAsync = ref.watch(adminStudentsProvider(_selectedClassFilter));
    final classesAsync = ref.watch(adminClassesProvider);

    final students = studentsAsync.valueOrNull ?? const [];
    final classes = classesAsync.valueOrNull ?? const [];

    // Map classId to ClassSummary
    final classMap = <String, AdminClassSummary>{};
    for (final c in classes) {
      classMap[c.id] = c;
    }

    // Filter students
    final filteredStudents = students.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery) ||
          s.email.toLowerCase().contains(_searchQuery) ||
          (s.badge.isNotEmpty && s.badge.toLowerCase().contains(_searchQuery));
      return matchesSearch;
    }).toList();

    final totalCount = students.length;
    final assignedCount = students.where((s) => s.assignedClassId != null).length;
    final unassignedCount = totalCount - assignedCount;
    final verifiedCount = students.where((s) => s.verified).length;

    AdminStudent? inspectedStudent;
    if (_inspectedStudentId != null) {
      for (final s in students) {
        if (s.id == _inspectedStudentId) {
          inspectedStudent = s;
          break;
        }
      }
    }

    return WebAdminScaffold(
      activePath: '/admin/students',
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
                          context.tr('admin_students_breadcrumb_cat'),
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
                          context.tr('admin_students_breadcrumb_current'),
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
                      context.tr('admin_students_page_heading'),
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('admin_students_page_desc'),
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
                        ref.invalidate(adminClassesProvider);
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
            // 2. 4 METRIC CARDS (STUDENT SPECIFIC)
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_total_students'),
                    value: totalCount.toString(),
                    badgeText: context.tr('admin_kpi_badge_enrolled'),
                    badgeColor: const Color(0xFF6366F1),
                    icon: Icons.school_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_in_cohort'),
                    value: assignedCount.toString(),
                    badgeText: context.tr('admin_kpi_badge_assigned'),
                    badgeColor: const Color(0xFF10B981),
                    icon: Icons.groups_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_unassigned'),
                    value: unassignedCount.toString(),
                    badgeText: unassignedCount > 0 ? context.tr('admin_kpi_badge_to_assign') : context.tr('admin_kpi_badge_all_assigned'),
                    badgeColor: unassignedCount > 0
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                    icon: Icons.person_off_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_verified_accounts'),
                    value: verifiedCount.toString(),
                    badgeText: context.tr('admin_badge_email_verified'),
                    badgeColor: const Color(0xFF3B82F6),
                    icon: Icons.verified_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 3. SEARCH & CLASS FILTER
            // ==========================================
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                // Class filter dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 42,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedClassFilter,
                      dropdownColor: cardBg,
                      hint: Text(
                        context.tr('admin_dropdown_all_promos', args: {'count': classes.length.toString()}),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : AppTheme.onSurface,
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            context.tr('admin_dropdown_all_promos', args: {'count': classes.length.toString()}),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        ...classes.map((c) {
                          return DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(
                              '${c.title} • ${c.promoTag}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedClassFilter = val);
                      },
                    ),
                  ),
                ),

                // Search field
                SizedBox(
                  width: 340,
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
                      hintText: context.tr('admin_search_students_placeholder'),
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
            // 4. MAIN STUDENTS TABLE + INSPECTOR
            // ==========================================
            studentsAsync.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(60),
                      child: SmartLoader(size: SmartLoaderSize.medium),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Table
                      Expanded(
                        flex: inspectedStudent != null ? 7 : 10,
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
                                        context.tr('admin_col_student'),
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
                                        context.tr('admin_col_class_cohort'),
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
                                        context.tr('admin_col_account_status'),
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
                              if (filteredStudents.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.school_rounded,
                                          size: 48,
                                          color: isDark
                                              ? const Color(0xFF475569)
                                              : Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          context.tr('admin_no_students_found'),
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
                                  itemCount: filteredStudents.length,
                                  separatorBuilder: (_, _) =>
                                      Divider(height: 1, color: borderColor),
                                  itemBuilder: (context, index) {
                                    final student = filteredStudents[index];
                                    final isSelected =
                                        _selectedStudentIds.contains(student.id);
                                    final isInspected =
                                        _inspectedStudentId == student.id;
                                    final assignedClass =
                                        student.assignedClassId != null
                                            ? classMap[student.assignedClassId]
                                            : null;

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _inspectedStudentId = isInspected
                                              ? null
                                              : student.id;
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
                                                    _selectedStudentIds
                                                        .add(student.id);
                                                  } else {
                                                    _selectedStudentIds
                                                        .remove(student.id);
                                                  }
                                                });
                                              },
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // Avatar & Name & Email
                                            Expanded(
                                              flex: 4,
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 17,
                                                    backgroundColor: const Color(
                                                            0xFF3B82F6)
                                                        .withValues(alpha: 0.15),
                                                    child: Text(
                                                      student.initials ?? 'ET',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(0xFF3B82F6),
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
                                                          student.name,
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
                                                          student.email,
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

                                            // Class / Cohort
                                            Expanded(
                                              flex: 3,
                                              child: Row(
                                                children: [
                                                  if (assignedClass != null) ...[
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF6366F1)
                                                            .withValues(alpha: 0.12),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                6),
                                                      ),
                                                      child: Text(
                                                        assignedClass.title,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Color(0xFF6366F1),
                                                        ),
                                                      ),
                                                    ),
                                                  ] else ...[
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey
                                                            .withValues(alpha: 0.12),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                6),
                                                      ),
                                                      child: Text(
                                                        context.tr('admin_unassigned_badge'),
                                                        style: TextStyle(
                                                          fontSize: 11.5,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),

                                            // Verification status
                                            Expanded(
                                              flex: 2,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3.5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: student.verified
                                                          ? const Color(0xFF10B981)
                                                              .withValues(alpha: 0.12)
                                                          : const Color(0xFFF59E0B)
                                                              .withValues(alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      student.verified
                                                          ? context.tr('admin_badge_verified')
                                                          : context.tr('admin_badge_unverified'),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: student.verified
                                                            ? const Color(0xFF10B981)
                                                            : const Color(0xFFF59E0B),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Actions
                                            Expanded(
                                              flex: 3,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  // Assign / Change Class Button
                                                  Tooltip(
                                                    message: student.assignedClassId != null
                                                        ? context.tr('admin_tooltip_change_class')
                                                        : context.tr('admin_tooltip_assign_class'),
                                                    child: OutlinedButton.icon(
                                                      onPressed: () =>
                                                          _openAssignClassDialog(
                                                              student, classes),
                                                      icon: const Icon(
                                                        Icons.group_add_rounded,
                                                        size: 14,
                                                      ),
                                                      label: Text(
                                                        student.assignedClassId != null
                                                            ? context.tr('admin_btn_change')
                                                            : context.tr('admin_btn_assign'),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      style: OutlinedButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                        side: BorderSide(
                                                          color: isDark
                                                              ? const Color(0xFF3B82F6)
                                                                  .withValues(alpha: 0.5)
                                                              : const Color(0xFF3B82F6),
                                                        ),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),

                                                  // Remove from class if assigned
                                                  if (student.assignedClassId != null)
                                                    Tooltip(
                                                      message: context.tr('admin_tooltip_remove_class'),
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.remove_circle_outline_rounded,
                                                          size: 18,
                                                          color: Color(0xFFEF4444),
                                                        ),
                                                        onPressed: () =>
                                                            _removeFromClass(
                                                          student,
                                                          student.assignedClassId!,
                                                        ),
                                                      ),
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

                      // Side Inspector
                      if (inspectedStudent != null) ...[
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 3,
                          child: _buildInspector(
                            student: inspectedStudent,
                            assignedClass: inspectedStudent.assignedClassId != null
                                ? classMap[inspectedStudent.assignedClassId]
                                : null,
                            classes: classes,
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
    required AdminStudent student,
    required AdminClassSummary? assignedClass,
    required List<AdminClassSummary> classes,
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
                context.tr('admin_inspector_student_title'),
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
                onPressed: () => setState(() => _inspectedStudentId = null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor:
                      const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  child: Text(
                    student.initials ?? 'ET',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  student.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.onSurface,
                  ),
                ),
                Text(
                  student.email,
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
          _buildInspectorRow(
            context.tr('admin_inspector_current_class'),
            assignedClass != null ? assignedClass.title : context.tr('admin_unassigned_badge'),
            isDark,
          ),
          const SizedBox(height: 10),
          _buildInspectorRow(
            context.tr('admin_inspector_level_cycle'),
            assignedClass != null ? assignedClass.level.name.toUpperCase() : '—',
            isDark,
          ),
          const SizedBox(height: 10),
          _buildInspectorRow(
            context.tr('admin_badge_account_verified'),
            student.verified ? context.tr('yes') : context.tr('no'),
            isDark,
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('admin_inspector_cohort_assignment'),
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openAssignClassDialog(student, classes),
              icon: const Icon(Icons.school_rounded, size: 16),
              label: Text(
                student.assignedClassId != null
                    ? context.tr('admin_btn_transfer_class')
                    : context.tr('admin_btn_assign_class'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (student.assignedClassId != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _removeFromClass(student, student.assignedClassId!),
                icon: const Icon(
                  Icons.person_remove_rounded,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
                label: Text(
                  context.tr('admin_btn_remove_from_class'),
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
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

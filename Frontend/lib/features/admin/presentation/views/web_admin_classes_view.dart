import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/managed_class.dart';
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
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(adminClassSearchProvider);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref.read(adminClassSearchProvider.notifier).state = value.trim();
    });
  }

  Future<void> _confirmDelete(AdminClassSummary cls) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('admin_confirm_delete_title')),
        content: Text(
          context.tr('admin_confirm_delete_msg', args: {'name': cls.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(adminRepositoryProvider).deleteClass(cls.id);
      ref.invalidate(adminClassesProvider);
      ref.invalidate(adminOverviewProvider);
      if (mounted) {
        context.showSuccessToast(context.tr('admin_archive_done'));
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is Failure
          ? context.tr(failureL10n(e).key)
          : context.tr('something_went_wrong');
      context.showErrorToast(msg);
    }
  }

  String _levelName(ClassLevel level) {
    switch (level) {
      case ClassLevel.licence:
        return context.tr('admin_filter_licence');
      case ClassLevel.master:
        return context.tr('admin_filter_master');
      case ClassLevel.doctorat:
        return context.tr('admin_filter_doctorat');
    }
  }

  Color _levelColor(ClassLevel level) {
    switch (level) {
      case ClassLevel.licence:
        return const Color(0xFF2563EB);
      case ClassLevel.master:
        return const Color(0xFF7C3AED);
      case ClassLevel.doctorat:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classesAsync = ref.watch(adminClassesProvider);
    final overviewAsync = ref.watch(adminOverviewProvider);
    final levelFilter = ref.watch(adminClassLevelFilterProvider);

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

    final totalClasses = findStat('classes', '—');
    final totalStudents = findStat('students', '—');
    final totalTeachers = findStat('teachers', '—');

    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

    return WebAdminScaffold(
      activePath: 'classes',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // 1. TOP HEADER & BREADCRUMBS
            // ==========================================
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              spacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('admin_classes_breadcrumb_cat'),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      '  /  ',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF475569) : AppTheme.outlineVariant,
                      ),
                    ),
                    Text(
                      context.tr('admin_classes_breadcrumb_current'),
                      style: TextStyle(
                        color: isDark ? const Color(0xFFCBD5E1) : AppTheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle,
                          color: Color(0xFF10B981), size: 7),
                      const SizedBox(width: 6),
                      Text(
                        context.tr('admin_realtime_synced_data'),
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppTheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              runSpacing: 16,
              spacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('admin_classes_page_heading'),
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('admin_classes_page_desc'),
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
                      label: Text(context.tr('admin_create_class_button')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 2. METRIC CARDS (REAL DATA)
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_classes_promos'),
                    value: context.tr('admin_kpi_classes_count', args: {'count': totalClasses}),
                    badge: context.tr('admin_kpi_classes_badge'),
                    badgeColor: const Color(0xFF10B981),
                    icon: Icons.groups_3_rounded,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _buildMetricCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_students_enrollment'),
                    value: context.tr('admin_kpi_students_count', args: {'count': totalStudents}),
                    badge: context.tr('admin_kpi_students_badge'),
                    badgeColor: const Color(0xFF2563EB),
                    icon: Icons.how_to_reg_rounded,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _buildMetricCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_faculty'),
                    value: context.tr('admin_kpi_faculty_count', args: {'count': totalTeachers}),
                    badge: context.tr('admin_kpi_faculty_badge'),
                    badgeColor: const Color(0xFF7C3AED),
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
                // Live server-side search
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
                          onChanged: _onSearchChanged,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : AppTheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                context.tr('admin_search_classes_placeholder'),
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
                            _onSearchChanged('');
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

                // Level Filter
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ClassLevel?>(
                      value: levelFilter,
                      dropdownColor: cardBg,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.onSurface,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(context.tr('admin_level_filter_all')),
                        ),
                        DropdownMenuItem(
                          value: ClassLevel.licence,
                          child: Text(context.tr('admin_level_filter_prefix', args: {'level': _levelName(ClassLevel.licence)})),
                        ),
                        DropdownMenuItem(
                          value: ClassLevel.master,
                          child: Text(context.tr('admin_level_filter_prefix', args: {'level': _levelName(ClassLevel.master)})),
                        ),
                        DropdownMenuItem(
                          value: ClassLevel.doctorat,
                          child: Text(context.tr('admin_level_filter_prefix', args: {'level': _levelName(ClassLevel.doctorat)})),
                        ),
                      ],
                      onChanged: (lvl) {
                        ref.read(adminClassLevelFilterProvider.notifier).state =
                            lvl;
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 4. REAL CLASSES DATA TABLE
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: classesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: SmartLoader.medium()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 36, color: AppTheme.error),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('admin_unable_load_classes'),
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(adminClassesProvider),
                          child: Text(context.tr('retry')),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (classes) {
                  if (classes.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 48,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : AppTheme.outlineVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.tr('admin_no_classes_found'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr('admin_no_classes_hint'),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : AppTheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => context.go('/admin/classes/new'),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: Text(context.tr('admin_create_class_button')),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                              : const Color(0xFFF8FAFC),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          border: Border(bottom: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 4,
                              child: Text(
                                context.tr('admin_col_class_name'),
                                style: const TextStyle(
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
                                context.tr('admin_col_level_dept'),
                                style: const TextStyle(
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
                                context.tr('admin_col_headcount'),
                                style: const TextStyle(
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
                                context.tr('admin_col_faculty'),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                context.tr('admin_col_status'),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: Text(
                                context.tr('admin_col_actions'),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
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

                      // Data Rows
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: classes.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: borderColor,
                        ),
                        itemBuilder: (context, index) {
                          final cls = classes[index];
                          final isSelected = _selectedClassIds.contains(cls.id);
                          final pct = cls.students > 0
                              ? (cls.students / 40.0).clamp(0.0, 1.0)
                              : 0.0;
                          final lvlColor = _levelColor(cls.level);

                          return Container(
                            color: isSelected
                                ? const Color(0xFF2563EB).withValues(alpha: 0.06)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                // Checkbox
                                SizedBox(
                                  width: 32,
                                  child: Checkbox(
                                    value: isSelected,
                                    activeColor: const Color(0xFF2563EB),
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selectedClassIds.add(cls.id);
                                        } else {
                                          _selectedClassIds.remove(cls.id);
                                        }
                                      });
                                    },
                                  ),
                                ),

                                // Class Name & Badge
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: lvlColor.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          cls.level == ClassLevel.licence
                                              ? 'L3'
                                              : (cls.level == ClassLevel.master
                                                  ? 'M'
                                                  : 'D'),
                                          style: TextStyle(
                                            color: lvlColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
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
                                              cls.title,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppTheme.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              cls.promoTag,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? const Color(0xFF94A3B8)
                                                    : AppTheme.onSurfaceVariant,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Level & Department
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: lvlColor.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _levelName(cls.level).toUpperCase(),
                                          style: TextStyle(
                                            color: lvlColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        cls.promoTag.isEmpty
                                            ? context.tr('admin_unattached_promo')
                                            : cls.promoTag,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : AppTheme.onSurfaceVariant,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Students Headcount
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              context.tr('admin_students_count_label', args: {'count': cls.students.toString()}),
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppTheme.onSurface,
                                              ),
                                            ),
                                            Text(
                                              context.tr('admin_enrolled', args: {'enrolled': cls.students.toString(), 'capacity': cls.students.toString()}),
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            backgroundColor: isDark
                                                ? const Color(0xFF334155)
                                                : const Color(0xFFE2E8F0),
                                            valueColor: AlwaysStoppedAnimation(
                                                pct >= 1.0
                                                    ? const Color(0xFFEF4444)
                                                    : const Color(0xFF2563EB)),
                                            minHeight: 5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Teachers Count
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Icon(Icons.co_present_outlined,
                                          size: 16,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B)),
                                      const SizedBox(width: 6),
                                      Text(
                                        context.tr('admin_teachers_count_label', args: {'count': cls.teachers.toString()}),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Status Badge
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (cls.statusActive
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFF59E0B))
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          color: cls.statusActive
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFF59E0B),
                                          size: 6,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          cls.statusActive
                                              ? context.tr('admin_status_published')
                                              : context.tr('admin_status_draft'),
                                          style: TextStyle(
                                            color: cls.statusActive
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFF59E0B),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Actions menu & quick buttons
                                SizedBox(
                                  width: 140,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Manage Students icon
                                      IconButton(
                                        icon: const Icon(
                                            Icons.group_outlined,
                                            size: 18),
                                        tooltip: context.tr('admin_manage_students_tooltip'),
                                        onPressed: () => context.go(
                                            '/admin/classes/${cls.id}/students'),
                                      ),
                                      // Manage Teachers icon
                                      IconButton(
                                        icon: const Icon(
                                            Icons.person_add_alt_1_outlined,
                                            size: 18),
                                        tooltip: context.tr('admin_assign_teachers_tooltip'),
                                        onPressed: () => context.go(
                                            '/admin/classes/${cls.id}/teachers'),
                                      ),
                                      // Overflow menu (Edit, Delete)
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded,
                                            size: 18),
                                        onSelected: (action) {
                                          if (action == 'edit') {
                                            context.go(
                                              '/admin/classes/new',
                                              extra: cls.id,
                                            );
                                          } else if (action == 'delete') {
                                            _confirmDelete(cls);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.edit_outlined,
                                                    size: 16),
                                                const SizedBox(width: 8),
                                                Text(context.tr('admin_menu_edit')),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.delete_outline_rounded,
                                                    size: 16,
                                                    color: AppTheme.error),
                                                const SizedBox(width: 8),
                                                Text(context.tr('admin_menu_delete'),
                                                    style: const TextStyle(
                                                        color: AppTheme.error)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
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
    required String badge,
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
              badge,
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

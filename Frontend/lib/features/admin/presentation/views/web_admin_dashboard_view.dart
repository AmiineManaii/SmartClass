import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_overview.dart';
import '../../domain/entities/fraud_report.dart';
import '../../domain/entities/managed_class.dart';
import '../widgets/web_admin_scaffold.dart';

typedef WebAdminDashboardView = WebAdminDashboardPage;

class WebAdminDashboardPage extends ConsumerStatefulWidget {
  const WebAdminDashboardPage({super.key});

  @override
  ConsumerState<WebAdminDashboardPage> createState() =>
      _WebAdminDashboardPageState();
}

class _WebAdminDashboardPageState extends ConsumerState<WebAdminDashboardPage> {
  bool _filterUntreatedOnly = false;

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(adminOverviewProvider);
    final overview = overviewAsync.valueOrNull;

    final stats = overview?.stats;
    AdminStat? findStat(String id) {
      if (stats == null) return null;
      try {
        return stats.firstWhere((s) => s.id == id);
      } catch (_) {
        return null;
      }
    }

    final studentStat = findStat('students');
    final teacherStat = findStat('teachers');
    final groupStat = findStat('classes');
    final fraudStat = findStat('frauds');

    final totalStudents = studentStat?.value ?? '0';
    final newStudents = studentStat?.badgeArgs['count'] ?? '0';

    final totalTeachers = teacherStat?.value ?? '0';
    final teacherActivePct = teacherStat?.badgeArgs['pct'] ?? '0';

    final totalGroups = groupStat?.value ?? '0';
    final newGroups = groupStat?.badgeArgs['count'] ?? '0';

    final pendingFrauds = fraudStat?.value ?? '0';

    final fraudReportsAsync = ref.watch(adminFraudReportsProvider);
    final allFraudReports =
        fraudReportsAsync.valueOrNull?.reports ?? const <FraudReport>[];
    final displayedReports = _filterUntreatedOnly
        ? allFraudReports
            .where((r) => r.status == FraudStatus.untreated)
            .toList()
        : allFraudReports;

    final classesAsync = ref.watch(adminClassesProvider);
    final classes = classesAsync.valueOrNull ?? const <AdminClassSummary>[];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppTheme.onSurface;
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : AppTheme.onSurfaceVariant;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);
    final innerBg =
        isDark ? const Color(0xFF1E293B) : AppTheme.surfaceContainerLow;

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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle,
                                    color: AppTheme.primary, size: 7),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr('admin_supervision_badge'),
                                  style: const TextStyle(
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
                          Text(
                            context.tr('admin_winter_spring_session'),
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('admin_dashboard_title'),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('admin_dashboard_subtitle'),
                        style: TextStyle(
                          color: textSecondary,
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
                      onPressed: () {
                        ref.invalidate(adminOverviewProvider);
                        ref.invalidate(adminFraudReportsProvider);
                        ref.invalidate(adminClassesProvider);
                      },
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: Text(context.tr('admin_refresh_data')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        backgroundColor: cardBg,
                        side: BorderSide(color: borderColor),
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
                      onPressed: () => context.go('/admin/reports'),
                      icon: const Icon(Icons.analytics_outlined, size: 18),
                      label: Text(context.tr('admin_reports_audits')),
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
                    title: context.tr('admin_metric_headcount'),
                    value: totalStudents,
                    icon: Icons.school_rounded,
                    iconColor: AppTheme.primary,
                    iconBg: AppTheme.surfaceContainer,
                    footerWidget: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up_rounded,
                                color: AppTheme.success, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('admin_this_month_students', args: {'count': newStudents}),
                              style: const TextStyle(
                                color: AppTheme.success,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.tr('admin_real_time'),
                            style: const TextStyle(
                              color: AppTheme.success,
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

                // Card 2: Corps Enseignant
                Expanded(
                  child: _buildMetricCard(
                    title: context.tr('admin_metric_faculty'),
                    value: totalTeachers,
                    icon: Icons.assignment_ind_rounded,
                    iconColor: AppTheme.secondary,
                    iconBg: AppTheme.secondaryFixed.withValues(alpha: 0.4),
                    footerWidget: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          context.tr('admin_active_teachers_label'),
                          style: TextStyle(
                            color: textSecondary,
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
                          child: Text(
                            context.tr('admin_active_pct', args: {'pct': teacherActivePct}),
                            style: const TextStyle(
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
                    title: context.tr('admin_metric_groups'),
                    value: totalGroups,
                    icon: Icons.hub_rounded,
                    iconColor: AppTheme.secondary,
                    iconBg: AppTheme.surfaceContainer,
                    footerWidget: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          context.tr('admin_active_classes_label'),
                          style: TextStyle(
                            color: textSecondary,
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
                          child: Text(
                            context.tr('admin_created_count', args: {'count': newGroups}),
                            style: const TextStyle(
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
                      color: isDark
                          ? const Color(0xFF1E1522)
                          : const Color(0xFFFFF1F0),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: isDark ? 0.35 : 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : const Color(0x0A000000),
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
                            Expanded(
                              child: Text(
                                context.tr('admin_metric_integrity'),
                                style: const TextStyle(
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
                                color: isDark
                                    ? const Color(0xFF3B1219)
                                    : Colors.white,
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
                            Text(
                              context.tr('admin_pending_status'),
                              style: const TextStyle(
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
                            Text(
                              context.tr('admin_action_24h'),
                              style: const TextStyle(
                                color: AppTheme.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            InkWell(
                              onTap: () => context.go('/admin/frauds'),
                              child: Text(
                                context.tr('admin_handle_action'),
                                style: const TextStyle(
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
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : const Color(0x0A1D2338),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('admin_recent_fraud_incidents'),
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.tr('admin_biometric_surveillance'),
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: innerBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTabPill(
                                    context.tr('admin_filter_all_count', args: {'count': allFraudReports.length.toString()}),
                                    !_filterUntreatedOnly,
                                    () => setState(() => _filterUntreatedOnly = false),
                                  ),
                                  _buildTabPill(
                                    context.tr('admin_filter_untreated_count', args: {'count': pendingFrauds}),
                                    _filterUntreatedOnly,
                                    () => setState(() => _filterUntreatedOnly = true),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Incidents List / Table
                        if (displayedReports.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 36,
                              horizontal: 20,
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 44,
                                  color: AppTheme.success.withValues(alpha: 0.8),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _filterUntreatedOnly
                                      ? context.tr('admin_no_untreated_fraud')
                                      : context.tr('admin_no_fraud_recorded'),
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _filterUntreatedOnly
                                      ? context.tr('admin_all_reports_handled')
                                      : context.tr('admin_all_exams_compliant'),
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ...displayedReports.take(4).map((report) {
                            final initials = report.studentName.isNotEmpty
                                ? report.studentName
                                    .split(' ')
                                    .where((p) => p.isNotEmpty)
                                    .map((p) => p[0])
                                    .take(2)
                                    .join()
                                    .toUpperCase()
                                : 'ET';
                            final isCritical =
                                report.severity == FraudSeverity.critical;
                            final severityLabel = isCritical
                                ? context.tr('admin_severity_critical')
                                : context.tr('admin_severity_medium');
                            final severityColor = isCritical
                                ? AppTheme.error
                                : Colors.amber.shade800;
                            final code = [
                              if (report.studentId.isNotEmpty)
                                '#${report.studentId}',
                              if (report.studentClass.isNotEmpty)
                                report.studentClass,
                            ].join(' • ');

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildIncidentRow(
                                  initials: initials,
                                  avatarColor:
                                      AppTheme.primary.withValues(alpha: 0.12),
                                  avatarTextColor: AppTheme.primary,
                                  name: report.studentName.isNotEmpty
                                      ? report.studentName
                                      : context.tr('admin_student_fallback'),
                                  code: code.isNotEmpty
                                      ? code
                                      : context.tr('admin_exam_session'),
                                  exam: report.title.isNotEmpty
                                      ? report.title
                                      : context.tr('admin_evaluation_fallback'),
                                  examPeriod: report.subtitle.isNotEmpty
                                      ? report.subtitle
                                      : report.time,
                                  severity: severityLabel,
                                  severityColor: severityColor,
                                  diagnostic: report.findings.isNotEmpty
                                      ? report.findings.join(', ')
                                      : (report.reason ?? context.tr('admin_auto_ai_detection')),
                                  actionLabel:
                                      report.status == FraudStatus.untreated
                                          ? context.tr('admin_take_charge')
                                          : context.tr('admin_consult'),
                                  onAction: () => context.go('/admin/frauds'),
                                ),
                                Divider(
                                  height: 22,
                                  color: borderColor,
                                ),
                              ],
                            );
                          }),

                        const SizedBox(height: 12),

                        // Footer CTA
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              context.tr('admin_certified_ai_consensus'),
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            InkWell(
                              onTap: () => context.go('/admin/frauds'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.tr('admin_view_all_integrity_reports', args: {'count': allFraudReports.length.toString()}),
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF818CF8) : AppTheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded,
                                      color: isDark ? const Color(0xFF818CF8) : AppTheme.primary, size: 14),
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
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : const Color(0x0A1D2338),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('admin_recent_system_activity'),
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.tr('admin_active_cohorts_promos'),
                                  style: TextStyle(
                                    color: textSecondary,
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
                                color: innerBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                context.tr('admin_live_badge'),
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Real Classes / System Activity
                        if (classes.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                const Icon(Icons.school_outlined,
                                    size: 36, color: AppTheme.outline),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr('admin_no_cohort_configured'),
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...classes.take(3).map((cls) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildTimelineItem(
                                time: cls.promoTag,
                                title: cls.title,
                                subtitle: cls.referent.isNotEmpty
                                    ? context.tr('admin_referent_with_students', args: {
                                        'name': cls.referent,
                                        'count': cls.students.toString(),
                                      })
                                    : context.tr('admin_students_enrolled_count', args: {
                                        'count': cls.students.toString(),
                                      }),
                                statusLabel: cls.statusActive
                                    ? context.tr('admin_status_active')
                                    : context.tr('admin_status_draft'),
                                statusColor: cls.statusActive
                                    ? AppTheme.success
                                    : AppTheme.outline,
                                statusBg: (cls.statusActive
                                        ? AppTheme.success
                                        : AppTheme.outline)
                                    .withValues(alpha: 0.15),
                                isCurrent: cls.statusActive,
                              ),
                            );
                          }),

                        const SizedBox(height: 10),

                        // Status Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: innerBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.circle,
                                      color: AppTheme.success, size: 9),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('admin_services_db'),
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        context.tr('admin_live_sync'),
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  context.tr('admin_operational'),
                                  style: const TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded,
                              color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('admin_quick_actions_supervision'),
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        context.tr('admin_certified_shortcuts'),
                        style: TextStyle(
                          color: textSecondary,
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
                          label: Text(context.tr('admin_create_new_class_btn')),
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
                          onPressed: () => context.go('/admin/classes'),
                          icon: const Icon(Icons.school_outlined, size: 18),
                          label: Text(context.tr('admin_manage_classes_promos')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderColor),
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
                          label: Text(context.tr('admin_timetable_rooms')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderColor),
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
                          onPressed: () => context.go('/admin/frauds'),
                          icon: const Icon(Icons.shield_outlined,
                              color: AppTheme.error, size: 18),
                          label: Text(
                            context.tr('admin_surveillance_frauds'),
                            style: const TextStyle(color: AppTheme.error),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppTheme.onSurface;
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : AppTheme.onSurfaceVariant;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0x0A1D2338),
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textSecondary,
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
            style: TextStyle(
              color: textPrimary,
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

  Widget _buildTabPill(String title, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2563EB) : Colors.white)
              : Colors.transparent,
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
            color: isSelected
                ? (isDark ? Colors.white : AppTheme.primary)
                : (isDark
                    ? const Color(0xFF94A3B8)
                    : AppTheme.onSurfaceVariant),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.onSurface;
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : AppTheme.onSurfaceVariant;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE2E8F0);

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
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                code,
                style: TextStyle(
                  color: textSecondary,
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
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                examPeriod,
                style: TextStyle(
                  color: textSecondary,
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
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onAction,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? const Color(0xFF818CF8) : AppTheme.primary,
            side: BorderSide(color: borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            actionLabel,
            style: TextStyle(
              color: isDark ? const Color(0xFF818CF8) : AppTheme.primary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.onSurface;
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : AppTheme.onSurfaceVariant;

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
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: textSecondary,
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


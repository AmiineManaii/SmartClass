import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/fraud_report.dart';
import '../widgets/web_admin_scaffold.dart';

typedef WebAdminReportsView = WebAdminReportsPage;

class WebAdminReportsPage extends ConsumerStatefulWidget {
  const WebAdminReportsPage({super.key});

  @override
  ConsumerState<WebAdminReportsPage> createState() =>
      _WebAdminReportsPageState();
}

class _WebAdminReportsPageState extends ConsumerState<WebAdminReportsPage> {
  String? _selectedDossierId;
  String _activeFilter = 'all'; // 'all' | 'UNTREATED' | 'IN_PROGRESS' | 'CLOSED'
  final _decisionController = TextEditingController();
  bool _updating = false;

  @override
  void dispose() {
    _decisionController.dispose();
    super.dispose();
  }

  void _onFilterChanged(String filter) {
    setState(() => _activeFilter = filter);
    final status = filter == 'all' ? null : filter;
    ref.read(adminFraudReportsProvider.notifier).loadInitial(status: status);
  }

  Future<void> _updateStatus(FraudReport report, FraudStatus newStatus, {String? resolution}) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await ref.read(adminRepositoryProvider).updateFraudReport(
            report.id,
            status: newStatus,
            resolution: resolution,
          );
      ref.invalidate(adminFraudReportsProvider);
      ref.invalidate(adminFraudSummaryProvider);
      ref.invalidate(adminOverviewProvider);
      if (mounted) {
        context.showSuccessToast(context.tr('admin_toast_dossier_updated'));
      }
    } catch (_) {
      if (mounted) {
        context.showErrorToast(context.tr('admin_toast_dossier_update_fail'));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _showResolutionDialog(FraudReport report) {
    _decisionController.clear();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('admin_dialog_close_dossier_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('admin_dialog_dossier_of', args: {'name': report.studentName, 'title': report.title})),
            const SizedBox(height: 12),
            TextField(
              controller: _decisionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.tr('admin_dialog_decision_hint'),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _updateStatus(
                report,
                FraudStatus.closed,
                resolution: _decisionController.text.trim(),
              );
            },
            child: Text(context.tr('admin_btn_confirm_closure')),
          ),
        ],
      ),
    );
  }

  Color _severityColor(FraudSeverity s) {
    switch (s) {
      case FraudSeverity.critical:
        return const Color(0xFFEF4444);
      case FraudSeverity.medium:
        return const Color(0xFFF59E0B);
      case FraudSeverity.closed:
        return const Color(0xFF10B981);
    }
  }

  String _severityLabel(FraudSeverity s, BuildContext context) {
    switch (s) {
      case FraudSeverity.critical:
        return context.tr('admin_severity_critical');
      case FraudSeverity.medium:
        return context.tr('admin_severity_medium');
      case FraudSeverity.closed:
        return context.tr('admin_severity_closed');
    }
  }

  String _statusLabel(FraudStatus s, BuildContext context) {
    switch (s) {
      case FraudStatus.untreated:
        return context.tr('admin_status_untreated');
      case FraudStatus.ongoing:
        return context.tr('admin_status_in_progress');
      case FraudStatus.closed:
        return context.tr('admin_status_closed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

    final reportsAsync = ref.watch(adminFraudReportsProvider);
    final summaryAsync = ref.watch(adminFraudSummaryProvider);

    final reportsState = reportsAsync.valueOrNull;
    final reports = reportsState?.reports ?? const [];
    final summary = summaryAsync.valueOrNull;

    if (_selectedDossierId == null && reports.isNotEmpty) {
      _selectedDossierId = reports.first.id;
    }

    final selectedReport = reports.isNotEmpty
        ? reports.firstWhere(
            (r) => r.id == _selectedDossierId,
            orElse: () => reports.first,
          )
        : null;

    final unresolvedCount = summary?.unresolved ?? 0;
    final inProgressCount = summary?.inProgress ?? 0;
    final resolvedCount = summary?.resolvedThisMonth ?? 0;

    return WebAdminScaffold(
      activePath: 'rapports-de-fraude',
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
                    const Icon(Icons.shield_rounded,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'ESPACE ADMINISTRATION',
                      style: TextStyle(
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
                      context.tr('admin_reports_breadcrumb_current'),
                      style: TextStyle(
                        color: isDark ? const Color(0xFFCBD5E1) : AppTheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(adminFraudReportsProvider);
                    ref.invalidate(adminFraudSummaryProvider);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(context.tr('admin_refresh_button')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppTheme.primary,
                    backgroundColor: cardBg,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('admin_reports_heading'),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('admin_reports_sub'),
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : AppTheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 2. METRIC CARDS
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_untreated'),
                    value: '$unresolvedCount',
                    badge: context.tr('admin_kpi_badge_action_req'),
                    badgeColor: const Color(0xFFEF4444),
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _buildKpiCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_in_arbitration'),
                    value: '$inProgressCount',
                    badge: context.tr('admin_kpi_badge_instructing'),
                    badgeColor: const Color(0xFFF59E0B),
                    icon: Icons.pending_actions_rounded,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _buildKpiCard(
                    isDark: isDark,
                    title: context.tr('admin_kpi_resolved_this_month'),
                    value: '$resolvedCount',
                    badge: context.tr('admin_kpi_badge_closed'),
                    badgeColor: const Color(0xFF10B981),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==========================================
            // 3. FILTER TABS
            // ==========================================
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterTab(context.tr('admin_filter_all_alerts'), 'all', isDark),
                _buildFilterTab(context.tr('admin_filter_untreated_count', args: {'count': unresolvedCount.toString()}), 'UNTREATED', isDark),
                _buildFilterTab(context.tr('admin_filter_in_progress_count', args: {'count': inProgressCount.toString()}), 'IN_PROGRESS', isDark),
                _buildFilterTab(context.tr('admin_filter_closed_count', args: {'count': resolvedCount.toString()}), 'CLOSED', isDark),
              ],
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 4. MAIN SPLIT: REPORTS LIST & DETAILS
            // ==========================================
            reportsAsync.isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: SmartLoader.medium()),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // List of Reports (60%)
                      Expanded(
                        flex: 60,
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
                          child: reports.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 50, horizontal: 20),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.verified_user_rounded,
                                          size: 40,
                                          color: Color(0xFF10B981),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          context.tr('admin_no_fraud_reports'),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          context.tr('admin_all_exams_compliant'),
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
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: reports.length,
                                  separatorBuilder: (_, _) =>
                                      Divider(height: 1, color: borderColor),
                                  itemBuilder: (context, index) {
                                    final report = reports[index];
                                    final isSelected =
                                        _selectedDossierId == report.id;
                                    final sevColor =
                                        _severityColor(report.severity);

                                    return InkWell(
                                      onTap: () => setState(
                                          () => _selectedDossierId = report.id),
                                      child: Container(
                                        color: isSelected
                                            ? (isDark
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFFEEF2FF))
                                            : Colors.transparent,
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: sevColor.withValues(
                                                    alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                Icons.warning_rounded,
                                                color: sevColor,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        report.studentName,
                                                        style: TextStyle(
                                                          fontSize: 13.5,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isDark
                                                              ? Colors.white
                                                              : AppTheme
                                                                  .onSurface,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '• ${report.time}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${report.title} — ${report.subtitle}',
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
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: sevColor.withValues(
                                                    alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _severityLabel(report.severity, context)
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: sevColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Inspector Panel (40%)
                      Expanded(
                        flex: 40,
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
                          child: selectedReport == null
                              ? Center(
                                  child: Text(context.tr('admin_select_an_alert')),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.assignment_late_outlined,
                                          color: _severityColor(
                                              selectedReport.severity),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            selectedReport.studentName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppTheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Divider(color: borderColor),
                                    const SizedBox(height: 12),
                                    _buildDetailRow(
                                        context.tr('admin_col_exam'), selectedReport.title, isDark),
                                    const SizedBox(height: 10),
                                    _buildDetailRow(context.tr('admin_col_class'),
                                        selectedReport.studentClass, isDark),
                                    const SizedBox(height: 10),
                                    _buildDetailRow(context.tr('admin_col_status'),
                                        _statusLabel(selectedReport.status, context), isDark),
                                    const SizedBox(height: 10),
                                    _buildDetailRow(context.tr('admin_col_severity'),
                                        _severityLabel(selectedReport.severity, context), isDark),
                                    const SizedBox(height: 16),

                                    if (selectedReport.findings.isNotEmpty) ...[
                                      Text(
                                        context.tr('admin_findings_detected'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...selectedReport.findings.map(
                                        (f) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.circle,
                                                size: 5,
                                                color: Color(0xFFEF4444),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  f,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark
                                                        ? const Color(0xFFCBD5E1)
                                                        : AppTheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    if (selectedReport.resolution != null &&
                                        selectedReport.resolution!.isNotEmpty) ...[
                                      Text(
                                        context.tr('admin_resolution_administrative'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          selectedReport.resolution!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? const Color(0xFFCBD5E1)
                                                : AppTheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // Action buttons
                                    if (selectedReport.status != FraudStatus.closed) ...[
                                      Row(
                                        children: [
                                          if (selectedReport.status == FraudStatus.untreated)
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: _updating
                                                    ? null
                                                    : () => _updateStatus(
                                                          selectedReport,
                                                          FraudStatus.ongoing,
                                                        ),
                                                child: Text(context.tr('admin_btn_take_charge')),
                                              ),
                                            ),
                                          if (selectedReport.status == FraudStatus.untreated)
                                            const SizedBox(width: 10),
                                          Expanded(
                                            child: FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF10B981),
                                              ),
                                              onPressed: _updating
                                                  ? null
                                                  : () => _showResolutionDialog(
                                                      selectedReport),
                                              child: Text(context.tr('admin_btn_close_case')),
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

  Widget _buildDetailRow(String label, String value, bool isDark) {
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

  Widget _buildFilterTab(String label, String tabKey, bool isDark) {
    final isSelected = _activeFilter == tabKey;
    return InkWell(
      onTap: () => _onFilterChanged(tabKey),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
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
    required String badge,
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

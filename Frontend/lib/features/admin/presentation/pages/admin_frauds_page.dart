import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/fraud_report.dart';
import '../widgets/admin_filter_chips.dart';

class AdminFraudsPage extends ConsumerStatefulWidget {
  const AdminFraudsPage({super.key});

  @override
  ConsumerState<AdminFraudsPage> createState() => _AdminFraudsPageState();
}

class _AdminFraudsPageState extends ConsumerState<AdminFraudsPage> {
  String _filter = 'all';

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('feature_coming_soon')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summaryAsync = ref.watch(adminFraudSummaryProvider);
    final reportsAsync = ref.watch(adminFraudReportsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('admin_fraud_title'),
              style: theme.textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              context.tr('admin_fraud_sub'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.ios_share_outlined), onPressed: _comingSoon),
          IconButton(
            icon: Badge(
              smallSize: 8,
              backgroundColor: colorScheme.error,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: _comingSoon,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              child: Icon(Icons.person_rounded, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminFraudSummaryProvider);
            ref.invalidate(adminFraudReportsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: context.screenWidth >= 600 ? 32 : 20,
              vertical: 8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    summaryAsync.when(
                      data: (summary) => _StatusCard(summary: summary),
                      loading: () => const SizedBox(height: 120),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    reportsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Text(
                              context.tr('something_went_wrong'),
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  ref.invalidate(adminFraudReportsProvider),
                              child: Text(context.tr('retry')),
                            ),
                          ],
                        ),
                      ),
                      data: (reports) =>
                          _ReportsBody(reports: reports, onAction: _comingSoon),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _comingSoon,
                      icon: const Icon(Icons.download_outlined, size: 20),
                      label: Text(context.tr('admin_export_audit')),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: theme.textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.tr('admin_compliance'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final FraudSummary summary;

  const _StatusCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget stat(String value, Color valueColor, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(color: valueColor),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('admin_antifraud_on'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  context.tr('admin_ai_watch'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                stat(
                  '${summary.unresolved}'.padLeft(2, '0'),
                  colorScheme.error,
                  context.tr('admin_unresolved'),
                ),
                stat(
                  '${summary.resolvedThisMonth}',
                  colorScheme.secondary,
                  context.tr('admin_resolved_month'),
                ),
                stat(
                  '${summary.integrityPct}%',
                  colorScheme.tertiary,
                  context.tr('admin_integrity'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsBody extends StatefulWidget {
  final List<FraudReport> reports;
  final VoidCallback onAction;

  const _ReportsBody({required this.reports, required this.onAction});

  @override
  State<_ReportsBody> createState() => _ReportsBodyState();
}

class _ReportsBodyState extends State<_ReportsBody> {
  String _filter = 'all';

  List<FraudReport> get _filtered {
    switch (_filter) {
      case 'untreated':
        return widget.reports
            .where((r) => r.status == FraudStatus.untreated)
            .toList();
      case 'ongoing':
        return widget.reports
            .where((r) => r.status == FraudStatus.ongoing)
            .toList();
      case 'closed':
        return widget.reports
            .where((r) => r.status == FraudStatus.closed)
            .toList();
      case 'all':
      default:
        return widget.reports;
    }
  }

  int _count(FraudStatus status) =>
      widget.reports.where((r) => r.status == status).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminFilterChips<String>(
          options: [
            AdminFilterOption(
              value: 'all',
              label: context.tr('admin_all_count',
                  args: {'count': '${widget.reports.length}'}),
            ),
            AdminFilterOption(
              value: 'untreated',
              label: context.tr('admin_unresolved_f',
                  args: {'count': '${_count(FraudStatus.untreated)}'}),
            ),
            AdminFilterOption(
              value: 'ongoing',
              label: context.tr('admin_ongoing',
                  args: {'count': '${_count(FraudStatus.ongoing)}'}),
            ),
            AdminFilterOption(
              value: 'closed',
              label: context.tr('admin_resolved_f',
                  args: {'count': '${_count(FraudStatus.closed)}'}),
            ),
          ],
          selected: _filter,
          onSelected: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              context.tr('empty_state'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          )
        else
          for (int i = 0; i < filtered.length; i++) ...[
            _FraudCard(report: filtered[i], onAction: widget.onAction),
            if (i < filtered.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _FraudCard extends StatelessWidget {
  final FraudReport report;
  final VoidCallback onAction;

  const _FraudCard({required this.report, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = switch (report.severity) {
      FraudSeverity.critical => colorScheme.error,
      FraudSeverity.medium => colorScheme.secondary,
      FraudSeverity.closed => colorScheme.tertiary,
    };

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accent, width: 4),
          top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          right: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _SeverityPill(report: report)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_outlined,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      report.time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(report.title, style: theme.textTheme.headlineSmall),
            Text(
              report.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryFixed,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.person_rounded,
                      size: 18, color: colorScheme.onSecondaryFixed),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${report.studentName}  ${report.studentId}',
                        style: theme.textTheme.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        report.studentClass,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (report.findings.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (int i = 0; i < report.findings.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        i == 0
                            ? Icons.content_paste_off_outlined
                            : Icons.videocam_outlined,
                        size: 16,
                        color: report.severity == FraudSeverity.critical
                            ? colorScheme.error
                            : colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          report.findings[i],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: report.severity == FraudSeverity.critical
                                ? colorScheme.error
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (report.reason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: theme.textTheme.bodySmall,
                        children: [
                          TextSpan(
                            text: '${context.tr('admin_reason')} ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: report.reason),
                        ],
                      ),
                    ),
                    if (report.resolution != null) ...[
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          style: theme.textTheme.bodySmall,
                          children: [
                            TextSpan(
                              text: '${context.tr('admin_resolution')} ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.tertiary,
                              ),
                            ),
                            TextSpan(text: report.resolution),
                          ],
                        ),
                      ),
                    ],
                    if (report.closedDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        report.closedDate!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _CardActions(report: report, onAction: onAction),
          ],
        ),
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  final FraudReport report;

  const _SeverityPill({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (IconData icon, String labelKey, Color bg, Color fg) = switch (report.severity) {
      FraudSeverity.critical => (
          Icons.warning_amber_rounded,
          'admin_critical',
          colorScheme.errorContainer,
          colorScheme.onErrorContainer
        ),
      FraudSeverity.medium => (
          Icons.devices_outlined,
          'admin_medium',
          colorScheme.secondaryFixed,
          colorScheme.onSecondaryFixed
        ),
      FraudSeverity.closed => (
          Icons.check_circle_outline_rounded,
          'admin_closed',
          colorScheme.surfaceContainerHigh,
          colorScheme.onSurfaceVariant
        ),
    };
    final statusKey = switch (report.status) {
      FraudStatus.untreated => 'admin_status_untreated',
      FraudStatus.ongoing => 'admin_status_ongoing',
      FraudStatus.closed => 'admin_closed',
    };

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
              Text(
                '${context.tr(labelKey)} • ${context.tr(statusKey)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardActions extends StatelessWidget {
  final FraudReport report;
  final VoidCallback onAction;

  const _CardActions({required this.report, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (report.severity) {
      case FraudSeverity.critical:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                label: Text(context.tr('admin_view_video')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: theme.textTheme.labelMedium,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.gavel_outlined, size: 18),
                label: Text(context.tr('admin_sanction')),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: theme.textTheme.labelMedium,
                ),
              ),
            ),
          ],
        );
      case FraudSeverity.medium:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: Text(context.tr('admin_network_logs')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: theme.textTheme.labelMedium,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.mail_outline_rounded, size: 18),
                label: Text(context.tr('admin_summon')),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: theme.textTheme.labelMedium,
                ),
              ),
            ),
          ],
        );
      case FraudSeverity.closed:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: onAction,
            icon: const Icon(Icons.verified_outlined, size: 18),
            label: Text(context.tr('admin_audit_history')),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: theme.textTheme.labelMedium,
            ),
          ),
        );
    }
  }
}

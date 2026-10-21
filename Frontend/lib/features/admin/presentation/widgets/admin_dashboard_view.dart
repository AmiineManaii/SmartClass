import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_overview.dart';
import 'admin_nav_row.dart';
import 'admin_section_header.dart';
import 'admin_stat_card.dart';
import '../views/web_admin_dashboard_view.dart';
import '../../../../core/widgets/smart_loader.dart';

/// Locally dismissed alert ids (no backend status endpoint yet).
final dismissedAdminAlertsProvider = StateProvider<Set<String>>((ref) => {});

class AdminDashboardView extends ConsumerWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (context.isDesktop) {
      return const WebAdminDashboardPage();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authStateProvider).valueOrNull;
    final overview = ref.watch(adminOverviewProvider);
    final dismissed = ref.watch(dismissedAdminAlertsProvider);

    // REAL identity from the authenticated session (GET /api/v1/auth/me).
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : context.tr('role_admin');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminOverviewProvider),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('admin_supervision').toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.06,
                                ),
                              ),
                              Text(
                                context.tr('admin_greeting', args: {'name': name}),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 22,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    overview.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: SmartLoader.medium(
                            message: 'Chargement des statistiques administrateur...',
                          ),
                        ),
                      ),
                      error: (e, _) => _OverviewError(
                        onRetry: () => ref.invalidate(adminOverviewProvider),
                      ),
                      data: (data) => _DashboardBody(
                        overview: data,
                        dismissed: dismissed,
                        onDismiss: (id) {
                          ref.read(dismissedAdminAlertsProvider.notifier).state = {
                            ...ref.read(dismissedAdminAlertsProvider),
                            id,
                          };
                        },
                      ),
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

class _OverviewError extends StatelessWidget {
  final VoidCallback onRetry;

  const _OverviewError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          context.tr('something_went_wrong'),
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(context.tr('retry')),
        ),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final AdminOverview overview;
  final Set<String> dismissed;
  final ValueChanged<String> onDismiss;

  const _DashboardBody({
    required this.overview,
    required this.dismissed,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final visibleAlerts =
        overview.alerts.where((a) => !dismissed.contains(a.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemCount: overview.stats.length,
          itemBuilder: (context, i) {
            final stat = overview.stats[i];
            return InkWell(
              onTap: stat.id == 'frauds' ? () => context.push('/admin/frauds') : null,
              borderRadius: BorderRadius.circular(16),
              child: AdminStatCard(stat: stat),
            );
          },
        ),
        const SizedBox(height: 24),
        AdminSectionHeader(
          titleKey: 'admin_shortcuts_title',
          subtitleKey: 'admin_shortcuts_sub',
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < overview.shortcuts.length; i++) ...[
          Builder(builder: (context) {
            final s = overview.shortcuts[i];
            return AdminNavRow(
              icon: s.icon,
              titleKey: s.titleKey,
              descKey: s.descKey,
              onTap: () => context.push(s.route),
            );
          }),
          if (i < overview.shortcuts.length - 1) const SizedBox(height: 10),
        ],
        const SizedBox(height: 24),
        AdminSectionHeader(
          titleKey: 'admin_alerts_title',
          actionKey: 'admin_view_all',
          actionArgs: {'count': visibleAlerts.length.toString()},
          onAction: () => context.push('/admin/frauds'),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < visibleAlerts.length; i++) ...[
          _AlertCard(
            alert: visibleAlerts[i],
            onDismiss: () => onDismiss(visibleAlerts[i].id),
          ),
          if (i < visibleAlerts.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AdminAlert alert;
  final VoidCallback onDismiss;

  const _AlertCard({required this.alert, required this.onDismiss});

  Color _chipBg(BuildContext context, AdminStatTone tone) {
    final colors = Theme.of(context).colorScheme;
    return switch (tone) {
      AdminStatTone.error => colors.errorContainer,
      AdminStatTone.success => colors.tertiaryContainer,
      AdminStatTone.warning => colors.tertiaryFixed,
      AdminStatTone.info => colors.surfaceContainer,
    };
  }

  Color _chipFg(BuildContext context, AdminStatTone tone) {
    final colors = Theme.of(context).colorScheme;
    return switch (tone) {
      AdminStatTone.error => colors.onErrorContainer,
      AdminStatTone.success => colors.onTertiaryContainer,
      AdminStatTone.warning => colors.onTertiaryFixed,
      AdminStatTone.info => colors.secondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  adminIconFromName(alert.icon),
                  size: 22,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      alert.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (alert.meta != null)
                Text(
                  alert.meta!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (alert.chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final chip in alert.chips)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _chipBg(context, chip.tone),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      chip.text,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _chipFg(context, chip.tone),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.push('/admin/frauds'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                  child: Text(context.tr(alert.primaryActionKey)),
                ),
              ),
              if (alert.secondaryActionKey != null) ...[
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: onDismiss,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                  child: Text(context.tr(alert.secondaryActionKey!)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

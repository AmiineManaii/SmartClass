import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/managed_class.dart';
import '../widgets/admin_filter_chips.dart';
import '../widgets/admin_search_field.dart';
import '../views/web_admin_classes_view.dart';

class AdminClassesPage extends ConsumerStatefulWidget {
  const AdminClassesPage({super.key});

  @override
  ConsumerState<AdminClassesPage> createState() => _AdminClassesPageState();
}

class _AdminClassesPageState extends ConsumerState<AdminClassesPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _sortByStudents = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ref.read(adminClassSearchProvider.notifier).state = value.trim();
    });
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('feature_coming_soon')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFailure(Object error) {
    final message = error is Failure
        ? context.tr(failureL10n(error).key)
        : context.tr('something_went_wrong');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmArchive(AdminClassSummary cls) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('admin_archive_title')),
        content: Text(
          context.tr('admin_archive_message', args: {'name': cls.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('admin_archive_action')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(adminRepositoryProvider).deleteClass(cls.id);
    } catch (e) {
      if (!mounted) return;
      _showFailure(e);
      return;
    }
    ref.invalidate(adminClassesProvider);
    ref.invalidate(adminOverviewProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('admin_archive_done')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openClassMenu(AdminClassSummary cls) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;

        Widget action(IconData icon, String labelKey, VoidCallback onTap) {
          return ListTile(
            leading: Icon(icon, color: colorScheme.primary),
            title: Text(
              sheetContext.tr(labelKey),
              style: theme.textTheme.bodyMedium,
            ),
            onTap: () {
              Navigator.of(sheetContext).pop();
              onTap();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  cls.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              action(
                Icons.analytics_outlined,
                'admin_view_details',
                () => context.push('/groups/${cls.id}', extra: cls.title),
              ),
              action(
                Icons.edit_outlined,
                'admin_edit_class_file',
                () => context.push('/admin/classes/new', extra: cls.id),
              ),
              action(
                Icons.calendar_month_outlined,
                'admin_view_timetable',
                () {
                  ref.read(adminPlanningClassProvider.notifier).state = cls.id;
                  context.push('/admin/planning');
                },
              ),
              action(Icons.mail_outline, 'admin_send_notice', _showComingSoon),
              action(
                Icons.archive_outlined,
                'admin_archive_cohort',
                () => _confirmArchive(cls),
              ),
              action(Icons.close_rounded, 'close', () {}),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return const WebAdminClassesPage();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final classesAsync = ref.watch(adminClassesProvider);
    final levelFilter = ref.watch(adminClassLevelFilterProvider);

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
              'SMARTCLASS ADMIN',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.secondary,
                letterSpacing: 0.06,
              ),
            ),
            Text(
              context.tr('admin_classes_title'),
              style: theme.textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
            tooltip: context.tr('filter'),
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
          onRefresh: () async => ref.invalidate(adminClassesProvider),
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
                    Text(
                      context.tr('admin_classes_sub'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AdminSearchField(
                      controller: _searchController,
                      hint: context.tr('admin_search_class_hint'),
                      onChanged: _onSearchChanged,
                      onFilterTap: () {},
                    ),
                    const SizedBox(height: 12),
                    AdminFilterChips<ClassLevel?>(
                      options: [
                        AdminFilterOption(value: null, label: context.tr('all')),
                        AdminFilterOption(
                          value: ClassLevel.licence,
                          label: context.tr('admin_filter_licence'),
                        ),
                        AdminFilterOption(
                          value: ClassLevel.master,
                          label: context.tr('admin_filter_master'),
                        ),
                        AdminFilterOption(
                          value: ClassLevel.doctorat,
                          label: context.tr('admin_filter_doctorat'),
                        ),
                      ],
                      selected: levelFilter,
                      onSelected: (v) => ref
                          .read(adminClassLevelFilterProvider.notifier)
                          .state = v,
                    ),
                    const SizedBox(height: 16),
                    classesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => _ListError(
                        onRetry: () => ref.invalidate(adminClassesProvider),
                      ),
                      data: (classes) => _ClassesBody(
                        classes: _applyFilter(classes),
                        sortByStudents: _sortByStudents,
                        onToggleSort: () =>
                            setState(() => _sortByStudents = !_sortByStudents),
                        onMenu: _openClassMenu,
                        onOpen: (id) => context.push('/groups/$id'),
                      ),
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/classes/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('admin_new_class')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Server already filters by level/search; only the manual sort
  /// toggle applies client-side on real data.
  List<AdminClassSummary> _applyFilter(List<AdminClassSummary> classes) {
    if (!_sortByStudents) return classes;
    return [...classes]..sort((a, b) => b.students.compareTo(a.students));
  }
}

class _ListError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ListError({required this.onRetry});

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

class _ClassesBody extends StatelessWidget {
  final List<AdminClassSummary> classes;
  final bool sortByStudents;
  final VoidCallback onToggleSort;
  final ValueChanged<AdminClassSummary> onMenu;
  final ValueChanged<String> onOpen;

  const _ClassesBody({
    required this.classes,
    required this.sortByStudents,
    required this.onToggleSort,
    required this.onMenu,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalStudents = classes.fold<int>(0, (sum, c) => sum + c.students);
    final totalTeachers = classes.fold<int>(0, (sum, c) => sum + c.teachers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                icon: Icons.groups_outlined,
                value: classes.length.toString(),
                label: context.tr('admin_stat_cohorts'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                icon: Icons.school_outlined,
                value: '$totalStudents',
                label: context.tr('admin_stat_students'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                icon: Icons.badge_outlined,
                value: '$totalTeachers',
                label: context.tr('admin_stat_teachers'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('admin_active_promos').toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.04,
              ),
            ),
            TextButton(
              onPressed: onToggleSort,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                context.tr('admin_sort_by'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (classes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              context.tr('empty_state'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          for (int i = 0; i < classes.length; i++) ...[
            _AdminClassCard(
              cls: classes[i],
              onMenu: () => onMenu(classes[i]),
              onOpen: () => onOpen(classes[i].id),
            ),
            if (i < classes.length - 1) const SizedBox(height: 12),
          ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.sync_rounded, size: 18, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr(
                    'admin_sync_ent',
                    args: {'ago': context.tr('admin_sync_ago')},
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AdminClassCard extends StatelessWidget {
  final AdminClassSummary cls;
  final VoidCallback onMenu;
  final VoidCallback onOpen;

  const _AdminClassCard({
    required this.cls,
    required this.onMenu,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          cls.promoTag,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                      if (cls.statusKey != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cls.statusActive
                                ? colorScheme.tertiaryFixed
                                : colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: cls.statusActive
                                      ? colorScheme.tertiary
                                      : colorScheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.tr(cls.statusKey!),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cls.statusActive
                                      ? colorScheme.onTertiaryFixed
                                      : colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: colorScheme.onSurfaceVariant,
                  onPressed: onMenu,
                ),
              ],
            ),
            Text(
              cls.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _Meta(icon: Icons.person_outline, text: context.tr('admin_students_count', args: {'count': cls.students.toString()})),
                _Meta(icon: Icons.school_outlined, text: context.tr('admin_teachers_count', args: {'count': cls.teachers.toString()})),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Pill(
                  icon: Icons.account_circle_outlined,
                  text: cls.referent.isNotEmpty
                      ? cls.referent
                      : context.tr('admin_no_referent'),
                ),
                for (final chip in cls.extraChips) _Pill(icon: Icons.label_outline, text: chip),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.secondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.secondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

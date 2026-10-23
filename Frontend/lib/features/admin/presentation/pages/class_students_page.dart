import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_person.dart';
import '../widgets/admin_filter_chips.dart';
import '../widgets/admin_person_avatar.dart';
import '../widgets/admin_search_field.dart';

class ClassStudentsPage extends ConsumerStatefulWidget {
  final String classId;

  const ClassStudentsPage({required this.classId, super.key});

  @override
  ConsumerState<ClassStudentsPage> createState() => _ClassStudentsPageState();
}

class _ClassStudentsPageState extends ConsumerState<ClassStudentsPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _filter = 'all';
  final Set<String> _selected = {};

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
      ref.read(adminPersonSearchProvider.notifier).state = value.trim();
    });
  }

  void _showFailure(Object error) {
    final message = error is Failure
        ? context.tr(failureL10n(error).key)
        : context.tr('something_went_wrong');
    context.showErrorToast(message);
  }

  void _showComingSoon() {
    context.showInfoToast(context.tr('feature_coming_soon'));
  }

  Future<void> _assign() async {
    if (_selected.isEmpty) return;
    // Safety net: only unassigned students can be (re)assigned — assigned
    // rows offer no assign option, so this is normally already the case.
    final students = ref.read(adminStudentsProvider(widget.classId)).valueOrNull ?? [];
    final allowed = students
        .where((s) => s.assignedClassId == null)
        .map((s) => s.id)
        .toSet();
    final ids = _selected.where(allowed.contains).toList();
    if (ids.isEmpty) return;
    final count = ids.length;
    try {
      await ref.read(adminRepositoryProvider).assignStudents(
            widget.classId,
            ids,
          );
    } catch (e) {
      if (!mounted) return;
      _showFailure(e);
      return;
    }
    ref.invalidate(adminStudentsProvider(widget.classId));
    ref.invalidate(adminClassDetailProvider(widget.classId));
    ref.invalidate(adminOverviewProvider);
    if (!mounted) return;
    context.showSuccessToast(
      context.tr('admin_selected_count', args: {'count': '$count'}),
    );
    context.pop();
  }

  Future<void> _unassign(String studentId, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('admin_unassign_title')),
        content: Text(
          context.tr('admin_unassign_message', args: {'name': studentName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('admin_unassign_action')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .removeStudents(widget.classId, [studentId]);
    } catch (e) {
      if (!mounted) return;
      _showFailure(e);
      return;
    }
    setState(() => _selected.remove(studentId));
    ref.invalidate(adminStudentsProvider(widget.classId));
    ref.invalidate(adminClassDetailProvider(widget.classId));
    ref.invalidate(adminOverviewProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final studentsAsync = ref.watch(adminStudentsProvider(widget.classId));
    final detailAsync = ref.watch(adminClassDetailProvider(widget.classId));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: context.isDesktop
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('admin_add_students'),
                    style: theme.textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  detailAsync.when(
                    data: (detail) => Text(
                      detail?.title ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.upload_file_outlined),
                  tooltip: context.tr('admin_import_csv'),
                  onPressed: _showComingSoon,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.isDesktop
                      ? 36
                      : (context.screenWidth >= 600 ? 32 : 20),
                  vertical: context.isDesktop ? 24 : 8,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: context.isDesktop ? 860 : 640,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (context.isDesktop) ...[
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded,
                                    size: 20),
                                onPressed: () => context.go('/admin/classes'),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => context.go('/admin/classes'),
                                child: Text(
                                  context.tr('admin_nav_classes'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ),
                              Text(
                                '  /  ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                              detailAsync.when(
                                data: (detail) => Text(
                                  detail?.title ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, _) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('admin_add_students'),
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  detailAsync.when(
                                    data: (detail) => Text(
                                      context.tr('admin_assign_students_desc', args: {'title': detail?.title ?? ''}),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, _) => const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed: _showComingSoon,
                                icon: const Icon(Icons.upload_file_outlined,
                                    size: 18),
                                label: Text(context.tr('admin_import_csv')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                        detailAsync.when(
                          data: (detail) => detail == null
                              ? const SizedBox(height: 24)
                              : _ClassCapacityCard(
                                  title: detail.title,
                                  enrolled: detail.students,
                                  capacity: detail.capacity,
                                ),
                          loading: () => const SizedBox(height: 120),
                          error: (_, _) => const SizedBox(height: 24),
                        ),
                        const SizedBox(height: 16),
                        AdminSearchField(
                          controller: _searchController,
                          hint: context.tr('admin_search_person_hint'),
                          onChanged: _onSearchChanged,
                          onFilterTap: () {},
                        ),
                        const SizedBox(height: 12),
                        studentsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, _) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              context.tr('something_went_wrong'),
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          data: (students) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AdminFilterChips<String>(
                                  options: [
                                    AdminFilterOption(
                                      value: 'all',
                                      label: context.tr('admin_all_count',
                                          args: {'count': '${students.length}'}),
                                    ),
                                    AdminFilterOption(
                                      value: 'unassigned',
                                      label: context.tr('admin_unassigned', args: {
                                        'count':
                                            '${students.where((s) => s.assignedClassId == null).length}'
                                      }),
                                    ),
                                  ],
                                  selected: _filter,
                                  onSelected: (v) => setState(() => _filter = v),
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
                        ),
                        studentsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (students) {
                            final filtered = _applyFilter(students);
                            return _StudentsBody(
                              students: filtered,
                              selectedIds: _selected,
                              onToggleAll: () => setState(() {
                                // Already-assigned students offer no assign
                                // option: select-all only takes unassigned ones.
                                final all = filtered
                                    .where((s) => s.assignedClassId == null)
                                    .map((s) => s.id)
                                    .toSet();
                                if (_selected.length == all.length &&
                                    all.isNotEmpty) {
                                  _selected.clear();
                                } else {
                                  _selected
                                    ..clear()
                                    ..addAll(all);
                                }
                              }),
                              onToggle: (id) => setState(() {
                                if (!_selected.remove(id)) {
                                  _selected.add(id);
                                }
                              }),
                              onUnassign: (student) =>
                                  _unassign(student.id, student.name),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _BottomAssignBar(
              selectedCount: _selected.length,
              onAssign: _assign,
              onCancel: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  /// Server already searches; only the assigned/unassigned chip
  /// filters client-side on real membership.
  List<AdminStudent> _applyFilter(List<AdminStudent> students) {
    if (_filter == 'unassigned') {
      return students.where((s) => s.assignedClassId == null).toList();
    }
    return students;
  }
}

class _ClassCapacityCard extends StatelessWidget {
  final String title;
  final int enrolled;
  final int capacity;

  const _ClassCapacityCard({
    required this.title,
    required this.enrolled,
    required this.capacity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final left = capacity - enrolled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('admin_direct_assign'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryFixed,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  context.tr('admin_places_left', args: {'count': '$left'}),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryFixed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: enrolled / capacity,
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('admin_enrolled', args: {
                  'enrolled': '$enrolled',
                  'capacity': '$capacity',
                }),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentsBody extends StatelessWidget {
  final List<AdminStudent> students;
  final Set<String> selectedIds;
  final VoidCallback onToggleAll;
  final ValueChanged<String> onToggle;
  final ValueChanged<AdminStudent> onUnassign;

  const _StudentsBody({
    required this.students,
    required this.selectedIds,
    required this.onToggleAll,
    required this.onToggle,
    required this.onUnassign,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: onToggleAll,
              icon: const Icon(Icons.select_all_rounded, size: 18),
              label: Text(context.tr('admin_select_all')),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.secondaryFixed,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.how_to_reg_outlined, size: 14, color: colorScheme.onSecondaryFixed),
                  const SizedBox(width: 4),
                  Text(
                    context.tr('admin_selected_count', args: {
                      'count': '${selectedIds.length}',
                    }),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryFixed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < students.length; i++) ...[
          _StudentRow(
            student: students[i],
            selected: selectedIds.contains(students[i].id),
            onToggle: () => onToggle(students[i].id),
            onUnassign: students[i].assignedClassId == null
                ? null
                : () => onUnassign(students[i]),
          ),
          if (i < students.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StudentRow extends StatelessWidget {
  final AdminStudent student;
  final bool selected;
  final VoidCallback? onToggle;
  final VoidCallback? onUnassign;

  const _StudentRow({
    required this.student,
    required this.selected,
    this.onToggle,
    this.onUnassign,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            AdminPersonAvatar(
              initials: student.initials,
              showOnlineDot: student.initials == null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          student.name,
                          style: theme.textTheme.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (student.verified) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified_rounded, size: 16, color: colorScheme.secondary),
                      ],
                    ],
                  ),
                  Text(
                    student.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (student.verified
                              ? colorScheme.tertiaryFixed
                              : colorScheme.surfaceContainer)
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      context.tr(student.verified
                          ? 'admin_verified'
                          : 'admin_unverified'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (onUnassign != null)
              IconButton(
                icon: const Icon(Icons.person_remove_outlined, size: 20),
                tooltip: context.tr('admin_unassign_action'),
                color: colorScheme.error,
                onPressed: onUnassign,
              ),
            // No assign checkbox for already-assigned students:
            // their only action is unassigning.
            if (student.assignedClassId == null)
              _CheckBox(selected: selected, onTap: onToggle),
          ],
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;

  const _CheckBox({required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.secondaryFixed,
          borderRadius: BorderRadius.circular(8),
        ),
        child: selected
            ? Icon(Icons.check_rounded, size: 18, color: colorScheme.onPrimary)
            : null,
      ),
    );
  }
}

class _BottomAssignBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onAssign;
  final VoidCallback onCancel;

  const _BottomAssignBar({
    required this.selectedCount,
    required this.onAssign,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('admin_selected_footer',
                        args: {'count': '$selectedCount'}),
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    context.tr('admin_assign_now'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_outlined, size: 16, color: colorScheme.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    context.tr('admin_instant_sync'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppButton(
            text:
                '${context.tr('admin_assign_to_class')}  ($selectedCount)',
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: selectedCount == 0 ? null : onAssign,
          ),
          Center(
            child: TextButton(
              onPressed: onCancel,
              child: Text(context.tr('admin_cancel_op')),
            ),
          ),
        ],
      ),
    );
  }
}

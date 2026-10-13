import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/repositories/admin_repository.dart';
import '../widgets/admin_filter_chips.dart';
import '../widgets/admin_person_avatar.dart';
import '../widgets/admin_search_field.dart';

class ClassTeachersPage extends ConsumerStatefulWidget {
  final String classId;

  const ClassTeachersPage({required this.classId, super.key});

  @override
  ConsumerState<ClassTeachersPage> createState() => _ClassTeachersPageState();
}

class _ClassTeachersPageState extends ConsumerState<ClassTeachersPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _filter = 'all';

  /// Ids picked for a NEW assignment. Already-assigned teachers offer no
  /// assign option (checkbox hidden) — only unassigning.
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _confirm() async {
    if (_selected.isEmpty) return;
    final subject = await _askSubject();
    if (subject == null || !mounted) return;
    try {
      await ref.read(adminRepositoryProvider).assignTeachers(
            widget.classId,
            _selected
                .map((id) => TeacherAssignment(
                      teacherId: id,
                      subject: subject.subject,
                      weeklyHours: subject.weeklyHours,
                    ))
                .toList(),
          );
    } catch (e) {
      if (!mounted) return;
      _showFailure(e);
      return;
    }
    ref.invalidate(adminTeachersProvider(widget.classId));
    ref.invalidate(adminClassDetailProvider(widget.classId));
    ref.invalidate(adminOverviewProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('admin_teachers_selected',
              args: {'count': '${_selected.length}'}),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  /// Subject (+ optional weekly hours) applied to every selected teacher.
  Future<({String subject, String? weeklyHours})?> _askSubject() async {
    final subjectController = TextEditingController();
    final hoursController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    try {
      return await showDialog<({String subject, String? weeklyHours})>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.tr('admin_assign_subject_title')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: subjectController,
                  hint: context.tr('admin_subject_hint'),
                  prefixIcon: const Icon(Icons.book_outlined),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? context.tr('required_field')
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: hoursController,
                  hint: context.tr('admin_hours_hint'),
                  prefixIcon: const Icon(Icons.schedule_outlined),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.of(dialogContext).pop((
                  subject: subjectController.text.trim(),
                  weeklyHours: hoursController.text.trim().isEmpty
                      ? null
                      : hoursController.text.trim(),
                ));
              },
              child: Text(context.tr('admin_confirm_assign')),
            ),
          ],
        ),
      );
    } finally {
      subjectController.dispose();
      hoursController.dispose();
    }
  }

  Future<void> _unassign(String teacherId, String teacherName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('admin_unassign_title')),
        content: Text(
          context.tr('admin_unassign_message', args: {'name': teacherName}),
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
          .removeTeachers(widget.classId, [teacherId]);
    } catch (e) {
      if (!mounted) return;
      _showFailure(e);
      return;
    }
    setState(() => _selected.remove(teacherId));
    ref.invalidate(adminTeachersProvider(widget.classId));
    ref.invalidate(adminClassDetailProvider(widget.classId));
    ref.invalidate(adminOverviewProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final teachersAsync = ref.watch(adminTeachersProvider(widget.classId));
    final detailAsync = ref.watch(adminClassDetailProvider(widget.classId));
    final loadedTeachers = teachersAsync.valueOrNull ?? const <AdminTeacher>[];

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
              context.tr('admin_assign_teachers'),
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
        actions: const [
          Padding(
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
                  horizontal: context.screenWidth >= 600 ? 32 : 20,
                  vertical: 8,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        detailAsync.when(
                          data: (detail) => _CoverageCard(
                            className: detail?.title ?? '',
                            department: detail?.department ?? '',
                            teachers: loadedTeachers,
                          ),
                          loading: () => const SizedBox(height: 24),
                          error: (_, _) => const SizedBox(height: 24),
                        ),
                        const SizedBox(height: 16),
                        AdminSearchField(
                          controller: _searchController,
                          hint: context.tr('admin_search_teacher_hint'),
                          onChanged: _onSearchChanged,
                          onFilterTap: () {},
                        ),
                        const SizedBox(height: 12),
                        teachersAsync.when(
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
                          data: (teachers) {
                            return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AdminFilterChips<String>(
                                options: [
                                  AdminFilterOption(
                                    value: 'all',
                                    label: context.tr('admin_all_count',
                                        args: {'count': '${teachers.length}'}),
                                  ),
                                  AdminFilterOption(
                                    value: 'assigned',
                                    label: context.tr('admin_assigned_f', args: {
                                      'count':
                                          '${teachers.where((t) => t.initiallyAssigned).length}'
                                    }),
                                  ),
                                  AdminFilterOption(
                                    value: 'available',
                                    label: context.tr('admin_available_f', args: {
                                      'count':
                                          '${teachers.where((t) => !t.initiallyAssigned).length}'
                                    }),
                                  ),
                                ],
                                selected: _filter,
                                onSelected: (v) => setState(() => _filter = v),
                              ),
                              const SizedBox(height: 12),
                              _TeachersHeader(),
                              const SizedBox(height: 8),
                              ..._applyFilter(teachers).map(
                                (teacher) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TeacherCard(
                                    teacher: teacher,
                                    selected: _selected.contains(teacher.id),
                                    onToggle: () => setState(() {
                                      if (!_selected.remove(teacher.id)) {
                                        _selected.add(teacher.id);
                                      }
                                    }),
                                    onUnassign: teacher.initiallyAssigned
                                        ? () => _unassign(
                                            teacher.id, teacher.name)
                                        : null,
                                  ),
                                ),
                              ),
                            ],
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
            _BottomConfirmBar(
              selectedCount: _selected.length,
              onCancel: () => context.pop(),
              onConfirm: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  List<AdminTeacher> _applyFilter(List<AdminTeacher> teachers) {
    var list = teachers;
    switch (_filter) {
      case 'available':
        list = list.where((t) => !t.initiallyAssigned).toList();
      case 'assigned':
        list = list.where((t) => t.initiallyAssigned).toList();
      case 'all':
      default:
        break;
    }
    return list;
  }
}

class _CoverageCard extends StatelessWidget {
  final String className;
  final String department;
  final List<AdminTeacher> teachers;

  const _CoverageCard({
    required this.className,
    required this.department,
    required this.teachers,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final assigned = teachers.where((t) => t.initiallyAssigned).toList();
    final subjects =
        assigned.map((t) => t.specialty).where((s) => s.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, size: 14, color: colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  context.tr('admin_academic_year'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            className.isNotEmpty ? className : '—',
            style: theme.textTheme.headlineSmall,
          ),
          if (department.isNotEmpty)
            Text(
              department,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
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
                    context.tr('admin_course_coverage'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                context.tr('admin_teachers_count',
                    args: {'count': '${assigned.length}'}),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subjects.isEmpty
                ? context.tr('admin_no_subjects')
                : subjects.join(' • '),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeachersHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.tr('admin_available_teachers'),
          style: theme.textTheme.labelLarge,
        ),
        Text(
          context.tr('admin_sort_affinity'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final AdminTeacher teacher;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback? onUnassign;

  const _TeacherCard({
    required this.teacher,
    required this.selected,
    required this.onToggle,
    this.onUnassign,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AdminPersonAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            teacher.name,
                            style: theme.textTheme.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (teacher.initiallyAssigned) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified_rounded,
                              size: 16, color: colorScheme.secondary),
                        ],
                      ],
                    ),
                    Text(
                      teacher.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (teacher.specialty.isNotEmpty)
                          _MiniPill(
                            text: teacher.specialty,
                            bg: colorScheme.surfaceContainerLow,
                            fg: colorScheme.secondary,
                          ),
                        _MiniPill(
                          text: context.tr(teacher.availabilityKey,
                              args: {'hours': teacher.availabilityArgs}),
                          bg: _availabilityBg(colorScheme, teacher),
                          fg: _availabilityFg(colorScheme, teacher),
                        ),
                      ],
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
              // No assign option for already-assigned teachers:
              // checkbox (or "Ajouter") only when unassigned.
              if (!teacher.initiallyAssigned)
                if (selected)
                  InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.check_rounded,
                        size: 18, color: colorScheme.onPrimary),
                  ),
                )
              else
                OutlinedButton(
                  onPressed: onToggle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    textStyle: theme.textTheme.labelSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 14),
                      const SizedBox(width: 2),
                      Text(context.tr('admin_add')),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('admin_subject_assigned'),
                style: theme.textTheme.labelMedium,
              ),
              Text(
                _subjectStatus(context, teacher),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.code_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    teacher.subjectLabel.isNotEmpty
                        ? teacher.subjectLabel
                        : context.tr('admin_not_assigned'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: teacher.subjectLabel.isNotEmpty
                          ? null
                          : colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subjectStatus(BuildContext context, AdminTeacher teacher) {
    if (teacher.initiallyAssigned) {
      return teacher.subjectValue == 'admin_not_assigned'
          ? ''
          : teacher.subjectValue;
    }
    return context.tr('admin_not_assigned');
  }

  Color _availabilityBg(ColorScheme colors, AdminTeacher teacher) {
    return switch (teacher.state) {
      PersonAssignState.assigned => colors.tertiaryFixed.withValues(alpha: 0.5),
      PersonAssignState.warning => colors.errorContainer,
      _ => colors.secondaryFixed,
    };
  }

  Color _availabilityFg(ColorScheme colors, AdminTeacher teacher) {
    return switch (teacher.state) {
      PersonAssignState.assigned => colors.onSurface,
      PersonAssignState.warning => colors.error,
      _ => colors.onSecondaryFixed,
    };
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _MiniPill({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

class _BottomConfirmBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _BottomConfirmBar({
    required this.selectedCount,
    required this.onCancel,
    required this.onConfirm,
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
                    context.tr('admin_teachers_selected',
                        args: {'count': '$selectedCount'}),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync_rounded, size: 14, color: colorScheme.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    context.tr('admin_ent_sync_now'),
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
          Row(
            children: [
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: theme.textTheme.labelMedium,
                ),
                child: Text(context.tr('admin_cancel')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  text: context.tr('admin_confirm_assign'),
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: selectedCount == 0 ? null : onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

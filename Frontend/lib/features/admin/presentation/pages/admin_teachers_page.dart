import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/entities/managed_class.dart';
import '../../domain/repositories/admin_repository.dart';
import '../widgets/admin_person_avatar.dart';
import '../widgets/admin_search_field.dart';
import '../views/web_admin_teachers_view.dart';
import '../../../../core/widgets/smart_loader.dart';

/// Global teacher directory (GET /api/v1/users?role=TEACHER) with
/// assignment to a class (class picker + subject dialog → real POST).
class AdminTeachersPage extends ConsumerStatefulWidget {
  const AdminTeachersPage({super.key});

  @override
  ConsumerState<AdminTeachersPage> createState() => _AdminTeachersPageState();
}

class _AdminTeachersPageState extends ConsumerState<AdminTeachersPage> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _assigning = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFailure(Object error) {
    final message = error is Failure
        ? context.tr(failureL10n(error).key)
        : context.tr('something_went_wrong');
    context.showErrorToast(message);
  }

  Future<void> _assign(AdminTeacher teacher) async {
    if (_assigning) return;
    final classId = await _pickClass();
    if (classId == null || !mounted) return;
    // Already assigned to this class → no assign option: inform and stop
    // (the per-class screen offers unassigning instead).
    try {
      final current = await ref
          .read(adminRepositoryProvider)
          .teachers(classId: classId);
      if (current.any((t) => t.id == teacher.id && t.initiallyAssigned)) {
        if (!mounted) return;
        context.showWarningToast(context.tr('admin_already_assigned'));
        return;
      }
    } catch (e) {
      if (!mounted) return;
      _showFailure(e);
      return;
    }
    if (!mounted) return;
    final subject = await _askSubject();
    if (subject == null || !mounted) return;
    setState(() => _assigning = true);
    try {
      await ref.read(adminRepositoryProvider).assignTeachers(
            classId,
            [
              TeacherAssignment(
                teacherId: teacher.id,
                subject: subject.subject,
                weeklyHours: subject.weeklyHours,
              ),
            ],
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _assigning = false);
      _showFailure(e);
      return;
    }
    ref.invalidate(adminTeachersProvider(null));
    ref.invalidate(adminClassesProvider);
    if (!mounted) return;
    setState(() => _assigning = false);
    context.showSuccessToast(context.tr('success'));
  }

  Future<String?> _pickClass() async {
    List<AdminClassSummary> classes = [];
    try {
      classes = await ref.read(adminRepositoryProvider).classes();
    } on Failure catch (failure) {
      if (!mounted) return null;
      final l10n = failureL10n(failure);
      context.showErrorToast(context.tr(l10n.key, args: l10n.args));
      return null;
    }
    if (!mounted) return null;
    if (classes.isEmpty) {
      context.showInfoToast(context.tr('admin_no_classes'));
      return null;
    }
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  context.tr('admin_assign_to'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: classes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    title: Text(classes[i].title,
                        style: theme.textTheme.bodyMedium),
                    subtitle: Text(classes[i].promoTag,
                        style: theme.textTheme.bodySmall),
                    trailing: Text(
                      context.tr('admin_teachers_count',
                          args: {'count': '${classes[i].teachers}'}),
                      style: theme.textTheme.labelSmall,
                    ),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(classes[i].id),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

  Future<void> _updateApproval(AdminTeacher teacher, String status) async {
    try {
      await ref.read(adminRepositoryProvider).updateTeacherApproval(teacher.id, status);
      ref.invalidate(adminTeachersProvider(null));
      if (!mounted) return;
      if (status == 'APPROVED') {
        context.showSuccessToast(context.tr('admin_toast_teacher_approved_short'));
      } else {
        context.showInfoToast(context.tr('admin_toast_teacher_rejected_short'));
      }
    } catch (e) {
      if (!mounted) return;
      _showFailure(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return const WebAdminTeachersView();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final teachersAsync = ref.watch(adminTeachersProvider(null));

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
              context.tr('admin_teachers_title'),
              style: theme.textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(adminTeachersProvider(null)),
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
                      context.tr('admin_teachers_sub'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AdminSearchField(
                      controller: _searchController,
                      hint: context.tr('admin_search_teacher_hint'),
                      onChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                      onFilterTap: () {},
                    ),
                    const SizedBox(height: 12),
                    teachersAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: SmartLoader.medium(
                            message: 'Chargement des enseignants...',
                          ),
                        ),
                      ),
                      error: (_, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Text(
                              context.tr('something_went_wrong'),
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => ref.invalidate(
                                  adminTeachersProvider(null)),
                              child: Text(context.tr('retry')),
                            ),
                          ],
                        ),
                      ),
                      data: (teachers) {
                        final filtered = _query.isEmpty
                            ? teachers
                            : teachers
                                .where((t) =>
                                    t.name.toLowerCase().contains(_query) ||
                                    t.email.toLowerCase().contains(_query))
                                .toList();
                        if (filtered.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              context.tr('admin_no_teachers'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (int i = 0; i < filtered.length; i++) ...[
                              _TeacherRow(
                                teacher: filtered[i],
                                busy: _assigning,
                                onAssign: () => _assign(filtered[i]),
                                onApprove: () => _updateApproval(filtered[i], 'APPROVED'),
                                onReject: () => _updateApproval(filtered[i], 'REJECTED'),
                              ),
                              if (i < filtered.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        );
                      },
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

class _TeacherRow extends StatelessWidget {
  final AdminTeacher teacher;
  final bool busy;
  final VoidCallback onAssign;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _TeacherRow({
    required this.teacher,
    required this.busy,
    required this.onAssign,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isPending = teacher.approvalStatus == 'PENDING';
    final isRejected = teacher.approvalStatus == 'REJECTED';

    final Color badgeBg;
    final Color badgeText;
    final String badgeLabel;
    final IconData badgeIcon;

    if (isPending) {
      badgeBg = Colors.amber.withValues(alpha: 0.15);
      badgeText = Colors.amber.shade900;
      badgeLabel = context.tr('admin_badge_pending');
      badgeIcon = Icons.hourglass_top_rounded;
    } else if (isRejected) {
      badgeBg = Colors.red.withValues(alpha: 0.12);
      badgeText = Colors.red.shade800;
      badgeLabel = context.tr('admin_badge_rejected');
      badgeIcon = Icons.cancel_outlined;
    } else {
      badgeBg = Colors.green.withValues(alpha: 0.12);
      badgeText = Colors.green.shade800;
      badgeLabel = context.tr('admin_badge_approved');
      badgeIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
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
          AdminPersonAvatar(initials: teacher.initials),
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
                    if (teacher.verified) ...[
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 12, color: badgeText),
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isPending) ...[
            IconButton(
              icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
              iconSize: 22,
              tooltip: context.tr('admin_validate_accreditation_tooltip'),
              onPressed: onApprove,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.cancel_rounded, color: Colors.red),
              iconSize: 22,
              tooltip: context.tr('admin_reject_tooltip'),
              onPressed: onReject,
              visualDensity: VisualDensity.compact,
            ),
          ] else if (isRejected) ...[
            IconButton(
              icon: const Icon(Icons.replay_rounded, color: Colors.green),
              iconSize: 22,
              tooltip: context.tr('admin_btn_reapprove'),
              onPressed: onApprove,
              visualDensity: VisualDensity.compact,
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.block_rounded, size: 18, color: Colors.grey.shade600),
              tooltip: context.tr('admin_btn_suspend_revoke'),
              onPressed: onReject,
              visualDensity: VisualDensity.compact,
            ),
          ],
          const SizedBox(width: 4),
          OutlinedButton(
            onPressed: busy ? null : onAssign,
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                Text(context.tr('admin_assign_action')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/entities/managed_class.dart';
import '../widgets/admin_person_avatar.dart';
import '../widgets/admin_search_field.dart';
import '../views/web_admin_users_view.dart';
import '../../../../core/widgets/smart_loader.dart';

/// Global student directory (GET /api/v1/users?role=STUDENT) with
/// enrolment into a class (class picker → real POST).
class AdminStudentsPage extends ConsumerStatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  ConsumerState<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends ConsumerState<AdminStudentsPage> {
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

  Future<void> _assign(AdminStudent student) async {
    if (_assigning) return;
    final classId = await _pickClass();
    if (classId == null || !mounted) return;
    // Already enrolled in this class → no assign option: inform and stop
    // (the per-class screen offers unassigning instead).
    try {
      final memberIds = await ref
          .read(adminRepositoryProvider)
          .classMemberIds(classId);
      if (memberIds.contains(student.id)) {
        if (!mounted) return;
        context.showWarningToast(context.tr('admin_already_in_class'));
        return;
      }
    } catch (e) {
      if (!mounted) return;
      _showFailure(e);
      return;
    }
    if (!mounted) return;
    setState(() => _assigning = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .assignStudents(classId, [student.id]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _assigning = false);
      _showFailure(e);
      return;
    }
    ref.invalidate(adminStudentsProvider(null));
    ref.invalidate(adminClassesProvider);
    ref.invalidate(adminOverviewProvider);
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
                      context.tr('admin_students_count',
                          args: {'count': '${classes[i].students}'}),
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

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return const WebAdminUsersPage();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final studentsAsync = ref.watch(adminStudentsProvider(null));

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
              context.tr('admin_students_title'),
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
              ref.invalidate(adminStudentsProvider(null)),
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
                      context.tr('admin_students_sub'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AdminSearchField(
                      controller: _searchController,
                      hint: context.tr('admin_search_person_hint'),
                      onChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                      onFilterTap: () {},
                    ),
                    const SizedBox(height: 12),
                    studentsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: SmartLoader.medium(
                            message: 'Chargement des étudiants...',
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
                                  adminStudentsProvider(null)),
                              child: Text(context.tr('retry')),
                            ),
                          ],
                        ),
                      ),
                      data: (students) {
                        final filtered = _query.isEmpty
                            ? students
                            : students
                                .where((s) =>
                                    s.name.toLowerCase().contains(_query) ||
                                    s.email.toLowerCase().contains(_query))
                                .toList();
                        if (filtered.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              context.tr('admin_no_students'),
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
                              _StudentRow(
                                student: filtered[i],
                                busy: _assigning,
                                onAssign: () => _assign(filtered[i]),
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

class _StudentRow extends StatelessWidget {
  final AdminStudent student;
  final bool busy;
  final VoidCallback onAssign;

  const _StudentRow({
    required this.student,
    required this.busy,
    required this.onAssign,
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
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          AdminPersonAvatar(initials: student.initials),
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
                      Icon(Icons.verified_rounded,
                          size: 16, color: colorScheme.secondary),
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
              ],
            ),
          ),
          const SizedBox(width: 8),
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

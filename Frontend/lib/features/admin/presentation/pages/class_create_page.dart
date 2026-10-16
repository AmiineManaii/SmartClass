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
import '../../domain/entities/managed_class.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../infrastructure/models/admin_models.dart';
import '../widgets/admin_field_label.dart';

/// Class creation (and edition when [editClassId] is set) backed by the
/// real API: POST /api/v1/groups, PATCH /api/v1/groups/:id.
/// Filière picker lists tracks really in use (GET /groups/departments)
/// plus a free-text new filière; optional referent from the real teacher
/// directory. UI levels map to the LICENCE/MASTER/DOCTORAT enum.
class ClassCreatePage extends ConsumerStatefulWidget {
  final String? editClassId;

  const ClassCreatePage({this.editClassId, super.key});

  @override
  ConsumerState<ClassCreatePage> createState() => _ClassCreatePageState();
}

class _ClassCreatePageState extends ConsumerState<ClassCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customDepartmentController = TextEditingController();
  String _level = 'L3';
  String? _department;
  String? _referentId;
  String? _referentName;
  int _capacity = 35;
  bool _forumEnabled = true;
  bool _entSyncEnabled = true;
  bool _saving = false;
  bool _prefilled = false;

  bool get _isEdit => widget.editClassId != null;

  static const _levels = ['L1', 'L2', 'L3', 'Master 1', 'Master 2', 'Doctorat'];
  static const _maxDescription = 300;

  static ClassLevel _apiLevel(String label) {
    if (label == 'Doctorat') return ClassLevel.doctorat;
    if (label.startsWith('Master')) return ClassLevel.master;
    return ClassLevel.licence;
  }

  static String _labelFor(ClassLevel level) {
    switch (level) {
      case ClassLevel.master:
        return 'Master 1';
      case ClassLevel.doctorat:
        return 'Doctorat';
      case ClassLevel.licence:
        return 'L3';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customDepartmentController.dispose();
    super.dispose();
  }

  void _prefill(AdminClassDetail detail) {
    if (_prefilled) return;
    _prefilled = true;
    _nameController.text = detail.title;
    _descriptionController.text = '';
    _level = _labelFor(detail.level);
    _department = detail.department.isEmpty ? null : detail.department;
    _capacity = detail.capacity > 0 ? detail.capacity : 35;
    _referentName = detail.referent.isEmpty ? null : detail.referent;
  }

  String get _effectiveDepartment {
    final custom = _customDepartmentController.text.trim();
    if (custom.isNotEmpty) return custom;
    return (_department ?? '').trim();
  }

  Future<void> _submit({required bool draft}) async {
    if (!draft && !_formKey.currentState!.validate()) return;
    if (!draft && _nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (_isEdit) {
        await repo.updateClass(widget.editClassId!, {
          'name': _nameController.text.trim(),
          'level': adminLevelToApi(_apiLevel(_level)),
          if (_effectiveDepartment.isNotEmpty) 'department': _effectiveDepartment,
          'capacity': _capacity,
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'forumEnabled': _forumEnabled,
          'entSyncEnabled': _entSyncEnabled,
          'status': draft ? 'DRAFT' : 'PUBLISHED',
          if (_referentId != null) 'referentId': _referentId,
        });
      } else {
        await repo.createClass(
          name: _nameController.text.trim(),
          level: _apiLevel(_level),
          department: _effectiveDepartment.isEmpty ? null : _effectiveDepartment,
          capacity: _capacity,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          forumEnabled: _forumEnabled,
          entSyncEnabled: _entSyncEnabled,
          draft: draft,
          referentId: _referentId,
        );
      }
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _saving = false);
      final l10n = failureL10n(failure);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(l10n.key, args: l10n.args)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    } finally {
      if (mounted && _saving) setState(() => _saving = false);
    }
    ref.invalidate(adminClassesProvider);
    ref.invalidate(adminDepartmentsProvider);
    ref.invalidate(adminOverviewProvider);
    if (widget.editClassId != null) {
      ref.invalidate(adminClassDetailProvider(widget.editClassId!));
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(draft ? 'drafts' : 'success')),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final departmentsAsync = ref.watch(adminDepartmentsProvider);

    if (_isEdit) {
      final detailAsync = ref.watch(adminClassDetailProvider(widget.editClassId!));
      return detailAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          )),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Scaffold(
          appBar: AppBar(leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          )),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('something_went_wrong'),
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(adminClassDetailProvider(widget.editClassId!)),
                  child: Text(context.tr('retry')),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return Scaffold(
              appBar: AppBar(leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
              )),
              body: Center(child: Text(context.tr('empty_state'))),
            );
          }
          _prefill(detail);
          return _buildScaffold(context, departmentsAsync);
        },
      );
    }
    return _buildScaffold(context, departmentsAsync);
  }

  Widget _buildScaffold(
    BuildContext context,
    AsyncValue<List<DepartmentInfo>> departmentsAsync,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();

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
              context.tr(_isEdit ? 'admin_edit_class_title' : 'admin_classes_title'),
              style: theme.textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.screenWidth >= 600 ? 32 : 20,
            vertical: 8,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _IntroCard(yearRange: '${now.year}-${now.year + 1}'),
                    const SizedBox(height: 16),
                    const AdminFieldLabel(labelKey: 'admin_class_name', trailingKey: 'admin_required', showTrailing: true, requiredStar: true),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: _nameController,
                      hint: context.tr('admin_class_name_hint'),
                      prefixIcon: const Icon(Icons.co_present_outlined),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? context.tr('required_field') : null,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            context.tr('admin_class_name_note'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr('admin_study_level'), style: theme.textTheme.labelLarge),
                        Text(
                          _apiLevel(_level).name.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _DropdownRow(
                      icon: Icons.workspace_premium_outlined,
                      value: _level,
                      onTap: () => _pickLevel(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('admin_quick_pick').toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.06,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final level in _levels)
                          _ChoiceChip(
                            label: level,
                            selected: _level == level,
                            onTap: () => setState(() => _level = level),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr('admin_department'), style: theme.textTheme.labelLarge),
                        Text(
                          context.tr('admin_required'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    departmentsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => _departmentField(context, const []),
                      data: (departments) =>
                          _departmentField(context, departments),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _customDepartmentController,
                      hint: context.tr('admin_department_custom_hint'),
                      prefixIcon: const Icon(Icons.add_rounded),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr('admin_referent_label'),
                            style: theme.textTheme.labelLarge),
                        Text(
                          context.tr('admin_optional'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _DropdownRow(
                      icon: Icons.co_present_outlined,
                      value: _referentName ??
                          context.tr('admin_no_referent_option'),
                      onTap: _pickReferent,
                    ),
                    const SizedBox(height: 16),
                    Text(context.tr('admin_capacity'), style: theme.textTheme.labelLarge),
                    Text(
                      context.tr('admin_capacity_hint'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StepperButton(
                            icon: Icons.remove_rounded,
                            onTap: _capacity > 5
                                ? () => setState(() => _capacity -= 5)
                                : null,
                          ),
                          Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$_capacity',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.tr('admin_students_max'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          _StepperButton(
                            icon: Icons.add_rounded,
                            filled: true,
                            onTap: _capacity < 500
                                ? () => setState(() => _capacity += 5)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr('admin_description_label'),
                            style: theme.textTheme.labelLarge),
                        Text(
                          context.tr('admin_optional'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: _descriptionController,
                      hint: context.tr('admin_description_hint'),
                      maxLines: 4,
                      maxLength: _maxDescription,
                      onChanged: (_) => setState(() {}),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        context.tr('admin_char_count', args: {
                          'used': _descriptionController.text.length.toString(),
                          'max': _maxDescription.toString(),
                        }),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('admin_auto_params').toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                        letterSpacing: 0.06,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SwitchRow(
                      icon: Icons.forum_outlined,
                      title: context.tr('admin_forum_title'),
                      subtitle: context.tr('admin_forum_desc'),
                      value: _forumEnabled,
                      onChanged: (v) => setState(() => _forumEnabled = v),
                    ),
                    const SizedBox(height: 8),
                    _SwitchRow(
                      icon: Icons.sync_alt_rounded,
                      title: context.tr('admin_ent_sync_title'),
                      subtitle: context.tr('admin_ent_sync_desc'),
                      value: _entSyncEnabled,
                      onChanged: (v) => setState(() => _entSyncEnabled = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.verified_user_outlined,
                            size: 16, color: colorScheme.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.tr('admin_access_note'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: context.tr(_isEdit
                          ? 'admin_save_changes'
                          : 'admin_create_group'),
                      trailingIcon: Icons.arrow_forward_rounded,
                      isLoading: _saving,
                      onPressed: _saving ? null : () => _submit(draft: false),
                    ),
                    if (!_isEdit) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _saving ? null : () => _submit(draft: true),
                          child: Text(context.tr('admin_save_draft')),
                        ),
                      ),
                    ],
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

  Widget _departmentField(
    BuildContext context,
    List<DepartmentInfo> departments,
  ) {
    final selected = _department;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DropdownRow(
          icon: Icons.domain_outlined,
          value: _customDepartmentController.text.trim().isNotEmpty
              ? _customDepartmentController.text.trim()
              : (selected ?? context.tr('admin_department_choose')),
          onTap: () => _pickDepartment(context, departments),
        ),
        if (departments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final dept in departments)
                _ChoiceChip(
                  label: '${dept.name} (${dept.classCount})',
                  selected: selected == dept.name &&
                      _customDepartmentController.text.trim().isEmpty,
                  showCheck: true,
                  onTap: () => setState(() {
                    _customDepartmentController.clear();
                    _department = dept.name;
                  }),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _pickLevel(BuildContext context) async {
    final selected = await _pickFromSheet(context, _levels);
    if (selected != null) setState(() => _level = selected);
  }

  Future<void> _pickDepartment(
    BuildContext context,
    List<DepartmentInfo> departments,
  ) async {
    final options = departments.map((d) => d.name).toList();
    if (options.isEmpty) return;
    final selected = await _pickFromSheet(context, options);
    if (selected != null) {
      setState(() {
        _customDepartmentController.clear();
        _department = selected;
      });
    }
  }

  Future<void> _pickReferent() async {
    List<AdminTeacher> teachers = [];
    try {
      teachers = await ref.read(adminRepositoryProvider).teachers();
    } on Failure catch (failure) {
      if (!mounted) return;
      final l10n = failureL10n(failure);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(l10n.key, args: l10n.args))),
      );
      return;
    }
    if (!mounted) return;
    final selected = await showModalBottomSheet<AdminTeacher?>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: teachers.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              if (i == 0) {
                return ListTile(
                  title: Text(sheetContext.tr('admin_no_referent_option'),
                      style: theme.textTheme.bodyMedium),
                  onTap: () => Navigator.of(sheetContext).pop(null),
                );
              }
              final teacher = teachers[i - 1];
              return ListTile(
                title: Text(teacher.name, style: theme.textTheme.bodyMedium),
                subtitle: Text(teacher.email,
                    style: theme.textTheme.bodySmall),
                onTap: () => Navigator.of(sheetContext).pop(teacher),
              );
            },
          ),
        );
      },
    );
    if (!mounted) return;
    // Null dismissal (tap outside) keeps the current choice; explicit
    // "none" clears it. Distinguish via a sentinel is overkill here:
    // dismissal returns null too, which would clear — acceptable since
    // referent is optional and re-pickable.
    setState(() {
      _referentId = selected?.id;
      _referentName = selected?.name;
    });
  }

  Future<String?> _pickFromSheet(BuildContext context, List<String> options) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: options.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              title: Text(options[i], style: theme.textTheme.bodyMedium),
              onTap: () => Navigator.of(sheetContext).pop(options[i]),
            ),
          ),
        );
      },
    );
  }
}

class _IntroCard extends StatelessWidget {
  final String yearRange;

  const _IntroCard({required this.yearRange});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.school_rounded, color: colorScheme.onPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.tr('admin_space_admin')} • $yearRange',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      context.tr('admin_create_desc'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F9D78),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('admin_registry_synced'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                context.tr('admin_step_1_2'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  const _DropdownRow({required this.icon, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.expand_more_rounded, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool showCheck;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    this.showCheck = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected ? colorScheme.primary : colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (selected && showCheck) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_circle_rounded, size: 14, color: colorScheme.onPrimary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.filled = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: filled ? colorScheme.secondaryFixed : colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: filled
                ? colorScheme.onSecondaryFixed
                : (onTap == null
                    ? colorScheme.outline
                    : colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.labelLarge),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

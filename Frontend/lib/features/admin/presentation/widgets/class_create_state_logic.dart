part of '../pages/class_create_page.dart';
extension on _ClassCreatePageState {
  void _prefill(AdminClassDetail detail) {
    if (_prefilled) return;
    _prefilled = true;
    _nameController.text = detail.title;
    _descriptionController.text = '';
    _level = _ClassCreatePageState._labelFor(detail.level);
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
    updateState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (_isEdit) {
        await repo.updateClass(widget.editClassId!, {
          'name': _nameController.text.trim(),
          'level': adminLevelToApi(_ClassCreatePageState._apiLevel(_level)),
          if (_effectiveDepartment.isNotEmpty)
            'department': _effectiveDepartment,
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
          level: _ClassCreatePageState._apiLevel(_level),
          department:
              _effectiveDepartment.isEmpty ? null : _effectiveDepartment,
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
      updateState(() => _saving = false);
      final l10n = failureL10n(failure);
      context.showErrorToast(context.tr(l10n.key, args: l10n.args));
      return;
    } finally {
      if (mounted && _saving) updateState(() => _saving = false);
    }
    ref.invalidate(adminClassesProvider);
    ref.invalidate(adminDepartmentsProvider);
    ref.invalidate(adminOverviewProvider);
    if (widget.editClassId != null) {
      ref.invalidate(adminClassDetailProvider(widget.editClassId!));
    }
    if (!mounted) return;
    context.showSuccessToast(
      _isEdit
          ? context.tr('admin_toast_class_updated')
          : (draft
              ? context.tr('admin_toast_class_draft_saved')
              : context.tr('admin_toast_class_created')),
    );
    context.go('/admin/classes');
  }
}



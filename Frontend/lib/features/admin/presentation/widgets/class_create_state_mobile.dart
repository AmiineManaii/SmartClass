part of '../pages/class_create_page.dart';
extension on _ClassCreatePageState {
  Widget _buildCapacityStudioControl(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // - Stepper button
            _stepperBtn(
              icon: Icons.remove_rounded,
              onTap: _capacity > 5 ? () => updateState(() => _capacity -= 5) : null,
              isDark: isDark,
            ),
            const SizedBox(width: 16),
            // Value display
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_capacity',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('admin_students_max_label'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // + Stepper button
            _stepperBtn(
              icon: Icons.add_rounded,
              onTap: _capacity < 500 ? () => updateState(() => _capacity += 5) : null,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Preset quick pills
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            Text(
              context.tr('admin_presets_label'),
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            for (final preset in _ClassCreatePageState._capacityPresets)
              InkWell(
                onTap: () => updateState(() => _capacity = preset),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _capacity == preset
                        ? const Color(0xFF2563EB)
                        : (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$preset',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _capacity == preset
                          ? Colors.white
                          : (isDark
                              ? Colors.white
                              : const Color(0xFF0F172A)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stepperBtn({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: onTap == null
                ? const Color(0xFF64748B)
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceToggleCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_rounded,
                color: Color(0xFF2563EB), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF2563EB),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String label, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 15,
            color: isDone ? const Color(0xFF10B981) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                color: isDone
                    ? const Color(0xFF10B981)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MOBILE FALLBACK (Clean Vertical Layout)
  // =========================================================================
  Widget _buildMobileForm(
    BuildContext context,
    AsyncValue<List<DepartmentInfo>> departmentsAsync,
    AsyncValue<List<AdminTeacher>> teachersAsync,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEdit ? context.tr('admin_breadcrumb_edit_class') : context.tr('admin_breadcrumb_new_class'),
          style: theme.textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AdminFieldLabel(
                  labelKey: 'admin_class_name',
                  trailingKey: 'admin_required',
                  showTrailing: true,
                  requiredStar: true,
                ),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _nameController,
                  hint: 'Ex: L3 Informatique - Groupe A',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? context.tr('required_field')
                      : null,
                ),
                const SizedBox(height: 16),
                const Text('NIVEAU D\'ÉTUDES',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildLevelSegmentedSelector(isDark),
                const SizedBox(height: 16),
                Text(context.tr('admin_department_label'),
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDepartmentChips(departmentsAsync, isDark),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _customDepartmentController,
                  hint: context.tr('admin_custom_department_hint'),
                ),
                const SizedBox(height: 16),
                Text(context.tr('admin_teacher_referent_label'),
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildTeacherDropdown(teachersAsync, isDark),
                const SizedBox(height: 16),
                Text(context.tr('admin_group_capacity_label'),
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildCapacityStudioControl(isDark),
                const SizedBox(height: 24),
                AppButton(
                  text: _isEdit
                      ? context.tr('admin_btn_save_changes')
                      : context.tr('admin_btn_create_class'),
                  isLoading: _saving,
                  onPressed: _saving ? null : () => _submit(draft: false),
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _saving ? null : () => _submit(draft: true),
                    child: Text(context.tr('admin_btn_save_draft')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


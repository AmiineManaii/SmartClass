part of '../pages/class_create_page.dart';
extension on _ClassCreatePageState {
  Widget _buildSectionCard({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required String badge,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }

  Widget _buildLevelSegmentedSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Licence Cycle
        _buildCycleRow(
          title: context.tr('admin_cycle_licence'),
          color: const Color(0xFF2563EB),
          levels: _ClassCreatePageState._licenceLevels,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        // Master Cycle
        _buildCycleRow(
          title: context.tr('admin_cycle_master'),
          color: const Color(0xFF7C3AED),
          levels: _ClassCreatePageState._masterLevels,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        // Doctorat Cycle
        _buildCycleRow(
          title: context.tr('admin_cycle_doctorat'),
          color: const Color(0xFFD97706),
          levels: _ClassCreatePageState._doctoratLevels,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildCycleRow({
    required String title,
    required Color color,
    required List<String> levels,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: levels.map((lvl) {
            final isSelected = _level == lvl;
            return InkWell(
              onTap: () => updateState(() => _level = lvl),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      lvl,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? Colors.white
                                : const Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDepartmentChips(
    AsyncValue<List<DepartmentInfo>> departmentsAsync,
    bool isDark,
  ) {
    return departmentsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
      data: (departments) {
        if (departments.isEmpty) return const SizedBox.shrink();
        final selected = _effectiveDepartment;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: departments.map((dept) {
            final isSelected = selected == dept.name &&
                _customDepartmentController.text.trim().isEmpty;
            return InkWell(
              onTap: () {
                updateState(() {
                  _customDepartmentController.clear();
                  _department = dept.name;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dept.name,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? Colors.white
                                : const Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${dept.classCount}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTeacherDropdown(
    AsyncValue<List<AdminTeacher>> teachersAsync,
    bool isDark,
  ) {
    return teachersAsync.when(
      loading: () => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Text(context.tr('admin_teacher_loading'),
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ),
      error: (_, _) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: Text(context.tr('admin_teacher_error'),
            style: TextStyle(fontSize: 12, color: AppTheme.error)),
      ),
      data: (teachers) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _referentId,
              isExpanded: true,
              dropdownColor:
                  isDark ? const Color(0xFF0F172A) : Colors.white,
              icon: const Icon(Icons.arrow_drop_down_rounded),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.person_off_outlined,
                          size: 16, color: Color(0xFF64748B)),
                      SizedBox(width: 8),
                      Text(
                        context.tr('admin_no_referent_option'),
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                ...teachers.map((t) {
                  return DropdownMenuItem<String?>(
                    value: t.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF2563EB)
                              .withValues(alpha: 0.12),
                          child: Text(
                            t.initials ?? 'PR',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${t.name} (${t.email})',
                            style: const TextStyle(fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (id) {
                updateState(() {
                  _referentId = id;
                  if (id == null) {
                    _referentName = null;
                  } else {
                    _referentName =
                        teachers.where((t) => t.id == id).firstOrNull?.name;
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }

}


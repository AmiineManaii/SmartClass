part of '../pages/class_create_page.dart';
extension on _ClassCreatePageState {
  Widget _buildView(
    BuildContext context,
    AsyncValue<List<DepartmentInfo>> departmentsAsync,
    AsyncValue<List<AdminTeacher>> teachersAsync,
  ) {
    final isDesktop = context.screenWidth >= 800;
    if (isDesktop) {
      return _buildDesktopStudio(context, departmentsAsync, teachersAsync);
    }
    return _buildMobileForm(context, departmentsAsync, teachersAsync);
  }

  // =========================================================================
  // DESKTOP WEB STUDIO LAYOUT (Wide 2-Column with Sticky Live Preview)
  // =========================================================================
  Widget _buildDesktopStudio(
    BuildContext context,
    AsyncValue<List<DepartmentInfo>> departmentsAsync,
    AsyncValue<List<AdminTeacher>> teachersAsync,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Breadcrumb & Back Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_outlined,
                          size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('admin_classes_breadcrumb_cat'),
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        '  /  ',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      InkWell(
                        onTap: () => context.go('/admin/classes'),
                        child: Text(
                          context.tr('admin_breadcrumb_classes'),
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '  /  ',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      Text(
                        _isEdit ? context.tr('admin_breadcrumb_edit_class') : context.tr('admin_breadcrumb_new_class'),
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF0F172A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/admin/classes'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(context.tr('admin_btn_return_classes')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.white : const Color(0xFF2563EB),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Page Title & Subtitle
              Text(
                _isEdit ? context.tr('admin_class_edit_heading') : context.tr('admin_class_create_heading'),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('admin_class_create_sub'),
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 28),

              // Two-Column Studio Layout
              Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN (65%): Form Configuration Panels
                    Expanded(
                      flex: 65,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Card 1: Identité Académique & Cursus
                          _buildSectionCard(
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            badge: context.tr('admin_step1_badge'),
                            badgeColor: const Color(0xFF2563EB),
                            title: context.tr('admin_step1_title'),
                            subtitle:
                                context.tr('admin_step1_subtitle'),
                            icon: Icons.school_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AdminFieldLabel(
                                  labelKey: 'admin_class_name',
                                  trailingKey: 'admin_required',
                                  showTrailing: true,
                                  requiredStar: true,
                                ),
                                const SizedBox(height: 8),
                                AppTextField(
                                  controller: _nameController,
                                  hint: 'Ex: L3 Informatique - Groupe A',
                                  prefixIcon:
                                      const Icon(Icons.co_present_outlined),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? context.tr('required_field')
                                          : null,
                                ),
                                const SizedBox(height: 20),

                                // Cycle & Level Selector (Inline native chips)
                                const Text(
                                  'NIVEAU D\'ÉTUDES ACADÉMIQUE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildLevelSegmentedSelector(isDark),
                                const SizedBox(height: 20),

                                // Department / Filière
                                Text(
                                  context.tr('admin_department_label'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildDepartmentChips(departmentsAsync, isDark),
                                const SizedBox(height: 10),
                                AppTextField(
                                  controller: _customDepartmentController,
                                  hint:
                                      context.tr('admin_custom_department_hint'),
                                  prefixIcon: const Icon(Icons.add_rounded),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Card 2: Enseignant Référent & Capacité
                          _buildSectionCard(
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            badge: context.tr('admin_step2_badge'),
                            badgeColor: const Color(0xFF7C3AED),
                            title: context.tr('admin_step2_title'),
                            subtitle:
                                context.tr('admin_step2_subtitle'),
                            icon: Icons.groups_3_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('admin_teacher_referent_label'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildTeacherDropdown(teachersAsync, isDark),
                                const SizedBox(height: 20),

                                Text(
                                  context.tr('admin_group_capacity_label'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildCapacityStudioControl(isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Card 3: Modules & Description
                          _buildSectionCard(
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            badge: context.tr('admin_step3_badge'),
                            badgeColor: const Color(0xFF10B981),
                            title: context.tr('admin_step3_title'),
                            subtitle:
                                context.tr('admin_step3_subtitle'),
                            icon: Icons.tune_rounded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('admin_description_label_title'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AppTextField(
                                  controller: _descriptionController,
                                  hint:
                                      context.tr('admin_description_placeholder'),
                                  maxLines: 3,
                                  maxLength: _ClassCreatePageState._maxDescription,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.tr('admin_smartclass_services_label'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildServiceToggleCard(
                                        isDark: isDark,
                                        icon: Icons.forum_outlined,
                                        title: 'Forum d\'échange',
                                        subtitle: context.tr('admin_service_forum_sub'),
                                        value: _forumEnabled,
                                        onChanged: (v) =>
                                            updateState(() => _forumEnabled = v),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _buildServiceToggleCard(
                                        isDark: isDark,
                                        icon: Icons.sync_alt_rounded,
                                        title: context.tr('admin_service_ent_title'),
                                        subtitle: context.tr('admin_service_ent_sub'),
                                        value: _entSyncEnabled,
                                        onChanged: (v) =>
                                            updateState(() => _entSyncEnabled = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 28),

                    // RIGHT COLUMN (35%): Sticky Live Class Preview Card & Actions
                    Expanded(
                      flex: 35,
                      child: _buildRightStickyHub(
                        isDark: isDark,
                        cardBg: cardBg,
                        borderColor: borderColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // RIGHT STICKY HUB (Live Card Preview + Checklist + Submit)
  // =========================================================================
}


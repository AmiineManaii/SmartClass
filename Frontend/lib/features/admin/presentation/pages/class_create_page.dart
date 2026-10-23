import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/entities/managed_class.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../infrastructure/models/admin_models.dart';
import '../widgets/admin_field_label.dart';

/// Class creation and editing studio designed specifically for Web & Desktop.
/// Backed by real API endpoints: POST /api/v1/groups, PATCH /api/v1/groups/:id.
/// Includes real-time class card preview, inline cycle and department selectors,
/// live teacher directory dropdown, and university cohort capacity presets.
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

  static const _maxDescription = 300;

  static const _licenceLevels = ['L1', 'L2', 'L3'];
  static const _masterLevels = ['Master 1', 'Master 2'];
  static const _doctoratLevels = ['Doctorat'];
  static const _capacityPresets = [20, 25, 30, 35, 40, 50, 60];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _customDepartmentController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customDepartmentController.dispose();
    super.dispose();
  }

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

  Color _colorForLevel(String level) {
    if (level.startsWith('Doctorat')) return const Color(0xFFD97706);
    if (level.startsWith('Master')) return const Color(0xFF7C3AED);
    return const Color(0xFF2563EB);
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
          level: _apiLevel(_level),
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
      setState(() => _saving = false);
      final l10n = failureL10n(failure);
      context.showErrorToast(context.tr(l10n.key, args: l10n.args));
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
    context.showSuccessToast(
      _isEdit
          ? context.tr('admin_toast_class_updated')
          : (draft
              ? context.tr('admin_toast_class_draft_saved')
              : context.tr('admin_toast_class_created')),
    );
    context.go('/admin/classes');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final departmentsAsync = ref.watch(adminDepartmentsProvider);
    final teachersAsync = ref.watch(adminTeachersProvider(null));

    if (_isEdit) {
      final detailAsync =
          ref.watch(adminClassDetailProvider(widget.editClassId!));
      return detailAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('something_went_wrong'),
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(
                      adminClassDetailProvider(widget.editClassId!)),
                  child: Text(context.tr('retry')),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => context.pop(),
                ),
              ),
              body: Center(child: Text(context.tr('empty_state'))),
            );
          }
          _prefill(detail);
          return _buildView(context, departmentsAsync, teachersAsync);
        },
      );
    }
    return _buildView(context, departmentsAsync, teachersAsync);
  }

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
                                  maxLength: _maxDescription,
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
                                            setState(() => _forumEnabled = v),
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
                                            setState(() => _entSyncEnabled = v),
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
  Widget _buildRightStickyHub({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    final lvlColor = _colorForLevel(_level);
    final titleText = _nameController.text.trim();
    final deptText = _effectiveDepartment;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: APERÇU EN DIRECT
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.visibility_outlined,
                        size: 16, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text(
                      context.tr('admin_live_preview_header'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                      SizedBox(width: 5),
                      Text(
                        context.tr('admin_real_time'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // The Mock Class Card (Live visual preview)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cycle Badge + Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: lvlColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _level,
                          style: TextStyle(
                            color: lvlColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isEdit ? context.tr('admin_status_published') : context.tr('admin_breadcrumb_new_class'),
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Class Title
                  Text(
                    titleText.isEmpty
                        ? 'Ex: L3 Informatique - Groupe A'
                        : titleText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: titleText.isEmpty
                          ? (isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8))
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deptText.isEmpty
                        ? context.tr('admin_dept_unspecified_session')
                        : context.tr('admin_dept_specified_session', args: {'dept': deptText}),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Enseignant Référent Tile
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              const Color(0xFF2563EB).withValues(alpha: 0.12),
                          child: const Icon(Icons.person_rounded,
                              size: 16, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('admin_referent_teacher_title'),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _referentName ?? context.tr('admin_referent_unassigned'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Capacity Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('admin_capacity_label_preview'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        context.tr('admin_capacity_students_ratio', args: {'capacity': _capacity.toString()}),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.05,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Modules Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (_forumEnabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF2563EB).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.forum_outlined,
                                  size: 12, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text(
                                context.tr('admin_chip_forum_active'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_entSyncEnabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF7C3AED).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sync_rounded,
                                  size: 12, color: Color(0xFF7C3AED)),
                              SizedBox(width: 4),
                              Text(
                                context.tr('admin_chip_ent_synced'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Checklist de validation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('admin_validation_criteria_title'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                _buildCheckRow(context.tr('admin_criterion_name'),
                    _nameController.text.trim().isNotEmpty),
                _buildCheckRow(context.tr('admin_criterion_level'), _level.isNotEmpty),
                _buildCheckRow(context.tr('admin_criterion_dept'),
                    _effectiveDepartment.isNotEmpty),
                _buildCheckRow(
                    context.tr('admin_criterion_capacity'), _capacity > 0),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: _saving ? null : () => _submit(draft: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit
                              ? context.tr('admin_btn_save_changes')
                              : context.tr('admin_btn_create_class'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _saving ? null : () => _submit(draft: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.tr('admin_btn_save_draft'),
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => context.go('/admin/classes'),
                  child: Text(context.tr('cancel')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION COMPONENTS
  // =========================================================================
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
          levels: _licenceLevels,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        // Master Cycle
        _buildCycleRow(
          title: context.tr('admin_cycle_master'),
          color: const Color(0xFF7C3AED),
          levels: _masterLevels,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        // Doctorat Cycle
        _buildCycleRow(
          title: context.tr('admin_cycle_doctorat'),
          color: const Color(0xFFD97706),
          levels: _doctoratLevels,
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
              onTap: () => setState(() => _level = lvl),
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
                setState(() {
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
                setState(() {
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

  Widget _buildCapacityStudioControl(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // - Stepper button
            _stepperBtn(
              icon: Icons.remove_rounded,
              onTap: _capacity > 5 ? () => setState(() => _capacity -= 5) : null,
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
              onTap: _capacity < 500 ? () => setState(() => _capacity += 5) : null,
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
            for (final preset in _capacityPresets)
              InkWell(
                onTap: () => setState(() => _capacity = preset),
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

// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  Widget _buildPersonalInfoCard(Color cardBg, Color borderColor, bool isDark) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final role = authState?.role?.toLowerCase() ?? 'student';
    final isTeacher = role == 'teacher';
    final isAdmin = role == 'admin';

    return Container(
      padding: EdgeInsets.all(context.screenWidth >= 1024 ? 24 : 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Icon, Title, Subtitle and Official ID badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isAdmin
                      ? Icons.admin_panel_settings_rounded
                      : Icons.folder_shared_rounded,
                  color: const Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('menu_personal_info'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAdmin
                          ? 'Coordonnées & Informations administratives certifiées'
                          : context.tr('certified_academic_data'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAdmin
                          ? Icons.admin_panel_settings_outlined
                          : Icons.badge_rounded,
                      size: 13,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAdmin
                          ? 'Identifiant officiel certifié'
                          : (isTeacher
                                ? 'Matricule officiel certifié'
                                : context.tr('official_id')),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Photo Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFDBEAFE),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/student_avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            _fullNameController.text.isNotEmpty
                                ? _fullNameController.text[0].toUpperCase()
                                : (isTeacher ? 'P' : 'A'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            isAdmin
                                ? 'Photo de profil administrateur'
                                : (isTeacher
                                      ? 'Photo de profil enseignant'
                                      : context.tr('student_photo_title')),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              context.tr('validated_badge'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAdmin
                            ? 'Format PNG ou JPG, max 5 Mo. Cette photo figure sur votre console d\'administration et vos rapports d\'audit.'
                            : (isTeacher
                                  ? 'Format PNG ou JPG, max 5 Mo. Cette photo figure sur votre badge officiel, vos fiches de cours et votre profil académique.'
                                  : context.tr('student_photo_desc')),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : const Color(0xFFCBD5E1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              _showSuccessSnackBar(
                                'Module de téléversement photo prêt (Formats acceptés : JPG, PNG).',
                              );
                            },
                            child: Text(
                              context.tr('change_image'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _showSuccessSnackBar(
                                'Photo par défaut rétablie.',
                              );
                            },
                            child: Text(
                              context.tr('delete_image'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
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
          const SizedBox(height: 20),

          // 2x2 Form grid + full width field
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 540;
              return Column(
                children: [
                  if (isWide)
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: context.tr('full_name_label'),
                            controller: _fullNameController,
                            icon: Icons.person_outline_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            label: context.tr('academic_email_label'),
                            controller: _emailController,
                            icon: Icons.mail_outline_rounded,
                            suffixBadge: context.tr('verified_label'),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildInputField(
                      label: context.tr('full_name_label'),
                      controller: _fullNameController,
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      label: context.tr('academic_email_label'),
                      controller: _emailController,
                      icon: Icons.mail_outline_rounded,
                      suffixBadge: context.tr('verified_label'),
                      isDark: isDark,
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (isWide)
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: isAdmin
                                ? 'Identifiant Administrateur (Admin ID)'
                                : (isTeacher
                                      ? 'Matricule Enseignant (PPR / Somme)'
                                      : context.tr('student_number_label')),
                            controller: _studentIdController,
                            icon: isAdmin
                                ? Icons.admin_panel_settings_outlined
                                : (isTeacher
                                      ? Icons.assignment_ind_outlined
                                      : Icons.badge_outlined),
                            trailingIcon: isAdmin
                                ? Icons.verified_user_rounded
                                : (isTeacher
                                      ? Icons.verified_user_outlined
                                      : Icons.badge_rounded),
                            isDark: isDark,
                            readOnly: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            label: isAdmin
                                ? 'Direction & Administration ENT'
                                : (isTeacher
                                      ? 'Établissement d\'affectation / Université'
                                      : context.tr('university_label')),
                            controller: _universityController,
                            icon: Icons.account_balance_outlined,
                            trailingIcon: Icons.check_circle_outline_rounded,
                            isDark: isDark,
                            readOnly: false,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildInputField(
                      label: isAdmin
                          ? 'Identifiant Administrateur (Admin ID)'
                          : (isTeacher
                                ? 'Matricule Enseignant (PPR / Somme)'
                                : context.tr('student_number_label')),
                      controller: _studentIdController,
                      icon: isAdmin
                          ? Icons.admin_panel_settings_outlined
                          : (isTeacher
                                ? Icons.assignment_ind_outlined
                                : Icons.badge_outlined),
                      trailingIcon: isAdmin
                          ? Icons.verified_user_rounded
                          : (isTeacher
                                ? Icons.verified_user_outlined
                                : Icons.badge_rounded),
                      isDark: isDark,
                      readOnly: false,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      label: isAdmin
                          ? 'Direction & Administration ENT'
                          : (isTeacher
                                ? 'Établissement d\'affectation / Université'
                                : context.tr('university_label')),
                      controller: _universityController,
                      icon: Icons.account_balance_outlined,
                      trailingIcon: Icons.check_circle_outline_rounded,
                      isDark: isDark,
                      readOnly: false,
                    ),
                  ],
                  const SizedBox(height: 14),
                  _buildInputField(
                    label: isAdmin
                        ? 'Pôle de supervision & Rôles administratifs'
                        : (isTeacher
                              ? 'Département & Discipline d\'enseignement'
                              : context.tr('major_promotion_label')),
                    controller: _majorController,
                    icon: isAdmin
                        ? Icons.security_rounded
                        : (isTeacher
                              ? Icons.domain_rounded
                              : Icons.school_outlined),
                    isDark: isDark,
                    readOnly: false,
                  ),
                  const SizedBox(height: 14),
                  _buildInputField(
                    label: isAdmin
                        ? 'Fonction & Description administrative'
                        : (isTeacher
                              ? 'Biographie & Domaines d\'expertise / Recherche'
                              : 'Biographie / Présentation académique'),
                    controller: _bioController,
                    icon: isAdmin
                        ? Icons.description_outlined
                        : (isTeacher
                              ? Icons.psychology_outlined
                              : Icons.edit_note_rounded),
                    isDark: isDark,
                    readOnly: false,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: SÉCURITÉ & AUTHENTIFICATION
  // ===========================================================================
}




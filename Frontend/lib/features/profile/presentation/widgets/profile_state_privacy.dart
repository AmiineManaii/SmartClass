// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  Widget _buildPrivacyGdprCard(Color cardBg, Color borderColor, bool isDark) {
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
          // Section Title + GDPR Badge
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
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('privacy_gdpr_title'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('privacy_gdpr_desc'),
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
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      size: 13,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('gdpr_badge'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Data Export Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.file_download_outlined,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAdmin
                                ? 'Rapport d\'Audit & Journal Administratif'
                                : isTeacher
                                ? 'Attestation d\'Exercice & Fiche de Service'
                                : context.tr('data_export_title'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAdmin
                                ? 'Générez et téléchargez le journal officiel de traçabilité, des actions administratives et de gouvernance système certifié ENT.'
                                : isTeacher
                                ? 'Générez et téléchargez votre attestation officielle d\'exercice et de charge d\'enseignement certifiée ENT au format PDF A4 officiel.'
                                : context.tr('data_export_desc'),
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
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.code_rounded, size: 16),
                      label: Text(
                        context.tr('download_json_btn'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: _isExporting
                          ? null
                          : () => _exportDataBackend(format: 'json'),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: Text(
                        isAdmin
                            ? 'Télécharger le rapport PDF'
                            : isTeacher
                            ? 'Télécharger l\'attestation PDF'
                            : context.tr('download_pdf_btn'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: _isExporting
                          ? null
                          : () => _exportDataBackend(format: 'pdf'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Visibility & Sharing Preferences
          _buildNotificationSwitchRow(
            icon: Icons.visibility_outlined,
            title: context.tr('privacy_visibility_profile'),
            subtitle: context.tr('privacy_visibility_profile_desc'),
            value: _profileVisibleToCohort,
            isDark: isDark,
            onChanged: (val) async {
              updateState(() => _profileVisibleToCohort = val);
              await _savePreferences();
              _showSuccessSnackBar(
                'Visibilité auprès des pairs mise à jour et enregistrée.',
              );
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: isTeacher ? Icons.badge_outlined : Icons.leaderboard_outlined,
            title: isTeacher
                ? 'Visibilité dans l\'annuaire des enseignants'
                : context.tr('privacy_visibility_ranking'),
            subtitle: isTeacher
                ? 'Permettre aux étudiants et collègues de consulter mes cours, coordonnées et heures de permanence.'
                : context.tr('privacy_visibility_ranking_desc'),
            value: _rankingVisible,
            isDark: isDark,
            onChanged: (val) async {
              updateState(() => _rankingVisible = val);
              await _savePreferences();
              _showSuccessSnackBar(
                isTeacher
                    ? 'Préférences d\'annuaire enseignant mises à jour et enregistrées.'
                    : 'Préférences de classement mises à jour et enregistrées.',
              );
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: Icons.share_outlined,
            title: context.tr('privacy_share_notes'),
            subtitle: context.tr('privacy_share_notes_desc'),
            value: _shareAiSummaries,
            isDark: isDark,
            onChanged: (val) async {
              updateState(() => _shareAiSummaries = val);
              await _savePreferences();
              _showSuccessSnackBar(
                'Partage des synthèses IA mis à jour et enregistré.',
              );
            },
          ),
          const SizedBox(height: 24),

          _buildPrivacyDangerZone(cardBg, borderColor, isDark),
        ],
      ),
    );
  }
}

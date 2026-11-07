// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  Widget _buildMiniMockupLines({
    required Color dotColor,
    required Color lineColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 50,
          height: 4,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // BOTTOM BAR & FOOTER
  // ===========================================================================

  Widget _buildBottomBar(Color cardBg, Color borderColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Live ENT Cloud Synchronization Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF10B981),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.cloud_done_rounded,
                  size: 15,
                  color: isDark
                      ? const Color(0xFF6EE7B7)
                      : const Color(0xFF059669),
                ),
                const SizedBox(width: 6),
                Text(
                  context.tr('last_ent_sync'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Discard / Reset button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.20)
                    : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFC),
            ),
            icon: Icon(
              Icons.restart_alt_rounded,
              size: 16,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
            onPressed: _isSaving ? null : _resetChanges,
            label: Text(
              context.tr('discard_changes'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Primary Save / Success Animated Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isSaving ? null : _saveProfile,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: _justSaved
                      ? const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_justSaved
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF2563EB))
                              .withValues(alpha: _isSaving ? 0.15 : 0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSaving) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Enregistrement en cours...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ] else if (_justSaved) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Modifications enregistrées !',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.save_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.tr('save_changes'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLinks(Color textMuted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SmartClass © 2026 Plateforme Numérique d\'Enseignement Supérieur et Secondaire',
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
        Row(
          children: [
            InkWell(
              onTap: () {},
              child: Text(
                'Politique de confidentialité',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '•',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ),
            InkWell(
              onTap: () {},
              child: Text(
                'Conditions académiques',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '•',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ),
            InkWell(
              onTap: () {},
              child: Text(
                'Support technique',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}




// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? suffixBadge,
    IconData? trailingIcon,
    required bool isDark,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: readOnly
                ? (isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                      : const Color(0xFFF1F5F9))
                : (isDark ? const Color(0xFF0F172A) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  readOnly: readOnly,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  // IMPORTANT: All borders explicitly set to InputBorder.none
                  // to prevent double-border outline inheritance from theme.
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (suffixBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: Color(0xFF15803D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        suffixBadge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              if (trailingIcon != null)
                Icon(
                  trailingIcon,
                  size: 17,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    String? badge,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
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
        Switch(
          value: value,
          activeThumbColor: const Color(0xFF2563EB),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildThemePreviewCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    bool isDarkCard = false,
    bool isSplitCard = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini UI Mockup container
            Container(
              height: 74,
              decoration: BoxDecoration(
                color: isDarkCard
                    ? const Color(0xFF1E293B)
                    : (isSplitCard
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDarkCard
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: isSplitCard
                  ? Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(9),
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: _buildMiniMockupLines(
                              dotColor: const Color(0xFF2563EB),
                              lineColor: const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(9),
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: _buildMiniMockupLines(
                              dotColor: const Color(0xFF60A5FA),
                              lineColor: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(10),
                      child: _buildMiniMockupLines(
                        dotColor: isDarkCard
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF2563EB),
                        lineColor: isDarkCard
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
            ),
            const SizedBox(height: 10),

            // Radio + Title + Subtitle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                      width: isSelected ? 5 : 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}




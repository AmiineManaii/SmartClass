part of '../pages/videoconference_page.dart';
extension on _VideoconferencePageState {
  Widget _buildHeroBanner(
    BuildContext context,
    bool isTeacher,
    bool isDark,
    bool isWide,
    double horizontalPadding,
  ) {
    return Container(
      margin: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 4),
      padding: EdgeInsets.all(isWide ? 22 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E1B4B)]
              : const [Color(0xFF122675), Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF122675).withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Faint decorative glow circle in corner
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Main banner contents
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Branding, Title, Description, and Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeroHeaderRow(context, isDark),
                      const SizedBox(height: 10),
                      Text(
                        'Participez ou animez des s├®ances interactives avec streaming vid├®o temps r├®el, chat, partage d\'├®cran et ├®margement.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureChipsRow(),
                    ],
                  ),
                ),

                // Right Column: Teacher Actions Dock
                if (isTeacher) ...[
                  const SizedBox(width: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF122675),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: const Text(
                        'Programmer une s├®ance',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () => _openScheduleDialog(liveNow: false),
                    ),
                  ),
                ],
              ],
            )
          else
            // Mobile vertical stack
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeroHeaderRow(context, isDark),
                const SizedBox(height: 10),
                Text(
                  'Participez ou animez des s├®ances interactives avec streaming vid├®o temps r├®el, chat, partage d\'├®cran et ├®margement.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeatureChipsRow(),
                if (isTeacher) ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF122675),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: const Text(
                      'Programmer une s├®ance',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    onPressed: () => _openScheduleDialog(liveNow: false),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

}

part of '../pages/videoconference_page.dart';
extension on _VideoconferencePageState {
  Widget _buildSegmentedTabs(BuildContext context, bool isDark, {required bool isWide}) {
    final activeIndex = _tabController.index;

    final tabs = [
      {
        'title': 'En direct',
        'tooltip': 'En direct',
        'icon': Icons.sensors_rounded,
        'selectedIcon': Icons.sensors_rounded,
        'activeColor': const Color(0xFFEF4444),
        'isLive': true,
      },
      {
        'title': 'Programm├®es',
        'tooltip': 'Programm├®es',
        'icon': Icons.calendar_today_outlined,
        'selectedIcon': Icons.calendar_month_rounded,
        'activeColor': isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
        'isLive': false,
      },
      {
        'title': 'Historique',
        'tooltip': 'Historique',
        'icon': Icons.history_rounded,
        'selectedIcon': Icons.history_toggle_off_rounded,
        'activeColor': isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        'isLive': false,
      },
    ];

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2F) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = activeIndex == idx;
          final item = tabs[idx];
          final isLive = item['isLive'] as bool;
          final activeColor = item['activeColor'] as Color;
          final title = item['title'] as String;

          return Expanded(
            child: Tooltip(
              message: item['tooltip'] as String,
              child: GestureDetector(
                onTap: () => _tabController.animateTo(idx),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isDark ? Colors.black : const Color(0xFF0F172A))
                                  .withValues(alpha: isDark ? 0.35 : 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            (isSelected ? item['selectedIcon'] : item['icon']) as IconData,
                            size: 18,
                            color: isSelected
                                ? activeColor
                                : (isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8)),
                          ),
                          if (isLive)
                            Positioned(
                              top: -2,
                              right: -3,
                              child: Container(
                                width: 6.5,
                                height: 6.5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                                      blurRadius: 4,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}


part of '../pages/videoconference_page.dart';
extension on _VideoconferencePageState {
  Widget _buildFeatureChipsRow() {
    final chips = [
      {'label': '1080p SFU', 'icon': Icons.hd_rounded},
      {'label': '< 100ms', 'icon': Icons.bolt_rounded},
      {'label': 'Partage & Laser', 'icon': Icons.draw_rounded},
      {'label': 'Chiffr├® E2E', 'icon': Icons.lock_outline_rounded},
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips.map((c) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(c['icon'] as IconData, size: 11, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 4),
              Text(
                c['label'] as String,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

}

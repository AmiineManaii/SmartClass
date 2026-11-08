import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class ReplayTimelineBar extends StatelessWidget {
  final double posSec;
  final double maxDur;
  final bool isPlaying;
  final bool subtitlesOn;
  final double speed;
  final ValueChanged<double> onSeek;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleSubtitles;
  final ValueChanged<double> onSpeedChanged;

  const ReplayTimelineBar({
    super.key,
    required this.posSec,
    required this.maxDur,
    required this.isPlaying,
    required this.subtitlesOn,
    required this.speed,
    required this.onSeek,
    required this.onTogglePlay,
    required this.onToggleSubtitles,
    required this.onSpeedChanged,
  });

  String _formatClock(double totalSec) {
    final s = totalSec.floor();
    final m = s ~/ 60;
    final r = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = r.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      color: const Color(0xFF111827),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 12,
              ),
            ),
            child: Slider(
              value: posSec.clamp(0.0, maxDur),
              min: 0.0,
              max: maxDur > 0 ? maxDur : 1.0,
              activeColor: const Color(0xFF2563EB),
              inactiveColor: const Color(0xFF334155),
              onChanged: onSeek,
            ),
          ),
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 34,
                  minHeight: 34,
                ),
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  color: const Color(0xFF3B82F6),
                  size: 28,
                ),
                onPressed: onTogglePlay,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                tooltip: '-10s',
                icon: const Icon(
                  Icons.replay_10_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                onPressed: () => onSeek((posSec - 10).clamp(0.0, maxDur)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                tooltip: '+10s',
                icon: const Icon(
                  Icons.forward_10_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                onPressed: () => onSeek((posSec + 10).clamp(0.0, maxDur)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_formatClock(posSec)} / ${_formatClock(maxDur)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                tooltip: context.tr('replay_subtitles'),
                icon: Icon(
                  subtitlesOn
                      ? Icons.subtitles_rounded
                      : Icons.subtitles_off_outlined,
                  color: subtitlesOn
                      ? const Color(0xFF38BDF8)
                      : Colors.white54,
                  size: 18,
                ),
                onPressed: onToggleSubtitles,
              ),
              const SizedBox(width: 4),
              PopupMenuButton<double>(
                tooltip: context.tr('replay_speed'),
                initialValue: speed,
                onSelected: onSpeedChanged,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 0.75, child: Text('0.75x')),
                  PopupMenuItem(value: 1.0, child: Text('1.0x')),
                  PopupMenuItem(value: 1.25, child: Text('1.25x')),
                  PopupMenuItem(value: 1.5, child: Text('1.5x')),
                  PopupMenuItem(value: 2.0, child: Text('2.0x')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${speed}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ModePillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ModePillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class ReplayTimelineBar extends StatelessWidget {
  final double posSec;
  final double maxDur;
  final bool isPlaying;
  final bool subtitlesOn;
  final double speed;
  final double volume;
  final bool isMuted;
  final List<double> chapterMarkerSeconds;
  final bool isTheaterMode;
  final bool isFullscreen;
  final ValueChanged<double> onSeek;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleSubtitles;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback? onToggleMute;
  final ValueChanged<double>? onVolumeChanged;
  final VoidCallback? onToggleTheater;
  final VoidCallback? onToggleFullscreen;

  const ReplayTimelineBar({
    super.key,
    required this.posSec,
    required this.maxDur,
    required this.isPlaying,
    required this.subtitlesOn,
    required this.speed,
    this.volume = 1.0,
    this.isMuted = false,
    this.chapterMarkerSeconds = const [],
    this.isTheaterMode = false,
    this.isFullscreen = false,
    required this.onSeek,
    required this.onTogglePlay,
    required this.onToggleSubtitles,
    required this.onSpeedChanged,
    this.onToggleMute,
    this.onVolumeChanged,
    this.onToggleTheater,
    this.onToggleFullscreen,
  });

  String _formatClock(double totalSec) {
    final s = totalSec.floor().clamp(0, 86400);
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final r = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = r.toString().padLeft(2, '0');
    if (h > 0) return '$h:$mm:$ss';
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMax = maxDur > 0 ? maxDur : 1.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isFullscreen ? 20 : 12,
        6,
        isFullscreen ? 20 : 12,
        isFullscreen ? 12 : 9,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E1626), Color(0xFF090E1A)],
        ),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final showSkipButtons = maxW >= 365;
          final showVolumeIcon = maxW >= 400;
          final showVolumeSlider = maxW >= 520;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Interactive Scrubber with Chapter Marker Notches
              SizedBox(
                height: 22,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Chapter notch pins along timeline
                    if (chapterMarkerSeconds.isNotEmpty && maxDur > 0)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: LayoutBuilder(
                            builder: (_, barConstraints) {
                              return Stack(
                                alignment: Alignment.centerLeft,
                                children: chapterMarkerSeconds
                                    .where((sec) => sec > 0 && sec < maxDur)
                                    .map((sec) {
                                  final frac = (sec / maxDur).clamp(0.0, 1.0);
                                  return Positioned(
                                    left: barConstraints.maxWidth * frac - 1,
                                    child: Container(
                                      width: 2.5,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: isFullscreen ? 5 : 4,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: isFullscreen ? 7 : 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 13,
                        ),
                        activeTrackColor: const Color(0xFF3B82F6),
                        inactiveTrackColor:
                            const Color(0xFF334155).withValues(alpha: 0.7),
                        thumbColor: const Color(0xFF60A5FA),
                        overlayColor:
                            const Color(0xFF3B82F6).withValues(alpha: 0.25),
                      ),
                      child: Slider(
                        value: posSec.clamp(0.0, effectiveMax),
                        min: 0.0,
                        max: effectiveMax,
                        onChanged: onSeek,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Cinema Transport Row
              Row(
                children: [
                  // Glowing Play / Pause button
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onTogglePlay,
                    child: Container(
                      width: isFullscreen ? 38 : 34,
                      height: isFullscreen ? 38 : 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6)
                                .withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: isFullscreen ? 23 : 20,
                      ),
                    ),
                  ),
                  if (showSkipButtons) ...[
                    const SizedBox(width: 4),
                    _TransportIconButton(
                      icon: Icons.replay_10_rounded,
                      tooltip: '-10s',
                      onPressed: () =>
                          onSeek((posSec - 10).clamp(0.0, effectiveMax)),
                    ),
                    _TransportIconButton(
                      icon: Icons.forward_10_rounded,
                      tooltip: '+10s',
                      onPressed: () =>
                          onSeek((posSec + 10).clamp(0.0, effectiveMax)),
                    ),
                  ],
                  const SizedBox(width: 6),
                  // Timecode pill (flexibly fills available gap so narrow widths never overflow)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF1E293B).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Text(
                            '${_formatClock(posSec)} / ${_formatClock(maxDur)}',
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Volume + Mute
                  if (showVolumeIcon && onToggleMute != null) ...[
                    const SizedBox(width: 4),
                    _TransportIconButton(
                      icon: (isMuted || volume <= 0.01)
                          ? Icons.volume_off_rounded
                          : (volume < 0.5
                              ? Icons.volume_down_rounded
                              : Icons.volume_up_rounded),
                      tooltip: isMuted ? 'Activer le son' : 'Couper le son',
                      color: (isMuted || volume <= 0.01)
                          ? const Color(0xFFF87171)
                          : Colors.white70,
                      onPressed: onToggleMute!,
                    ),
                    if (showVolumeSlider && onVolumeChanged != null)
                      SizedBox(
                        width: 72,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 4.5,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 9,
                            ),
                            activeTrackColor: const Color(0xFF94A3B8),
                            inactiveTrackColor: const Color(0xFF334155),
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: isMuted ? 0.0 : volume.clamp(0.0, 1.0),
                            min: 0.0,
                            max: 1.0,
                            onChanged: onVolumeChanged,
                          ),
                        ),
                      ),
                  ],

                  const SizedBox(width: 4),

                  // Subtitles toggle
                  _TransportIconButton(
                    icon: subtitlesOn
                        ? Icons.subtitles_rounded
                        : Icons.subtitles_off_outlined,
                    tooltip: context.tr('replay_subtitles'),
                    color: subtitlesOn
                        ? const Color(0xFF38BDF8)
                        : Colors.white54,
                    active: subtitlesOn,
                    onPressed: onToggleSubtitles,
                  ),
                  const SizedBox(width: 4),

                  // Speed Selector
                  PopupMenuButton<double>(
                    tooltip: context.tr('replay_speed'),
                    initialValue: speed,
                    onSelected: onSpeedChanged,
                    color: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 0.75,
                        child: Text('0.75x',
                            style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 1.0,
                        child: Text('1.0x (Normal)',
                            style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 1.25,
                        child: Text('1.25x',
                            style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 1.5,
                        child: Text('1.5x',
                            style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 2.0,
                        child: Text('2.0x',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: speed != 1.0
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        '${speed}x',
                        style: TextStyle(
                          color: speed != 1.0
                              ? const Color(0xFF60A5FA)
                              : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  // Theater / Cinema Mode button
                  if (onToggleTheater != null && !isFullscreen) ...[
                    const SizedBox(width: 4),
                    _TransportIconButton(
                      icon: isTheaterMode
                          ? Icons.view_sidebar_outlined
                          : Icons.crop_16_9_rounded,
                      tooltip: isTheaterMode
                          ? 'Vue partagée'
                          : 'Mode Cinéma (agrandir)',
                      color: isTheaterMode
                          ? const Color(0xFF38BDF8)
                          : Colors.white70,
                      active: isTheaterMode,
                      onPressed: onToggleTheater!,
                    ),
                  ],

                  // Fullscreen button
                  if (onToggleFullscreen != null) ...[
                    const SizedBox(width: 4),
                    _TransportIconButton(
                      icon: isFullscreen
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      tooltip: isFullscreen
                          ? 'Quitter le plein écran (Échap)'
                          : 'Plein écran',
                      color: Colors.white,
                      active: isFullscreen,
                      onPressed: onToggleFullscreen!,
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TransportIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;
  final bool active;

  const _TransportIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = Colors.white70,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active
                ? Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 18),
        ),
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
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                )
              : null,
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

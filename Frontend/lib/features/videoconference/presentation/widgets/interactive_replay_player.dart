import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../application/recording_providers.dart';
import '../../domain/entities/recording_models.dart';
import 'replay_timeline_bar.dart';
import 'replay_video_surface.dart';

/// Interactive Lecture Replay Player supporting:
/// - Real HTML5 `<video>` HTTP Range streaming (`lecture.mp4`) + extracted JPEG slide frames
/// - Mode switcher between "Vidéo HD" and "Diapositive IA"
/// - Synchronized playback clock with variable speed (0.75x - 2.0x)
/// - Visual chapter markers, important moment pins, and student bookmarks on timeline
/// - Live subtitle overlay from transcript segments
class InteractiveReplayPlayer extends ConsumerStatefulWidget {
  final String sessionId;
  final String sessionTitle;
  final SessionRecordingEntity? recording;
  final RecordingTranscriptEntity? transcript;
  final List<LessonChapterEntity> chapters;
  final List<SlideSegmentEntity> slides;
  final List<StudentBookmarkEntity> bookmarks;
  final ValueChanged<double>? onPositionChanged;

  const InteractiveReplayPlayer({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
    this.recording,
    this.transcript,
    this.chapters = const [],
    this.slides = const [],
    this.bookmarks = const [],
    this.onPositionChanged,
  });

  @override
  ConsumerState<InteractiveReplayPlayer> createState() =>
      _InteractiveReplayPlayerState();
}

class _InteractiveReplayPlayerState
    extends ConsumerState<InteractiveReplayPlayer> {
  Timer? _playbackTicker;
  bool _showSlideMode = false;

  double get _totalDurationSec {
    final recDuration = widget.recording?.durationSeconds?.toDouble();
    if (recDuration != null && recDuration > 0) return recDuration;
    if (widget.chapters.isNotEmpty) {
      return widget.chapters.last.endSec > 0
          ? widget.chapters.last.endSec
          : 72.0;
    }
    if (widget.transcript != null && widget.transcript!.segments.isNotEmpty) {
      return widget.transcript!.segments.last.endSec > 0
          ? widget.transcript!.segments.last.endSec
          : 72.0;
    }
    return 72.0;
  }

  @override
  void dispose() {
    _playbackTicker?.cancel();
    super.dispose();
  }

  void _syncTicker(bool isPlaying) {
    _playbackTicker?.cancel();
    if (!isPlaying) return;

    _playbackTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      final speed = ref.read(replaySpeedProvider(widget.sessionId));
      final current = ref.read(replayPositionSecondsProvider(widget.sessionId));
      final maxDur = _totalDurationSec;
      final next = (current + 0.5 * speed).clamp(0.0, maxDur);

      ref.read(replayPositionSecondsProvider(widget.sessionId).notifier).state =
          next;
      widget.onPositionChanged?.call(next);

      if (next >= maxDur) {
        ref.read(replayIsPlayingProvider(widget.sessionId).notifier).state =
            false;
        _playbackTicker?.cancel();
      }
    });
  }

  void _seekTo(double seconds) {
    final clamped = seconds.clamp(0.0, _totalDurationSec);
    ref.read(replayPositionSecondsProvider(widget.sessionId).notifier).state =
        clamped;
    widget.onPositionChanged?.call(clamped);
  }

  LessonChapterEntity? _activeChapter(double posSec) {
    for (final ch in widget.chapters) {
      if (posSec >= ch.startSec && posSec <= ch.endSec) return ch;
    }
    return widget.chapters.isNotEmpty ? widget.chapters.first : null;
  }

  SlideSegmentEntity? _activeSlide(double posSec) {
    for (final s in widget.slides) {
      if (posSec >= s.timestampSec && posSec <= s.endTimestampSec) return s;
    }
    return widget.slides.isNotEmpty ? widget.slides.first : null;
  }

  TranscriptSegmentEntity? _activeSubtitle(double posSec) {
    final segments = widget.transcript?.segments ?? const [];
    for (final seg in segments) {
      if (posSec >= seg.startSec && posSec <= seg.endSec) return seg;
    }
    return null;
  }

  String _formatClock(double seconds) {
    final total = seconds.round().clamp(0, 86400);
    final hrs = total ~/ 3600;
    final mins = (total % 3600) ~/ 60;
    final secs = total % 60;
    final mStr = mins.toString().padLeft(2, '0');
    final sStr = secs.toString().padLeft(2, '0');
    if (hrs > 0) return '$hrs:$mStr:$sStr';
    return '$mStr:$sStr';
  }

  @override
  Widget build(BuildContext context) {
    final posSec = ref.watch(replayPositionSecondsProvider(widget.sessionId));
    final isPlaying = ref.watch(replayIsPlayingProvider(widget.sessionId));
    final speed = ref.watch(replaySpeedProvider(widget.sessionId));
    final subtitlesOn =
        ref.watch(replaySubtitlesEnabledProvider(widget.sessionId));
    final accessToken =
        ref.watch(recordingAccessTokenProvider).valueOrNull;
    final recordingDs = ref.watch(recordingRemoteDataSourceProvider);

    final activeChapter = _activeChapter(posSec);
    final activeSlide = _activeSlide(posSec);
    final activeSubtitle = _activeSubtitle(posSec);
    final maxDur = _totalDurationSec;

    final streamPath = widget.recording?.streamUrl.isNotEmpty == true
        ? widget.recording!.streamUrl
        : '/api/v1/videoconference/sessions/${widget.sessionId}/recording/stream';
    final posterPath = widget.recording?.posterUrl ??
        '/api/v1/videoconference/sessions/${widget.sessionId}/recording/poster';

    final videoUrl = accessToken != null
        ? recordingDs.buildAuthenticatedStreamUrl(streamPath, accessToken)
        : '';
    final posterUrl = accessToken != null
        ? recordingDs.buildAuthenticatedStreamUrl(posterPath, accessToken)
        : '';
    final slideIdx = activeSlide?.slideIndex ?? 0;
    final activeFrameUrl = accessToken != null
        ? recordingDs.buildAuthenticatedFrameUrl(
            widget.sessionId,
            slideIdx,
            accessToken,
          )
        : '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1E293B).withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 16:9 Video & Visual Slide Stage
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Base dark stage
                const ColoredBox(color: Color(0xFF090D16)),

                // Real Playable Video Stream (or Slide Frame mode)
                if (!_showSlideMode && videoUrl.isNotEmpty)
                  ReplayVideoSurface(
                    videoUrl: videoUrl,
                    posterUrl: posterUrl,
                    activeFrameUrl: activeFrameUrl,
                    isPlaying: isPlaying,
                    positionSeconds: posSec,
                    playbackSpeed: speed,
                  )
                else if (activeFrameUrl.isNotEmpty)
                  Image.network(
                    activeFrameUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.expand(),
                  ),

                // Optional Slide Inspection Card (only when user switches to "Diapositive IA")
                if (_showSlideMode)
                  Container(
                    color: const Color(0xFF090D16).withValues(alpha: 0.72),
                    padding: const EdgeInsets.fromLTRB(24, 52, 24, 52),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111C2D).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                activeSlide?.extractedText.isNotEmpty == true
                                    ? activeSlide!.extractedText
                                    : (activeChapter?.title ?? widget.sessionTitle),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (activeSlide?.visualExplanation.isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 8),
                                Text(
                                  activeSlide!.visualExplanation,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Top Glassmorphic Bar: Chapter Badge & Video / Slide Mode Switcher
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF38BDF8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  activeChapter != null
                                      ? activeChapter.title
                                      : widget.sessionTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Stitch Mode Switcher: Vidéo HD vs Diapositive IA
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ModePillButton(
                              icon: Icons.videocam_rounded,
                              label: 'Vidéo HD',
                              selected: !_showSlideMode,
                              onTap: () => setState(() => _showSlideMode = false),
                            ),
                            ModePillButton(
                              icon: Icons.slideshow_rounded,
                              label: 'Slide #${slideIdx + 1}',
                              selected: _showSlideMode,
                              onTap: () => setState(() => _showSlideMode = true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Live Subtitles Overlay
                if (subtitlesOn && activeSubtitle != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 10,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF090D16).withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          activeSubtitle.text,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Chapter Quick-Jump Strip
          if (widget.chapters.isNotEmpty)
            Container(
              height: 32,
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.chapters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, idx) {
                  final ch = widget.chapters[idx];
                  final isCurrent = activeChapter?.id == ch.id;
                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _seekTo(ch.startSec),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${_formatClock(ch.startSec)} • ${ch.title}',
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.white
                              : const Color(0xFFCBD5E1),
                          fontSize: 10.5,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Transport & Timeline Controls Bar
          ReplayTimelineBar(
            posSec: posSec,
            maxDur: maxDur,
            isPlaying: isPlaying,
            subtitlesOn: subtitlesOn,
            speed: speed,
            onSeek: _seekTo,
            onTogglePlay: () {
              final next = !isPlaying;
              ref
                  .read(
                    replayIsPlayingProvider(widget.sessionId).notifier,
                  )
                  .state = next;
              _syncTicker(next);
            },
            onToggleSubtitles: () {
              ref
                  .read(
                    replaySubtitlesEnabledProvider(widget.sessionId)
                        .notifier,
                  )
                  .state = !subtitlesOn;
            },
            onSpeedChanged: (val) {
              ref
                  .read(replaySpeedProvider(widget.sessionId).notifier)
                  .state = val;
            },
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/recording_providers.dart';
import '../../domain/entities/recording_models.dart';
import 'replay_timeline_bar.dart';
import 'replay_video_surface.dart';

/// Interactive Lecture Replay Player supporting:
/// - Real HTML5 `<video>` HTTP Range streaming (`lecture.mp4`) + extracted JPEG slide frames
/// - Mode switcher between "Vidéo HD" and "Slide IA"
/// - Synchronized playback clock with variable speed (0.75x - 2.0x) & volume/mute
/// - Visual chapter markers & quick-jump pills
/// - Live subtitle overlay from transcript segments
/// - Mode Cinéma (Theater expanded view) & true Fullscreen Cinema modal with keyboard shortcuts
class InteractiveReplayPlayer extends ConsumerStatefulWidget {
  final String sessionId;
  final String sessionTitle;
  final SessionRecordingEntity? recording;
  final RecordingTranscriptEntity? transcript;
  final List<LessonChapterEntity> chapters;
  final List<SlideSegmentEntity> slides;
  final List<StudentBookmarkEntity> bookmarks;
  final ValueChanged<double>? onPositionChanged;
  final bool enableTheaterToggle;
  final bool isFullscreenOverlay;
  final VoidCallback? onCloseFullscreen;

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
    this.enableTheaterToggle = false,
    this.isFullscreenOverlay = false,
    this.onCloseFullscreen,
  });

  @override
  ConsumerState<InteractiveReplayPlayer> createState() =>
      _InteractiveReplayPlayerState();
}

class _InteractiveReplayPlayerState
    extends ConsumerState<InteractiveReplayPlayer> {
  Timer? _playbackTicker;
  bool _showSlideMode = false;
  double? _detectedDurationSec;
  DateTime? _lastNativeTimeUpdate;

  double get _totalDurationSec {
    if (_detectedDurationSec != null && _detectedDurationSec! > 0) {
      return _detectedDurationSec!;
    }
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
      // If the real HTML5 <video> element is actively emitting time updates,
      // let the video clock be the single source of truth.
      if (_lastNativeTimeUpdate != null &&
          DateTime.now().difference(_lastNativeTimeUpdate!).inMilliseconds <
              1200) {
        return;
      }
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

  void _togglePlay() {
    final isPlaying = ref.read(replayIsPlayingProvider(widget.sessionId));
    final next = !isPlaying;
    ref.read(replayIsPlayingProvider(widget.sessionId).notifier).state = next;
    _syncTicker(next);
  }

  Future<void> _openFullscreenCinema() async {
    if (widget.isFullscreenOverlay) {
      exitBrowserFullscreen();
      widget.onCloseFullscreen?.call();
      return;
    }

    ref.read(replayFullscreenOpenProvider(widget.sessionId).notifier).state =
        true;
    enterBrowserFullscreen();

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Plein écran',
      barrierColor: const Color(0xF504070F),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogCtx, _, _) {
        return _CinemaFullscreenDialog(
          sessionId: widget.sessionId,
          sessionTitle: widget.sessionTitle,
          recording: widget.recording,
          transcript: widget.transcript,
          chapters: widget.chapters,
          slides: widget.slides,
          bookmarks: widget.bookmarks,
          onPositionChanged: widget.onPositionChanged,
        );
      },
      transitionBuilder: (_, anim, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );

    exitBrowserFullscreen();
    if (mounted) {
      ref.read(replayFullscreenOpenProvider(widget.sessionId).notifier).state =
          false;
    }
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
    final volume = ref.watch(replayVolumeProvider(widget.sessionId));
    final isMuted = ref.watch(replayMutedProvider(widget.sessionId));
    final isTheater = ref.watch(replayTheaterModeProvider(widget.sessionId));
    final fullscreenOpen =
        ref.watch(replayFullscreenOpenProvider(widget.sessionId));
    final accessToken = ref.watch(recordingAccessTokenProvider).valueOrNull;
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

    final hideInlineVideo = !widget.isFullscreenOverlay && fullscreenOpen;
    final chapterMarkers =
        widget.chapters.map((c) => c.startSec).toList(growable: false);

    final videoStage = Stack(
      fit: StackFit.expand,
      children: [
        // Deep cinema backdrop
        const ColoredBox(color: Color(0xFF050811)),

        if (hideInlineVideo)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fullscreen_rounded,
                    color: Color(0xFF60A5FA),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Lecture en plein écran active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else if (!_showSlideMode && videoUrl.isNotEmpty)
          ReplayVideoSurface(
            videoUrl: videoUrl,
            posterUrl: posterUrl,
            activeFrameUrl: activeFrameUrl,
            isPlaying: isPlaying,
            positionSeconds: posSec,
            playbackSpeed: speed,
            volume: volume,
            isMuted: isMuted,
            onDurationDetected: (dur) {
              if (mounted && dur > 0) {
                setState(() => _detectedDurationSec = dur);
              }
            },
            onTimeUpdate: (sec) {
              if (!mounted) return;
              _lastNativeTimeUpdate = DateTime.now();
              final current =
                  ref.read(replayPositionSecondsProvider(widget.sessionId));
              if ((sec - current).abs() >= 0.25) {
                ref
                    .read(
                      replayPositionSecondsProvider(widget.sessionId).notifier,
                    )
                    .state = sec;
                widget.onPositionChanged?.call(sec);
              }
            },
            onEnded: () {
              if (!mounted) return;
              ref
                  .read(replayIsPlayingProvider(widget.sessionId).notifier)
                  .state = false;
              _playbackTicker?.cancel();
            },
          )
        else if (activeFrameUrl.isNotEmpty)
          Image.network(
            activeFrameUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.expand(),
          ),

        // Subtle top vignette for crisp readability of overlay badges
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 76,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.68),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Subtle bottom vignette behind subtitles
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 70,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Optional Slide Inspection Card (when switched to Slide IA)
        if (_showSlideMode && !hideInlineVideo)
          Container(
            color: const Color(0xFF050811).withValues(alpha: 0.72),
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 56),
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 640),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
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
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Top Glassmorphic Bar: Chapter Badge + Vidéo HD / Slide Switcher + Quick Expand
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1120).withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.7),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          activeChapter != null
                              ? activeChapter.title
                              : widget.sessionTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Mode Switcher: Vidéo HD vs Slide IA
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1120).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
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
              const SizedBox(width: 6),
              // Quick Fullscreen / Close floating pill right on the video corner
              Material(
                color: const Color(0xFF0B1120).withValues(alpha: 0.88),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _openFullscreenCinema,
                  child: Tooltip(
                    message: widget.isFullscreenOverlay
                        ? 'Quitter le plein écran (Échap)'
                        : 'Agrandir en plein écran',
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Icon(
                        widget.isFullscreenOverlay
                            ? Icons.close_fullscreen_rounded
                            : Icons.open_in_full_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Live Subtitles Overlay
        if (subtitlesOn && activeSubtitle != null && !hideInlineVideo)
          Positioned(
            left: 18,
            right: 18,
            bottom: widget.isFullscreenOverlay ? 18 : 10,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: widget.isFullscreenOverlay ? 820 : 540,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isFullscreenOverlay ? 18 : 14,
                    vertical: widget.isFullscreenOverlay ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050811).withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    activeSubtitle.text,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.isFullscreenOverlay ? 16 : 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF050811),
        borderRadius: BorderRadius.circular(widget.isFullscreenOverlay ? 16 : 18),
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.75),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize:
            widget.isFullscreenOverlay ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // Video Stage: expands to fill screen in fullscreen mode, or 16:9 inline
          if (widget.isFullscreenOverlay)
            Expanded(child: videoStage)
          else
            AspectRatio(aspectRatio: 16 / 9, child: videoStage),

          // Chapter Quick-Jump Strip
          if (widget.chapters.isNotEmpty)
            Container(
              height: widget.isFullscreenOverlay ? 40 : 34,
              color: const Color(0xFF0B1120),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        gradient: isCurrent
                            ? const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                              )
                            : null,
                        color: isCurrent ? null : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0xFF60A5FA).withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${_formatClock(ch.startSec)} • ${ch.title}',
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.white
                              : const Color(0xFFCBD5E1),
                          fontSize: widget.isFullscreenOverlay ? 11.5 : 10.5,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Cinema Transport & Timeline Controls Bar
          ReplayTimelineBar(
            posSec: posSec,
            maxDur: maxDur,
            isPlaying: isPlaying,
            subtitlesOn: subtitlesOn,
            speed: speed,
            volume: volume,
            isMuted: isMuted,
            chapterMarkerSeconds: chapterMarkers,
            isTheaterMode: isTheater,
            isFullscreen: widget.isFullscreenOverlay,
            onSeek: _seekTo,
            onTogglePlay: _togglePlay,
            onToggleSubtitles: () {
              ref
                  .read(
                    replaySubtitlesEnabledProvider(widget.sessionId).notifier,
                  )
                  .state = !subtitlesOn;
            },
            onSpeedChanged: (val) {
              ref.read(replaySpeedProvider(widget.sessionId).notifier).state =
                  val;
            },
            onToggleMute: () {
              ref.read(replayMutedProvider(widget.sessionId).notifier).state =
                  !isMuted;
            },
            onVolumeChanged: (val) {
              ref.read(replayVolumeProvider(widget.sessionId).notifier).state =
                  val;
              if (val > 0.01 && isMuted) {
                ref.read(replayMutedProvider(widget.sessionId).notifier).state =
                    false;
              }
            },
            onToggleTheater: widget.enableTheaterToggle
                ? () {
                    ref
                        .read(
                          replayTheaterModeProvider(widget.sessionId).notifier,
                        )
                        .state = !isTheater;
                  }
                : null,
            onToggleFullscreen: _openFullscreenCinema,
          ),
        ],
      ),
    );
  }
}

class _CinemaFullscreenDialog extends ConsumerStatefulWidget {
  final String sessionId;
  final String sessionTitle;
  final SessionRecordingEntity? recording;
  final RecordingTranscriptEntity? transcript;
  final List<LessonChapterEntity> chapters;
  final List<SlideSegmentEntity> slides;
  final List<StudentBookmarkEntity> bookmarks;
  final ValueChanged<double>? onPositionChanged;

  const _CinemaFullscreenDialog({
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
  ConsumerState<_CinemaFullscreenDialog> createState() =>
      _CinemaFullscreenDialogState();
}

class _CinemaFullscreenDialogState
    extends ConsumerState<_CinemaFullscreenDialog> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      final curr = ref.read(replayIsPlayingProvider(widget.sessionId));
      ref.read(replayIsPlayingProvider(widget.sessionId).notifier).state =
          !curr;
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final pos = ref.read(replayPositionSecondsProvider(widget.sessionId));
      ref.read(replayPositionSecondsProvider(widget.sessionId).notifier).state =
          (pos - 5).clamp(0.0, 86400.0);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final pos = ref.read(replayPositionSecondsProvider(widget.sessionId));
      ref.read(replayPositionSecondsProvider(widget.sessionId).notifier).state =
          (pos + 5).clamp(0.0, 86400.0);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyM) {
      final muted = ref.read(replayMutedProvider(widget.sessionId));
      ref.read(replayMutedProvider(widget.sessionId).notifier).state = !muted;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: InteractiveReplayPlayer(
              sessionId: widget.sessionId,
              sessionTitle: widget.sessionTitle,
              recording: widget.recording,
              transcript: widget.transcript,
              chapters: widget.chapters,
              slides: widget.slides,
              bookmarks: widget.bookmarks,
              onPositionChanged: widget.onPositionChanged,
              isFullscreenOverlay: true,
              onCloseFullscreen: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}

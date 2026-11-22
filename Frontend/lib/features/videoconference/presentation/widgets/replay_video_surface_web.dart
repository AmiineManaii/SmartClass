// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

void enterBrowserFullscreen() {
  try {
    if (html.document.fullscreenElement == null) {
      html.document.documentElement?.requestFullscreen();
    }
  } catch (_) {}
}

void exitBrowserFullscreen() {
  try {
    if (html.document.fullscreenElement != null) {
      html.document.exitFullscreen();
    }
  } catch (_) {}
}

class ReplayVideoSurface extends StatefulWidget {
  final String videoUrl;
  final String posterUrl;
  final String? activeFrameUrl;
  final bool isPlaying;
  final double positionSeconds;
  final double playbackSpeed;
  final double volume;
  final bool isMuted;
  final ValueChanged<double>? onTimeUpdate;
  final ValueChanged<double>? onDurationDetected;
  final VoidCallback? onEnded;

  const ReplayVideoSurface({
    super.key,
    required this.videoUrl,
    required this.posterUrl,
    this.activeFrameUrl,
    required this.isPlaying,
    required this.positionSeconds,
    required this.playbackSpeed,
    this.volume = 1.0,
    this.isMuted = false,
    this.onTimeUpdate,
    this.onDurationDetected,
    this.onEnded,
  });

  @override
  State<ReplayVideoSurface> createState() => _ReplayVideoSurfaceState();
}

class _ReplayVideoSurfaceState extends State<ReplayVideoSurface> {
  static final Set<String> _registeredViews = <String>{};
  late final String _viewType;
  html.VideoElement? _videoElement;

  @override
  void initState() {
    super.initState();
    _viewType =
        'smartclass-replay-video-${widget.videoUrl.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
    _initVideoElement();
  }

  void _initVideoElement() {
    final video = html.VideoElement()
      ..src = widget.videoUrl
      ..poster = widget.posterUrl
      ..controls = false
      ..autoplay = false
      ..preload = 'metadata'
      ..crossOrigin = 'anonymous'
      ..volume = widget.volume.clamp(0.0, 1.0)
      ..muted = widget.isMuted
      ..playbackRate = widget.playbackSpeed
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'contain'
      ..style.backgroundColor = '#050811'
      ..style.border = 'none';

    video.onLoadedMetadata.listen((_) {
      final dur = video.duration;
      if (!dur.isNaN && !dur.isInfinite && dur > 0) {
        widget.onDurationDetected?.call(dur.toDouble());
      }
      if (widget.positionSeconds > 0.5) {
        try {
          video.currentTime = widget.positionSeconds;
        } catch (_) {}
      }
      if (widget.isPlaying && video.paused) {
        video.play().catchError((_) {});
      }
    });

    video.onTimeUpdate.listen((_) {
      final cur = video.currentTime;
      if (!cur.isNaN) {
        widget.onTimeUpdate?.call(cur.toDouble());
      }
    });

    video.onEnded.listen((_) {
      widget.onEnded?.call();
    });

    _videoElement = video;

    if (!_registeredViews.contains(_viewType)) {
      _registeredViews.add(_viewType);
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => video,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ReplayVideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    final video = _videoElement;
    if (video == null) return;

    if (oldWidget.videoUrl != widget.videoUrl && widget.videoUrl.isNotEmpty) {
      video.src = widget.videoUrl;
      video.load();
    }

    if (oldWidget.playbackSpeed != widget.playbackSpeed) {
      video.playbackRate = widget.playbackSpeed;
    }

    if (oldWidget.volume != widget.volume) {
      video.volume = widget.volume.clamp(0.0, 1.0);
    }

    if (oldWidget.isMuted != widget.isMuted) {
      video.muted = widget.isMuted;
    }

    final mediaDur =
        (!video.duration.isNaN && !video.duration.isInfinite && video.duration > 0)
            ? video.duration.toDouble()
            : 0.0;
    final targetTime = mediaDur > 1.0
        ? widget.positionSeconds.clamp(0.0, mediaDur)
        : widget.positionSeconds;

    if ((video.currentTime - targetTime).abs() > 1.2) {
      try {
        video.currentTime = targetTime;
      } catch (_) {}
    }

    if (widget.isPlaying && video.paused) {
      video.play().catchError((_) {});
    } else if (!widget.isPlaying && !video.paused) {
      video.pause();
    }
  }

  @override
  void dispose() {
    try {
      _videoElement?.pause();
      _videoElement?.src = '';
      _videoElement?.load();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl.isEmpty) {
      return const SizedBox.expand();
    }
    return HtmlElementView(viewType: _viewType);
  }
}

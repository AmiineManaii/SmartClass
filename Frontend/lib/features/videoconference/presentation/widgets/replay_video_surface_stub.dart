import 'package:flutter/material.dart';

void enterBrowserFullscreen() {}

void exitBrowserFullscreen() {}

class ReplayVideoSurface extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final imageUrl =
        (activeFrameUrl != null && activeFrameUrl!.isNotEmpty)
            ? activeFrameUrl!
            : posterUrl;
    if (imageUrl.isEmpty) {
      return const SizedBox.expand();
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => const SizedBox.expand(),
    );
  }
}

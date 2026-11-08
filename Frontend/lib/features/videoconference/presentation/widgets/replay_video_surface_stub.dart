import 'package:flutter/material.dart';

class ReplayVideoSurface extends StatelessWidget {
  final String videoUrl;
  final String posterUrl;
  final String? activeFrameUrl;
  final bool isPlaying;
  final double positionSeconds;
  final double playbackSpeed;
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


import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../domain/entities/live_participant.dart';

/// Floating Picture-in-Picture (PiP) webcam box displayed over the shared screen,
/// replicating the Zoom, Microsoft Teams, and Google Meet presenter experience.
class PresenterPipOverlay extends StatefulWidget {
  final LiveParticipant participant;
  final lk.VideoTrack videoTrack;

  const PresenterPipOverlay({
    super.key,
    required this.participant,
    required this.videoTrack,
  });

  @override
  State<PresenterPipOverlay> createState() => _PresenterPipOverlayState();
}

class _PresenterPipOverlayState extends State<PresenterPipOverlay> {
  bool _isMinimized = false;
  Offset _position = const Offset(20, 20); // offset from bottom-right

  @override
  Widget build(BuildContext context) {
    if (_isMinimized) {
      return Positioned(
        bottom: 20,
        right: 20,
        child: Tooltip(
          message: 'Agrandir la caméra du présentateur',
          child: InkWell(
            onTap: () => setState(() => _isMinimized = false),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF3B82F6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam_rounded,
                    size: 15,
                    color: Color(0xFF60A5FA),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.participant.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.open_in_full_rounded,
                    size: 13,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      bottom: _position.dy,
      right: _position.dx,
      width: 210,
      height: 130,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx - details.delta.dx).clamp(10.0, 500.0),
              (_position.dy - details.delta.dy).clamp(10.0, 500.0),
            );
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.participant.isSpeaking
                  ? const Color(0xFF10B981)
                  : const Color(0xFF3B82F6).withValues(alpha: 0.8),
              width: widget.participant.isSpeaking ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.participant.isSpeaking
                    ? const Color(0xFF10B981).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                spreadRadius: widget.participant.isSpeaking ? 1 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Video renderer for presenter's webcam
              Positioned.fill(
                child: lk.VideoTrackRenderer(
                  widget.videoTrack,
                  fit: lk.VideoViewFit.cover,
                ),
              ),

              // Drag indicator in top-left
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.drag_indicator_rounded, size: 12, color: Colors.white70),
                      SizedBox(width: 2),
                      Text('Webcam', style: TextStyle(color: Colors.white70, fontSize: 9)),
                    ],
                  ),
                ),
              ),

              // Top action buttons: Minimize PiP
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: () => setState(() => _isMinimized = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_fullscreen_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Bottom banner with presenter name and microphone status
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.participant.isAudioMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        size: 12,
                        color: widget.participant.isAudioMuted
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.participant.isLocal
                              ? '${widget.participant.name} (Vous)'
                              : widget.participant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

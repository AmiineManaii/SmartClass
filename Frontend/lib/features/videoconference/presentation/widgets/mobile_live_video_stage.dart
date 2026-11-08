import 'package:flutter/material.dart';

import '../../application/live_room_controller.dart';
import '../../domain/entities/live_participant.dart';
import 'live_video_tile_loader.dart';
import 'participant_tile.dart';

class MobileLiveVideoStage extends StatelessWidget {
  final LiveRoomState roomState;
  final LiveParticipant? local;
  final List<LiveParticipant> remotes;
  final LiveParticipant? heroSpeaker;

  const MobileLiveVideoStage({
    super.key,
    required this.roomState,
    required this.local,
    required this.remotes,
    required this.heroSpeaker,
  });

  @override
  Widget build(BuildContext context) {
    // Case 1: Only local participant in room
    if (remotes.isEmpty) {
      return Stack(
        children: [
          Positioned.fill(
            child: local != null
                ? ParticipantTile(participant: local!, isHero: true)
                : const LiveVideoTileLoader(),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'En attente des autres participants...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Case 2: 1-on-1 (You + 1 Remote, e.g. Teacher + 1 Student)
    if (remotes.length == 1 && local != null) {
      final remote = remotes.first;
      final isScreenSharing = remote.isScreenSharing || local!.isScreenSharing;

      if (isScreenSharing) {
        final presenter = remote.isScreenSharing ? remote : local!;
        final viewer = remote.isScreenSharing ? local! : remote;

        return Stack(
          children: [
            // Full Stage Presentation (Google Meet / Teams Style)
            Positioned.fill(
              child: ParticipantTile(
                participant: presenter,
                isHero: true,
              ),
            ),
            // Floating Picture-in-Picture for Viewer
            Positioned(
              right: 12,
              bottom: 24,
              width: 115,
              height: 155,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF3B82F6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ParticipantTile(
                  participant: viewer,
                  isHero: false,
                ),
              ),
            ),
          ],
        );
      }

      return Column(
        children: [
          Expanded(
            flex: 1,
            child: ParticipantTile(
              participant: remotes.first,
              isHero: true,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 1,
            child: ParticipantTile(
              participant: local!,
              isHero: true,
            ),
          ),
        ],
      );
    }

    // Case 3: Group class (3+ participants)
    final otherParticipants = <LiveParticipant>[
      if (local != null && heroSpeaker != local) local!,
      ...remotes.where((p) => p != heroSpeaker),
    ];

    return Column(
      children: [
        Expanded(
          flex: 4,
          child: heroSpeaker != null
              ? ParticipantTile(participant: heroSpeaker!, isHero: true)
              : const LiveVideoTileLoader(),
        ),
        if (otherParticipants.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: otherParticipants.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 115,
                  child: ParticipantTile(
                    participant: otherParticipants[index],
                    isHero: false,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}


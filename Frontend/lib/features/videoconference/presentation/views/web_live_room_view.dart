import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/live_room_controller.dart';
import '../../domain/entities/live_participant.dart';
import '../../domain/entities/room_connection_state.dart';
import '../widgets/live_chat_panel.dart';
import '../widgets/live_room_controls.dart';
import '../widgets/live_video_tile_loader.dart';
import '../widgets/participant_tile.dart';
import '../widgets/participants_sheet.dart';

class WebLiveRoomView extends ConsumerStatefulWidget {
  const WebLiveRoomView({super.key});

  @override
  ConsumerState<WebLiveRoomView> createState() => _WebLiveRoomViewState();
}

class _WebLiveRoomViewState extends ConsumerState<WebLiveRoomView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(liveRoomControllerProvider);
    final session = roomState.session;

    final heroSpeaker = roomState.activeSpeaker;
    final otherParticipants = <LiveParticipant>[
      if (roomState.localParticipant != null &&
          roomState.localParticipant != heroSpeaker)
        roomState.localParticipant!,
      ...roomState.remoteParticipants.values
          .where((p) => p != heroSpeaker),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Column(
        children: [
          // Top Academic Header
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF151B2B),
              border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: Color(0xFF4056B9), size: 22),
                const SizedBox(width: 8),
                const Text(
                  'SmartClass',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 20, color: const Color(0xFF334155)),
                const SizedBox(width: 16),
                if (session?.className != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3E8C).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      session!.className!,
                      style: const TextStyle(color: Color(0xFF9EAEFF), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  session?.title ?? 'Session Live',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                // Live Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.fiber_manual_record, color: Colors.red, size: 10),
                      SizedBox(width: 6),
                      Text(
                        'EN DIRECT',
                        style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Network quality
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2638),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.signal_cellular_alt_rounded, color: Color(0xFF10B981), size: 14),
                      SizedBox(width: 4),
                      Text('24 ms', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Central Stage + Right Rail
          Expanded(
            child: Row(
              children: [
                // Video Stage
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Hero Active Speaker Tile
                        Expanded(
                          child: heroSpeaker != null
                              ? ParticipantTile(
                                  participant: heroSpeaker,
                                  isHero: true,
                                )
                              : const LiveVideoTileLoader(),
                        ),
                        // Filmstrip Carousel (if other participants exist)
                        if (otherParticipants.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 110,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: otherParticipants.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  width: 160,
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
                    ),
                  ),
                ),

                // Right Rail
                Container(
                  width: 380,
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Color(0xFF334155), width: 1)),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFF4056B9),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: context.tr('chat')),
                          Tab(text: context.tr('participants')),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: const [
                            LiveChatPanel(),
                            ParticipantsSheet(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Controls Dock
          const LiveRoomControls(isMobile: false),
        ],
      ),
    );
  }
}

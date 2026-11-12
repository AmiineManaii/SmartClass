import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/live_room_controller.dart';
import '../../domain/entities/live_participant.dart';
import '../widgets/live_chat_panel.dart';
import '../widgets/live_room_controls.dart';
import '../widgets/live_video_tile_loader.dart';
import '../widgets/participant_tile.dart';
import '../widgets/participants_sheet.dart';
import '../widgets/recording_status_banner.dart';

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

    final heroSpeaker =
        roomState.screenSharingParticipant ?? roomState.activeSpeaker;
    final otherParticipants = <LiveParticipant>[
      if (roomState.localParticipant != null &&
          roomState.localParticipant != heroSpeaker)
        roomState.localParticipant!,
      ...roomState.remoteParticipants.values
          .where((p) => p != heroSpeaker),
    ];
    final isDrawerOpen =
        roomState.isChatOpen || roomState.isParticipantsOpen;
    final targetTab = roomState.isParticipantsOpen ? 1 : 0;
    if (isDrawerOpen && _tabController.index != targetTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.index != targetTab) {
          _tabController.animateTo(targetTab);
        }
      });
    }

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
                Flexible(
                  child: Text(
                    session?.title ?? 'Session Live',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                const RecordingStatusBanner(compact: true),
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

          // Recording Consent Banner
          const RecordingStatusBanner(),

          // Presenter Screen Sharing Banner (Google Meet Style)
          if (roomState.isScreenSharing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.screen_share_rounded,
                      size: 18,
                      color: Color(0xFF60A5FA),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Vous partagez actuellement votre écran avec la classe',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '💡 Conseil : Partagez une fenêtre spécifique (PowerPoint, PDF, navigateur) plutôt que tout l\'écran pour éviter les reflets en miroir.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => ref
                        .read(liveRoomControllerProvider.notifier)
                        .toggleScreenShare(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.stop_screen_share_rounded,
                            size: 14,
                            color: Color(0xFFF87171),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Arrêter le partage',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFFF87171),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Central Stage + Google Meet Right Participant Column + Collapsible Drawer
          Expanded(
            child: Row(
              children: [
                // Main Stage + Google Meet Vertical Participant Strip on the Right
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Active Speaker / Screen Share Stage
                        Expanded(
                          child: heroSpeaker != null
                              ? ParticipantTile(
                                  participant: heroSpeaker,
                                  isHero: true,
                                )
                              : const LiveVideoTileLoader(),
                        ),
                        // Google Meet Right Vertical Participant Column
                        if (otherParticipants.isNotEmpty) ...[
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 220,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF151B2B),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.people_alt_rounded,
                                        size: 14,
                                        color: Color(0xFF60A5FA),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Classe (${otherParticipants.length + (heroSpeaker != null ? 1 : 0)})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: otherParticipants.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      return SizedBox(
                                        height: 136,
                                        child: ParticipantTile(
                                          participant: otherParticipants[index],
                                          isHero: false,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Collapsible Right Drawer (Discussion & Participants)
                if (isDrawerOpen)
                  Container(
                    width: 360,
                    margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151B2B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF334155),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(-4, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          color: const Color(0xFF1E2638),
                          child: Row(
                            children: [
                              Expanded(
                                child: TabBar(
                                  controller: _tabController,
                                  indicatorColor: const Color(0xFF3B82F6),
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.white60,
                                  dividerColor: Colors.transparent,
                                  onTap: (idx) {
                                    final ctrl = ref.read(
                                      liveRoomControllerProvider.notifier,
                                    );
                                    if (idx == 0) {
                                      ctrl.toggleChat(true);
                                    } else {
                                      ctrl.toggleParticipants(true);
                                    }
                                  },
                                  tabs: [
                                    Tab(
                                      icon: const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 16,
                                      ),
                                      text: context.tr('chat'),
                                    ),
                                    Tab(
                                      icon: const Icon(
                                        Icons.people_outline_rounded,
                                        size: 16,
                                      ),
                                      text: context.tr('participants'),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: context.tr('close'),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () {
                                  final ctrl = ref.read(
                                    liveRoomControllerProvider.notifier,
                                  );
                                  ctrl.toggleChat(false);
                                  ctrl.toggleParticipants(false);
                                },
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
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

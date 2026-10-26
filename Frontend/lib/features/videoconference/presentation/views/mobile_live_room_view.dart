import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/live_room_controller.dart';
import '../../domain/entities/live_participant.dart';
import '../../domain/entities/room_connection_state.dart';
import '../widgets/live_chat_panel.dart';
import '../widgets/live_room_controls.dart';
import '../widgets/live_video_tile_loader.dart';
import '../widgets/participant_tile.dart';
import '../widgets/participants_sheet.dart';

class MobileLiveRoomView extends ConsumerStatefulWidget {
  const MobileLiveRoomView({super.key});

  @override
  ConsumerState<MobileLiveRoomView> createState() => _MobileLiveRoomViewState();
}

class _MobileLiveRoomViewState extends ConsumerState<MobileLiveRoomView> {
  bool _isControlsVisible = true;
  Timer? _autoHideTimer;
  Timer? _sessionTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Auto-hide the bottom dock 3.5s after entering the session
    _startAutoHideTimer(const Duration(milliseconds: 3500));

    // Live session duration stopwatch
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed += const Duration(seconds: 1);
        });
      }
    });
  }

  void _startAutoHideTimer([Duration duration = const Duration(seconds: 4)]) {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(duration, () {
      if (mounted && _isControlsVisible) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
    if (_isControlsVisible) {
      _startAutoHideTimer(const Duration(seconds: 4));
    } else {
      _autoHideTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  String _formatElapsed() {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (_elapsed.inHours > 0) {
      return '${_elapsed.inHours}:$m:$s';
    }
    return '$m:$s';
  }

  void _showChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: const LiveChatPanel(),
      ),
    );
  }

  void _showParticipantsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: const ParticipantsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(liveRoomControllerProvider);
    final controller = ref.read(liveRoomControllerProvider.notifier);
    final session = roomState.session;

    // Listen to chat toggle from controls
    ref.listen<bool>(
      liveRoomControllerProvider.select((s) => s.isChatOpen),
      (prev, next) {
        if (next && (prev == null || !prev)) {
          _showChatSheet(context);
        }
      },
    );

    // Listen to participants toggle from controls
    ref.listen<bool>(
      liveRoomControllerProvider.select((s) => s.isParticipantsOpen),
      (prev, next) {
        if (next && (prev == null || !prev)) {
          _showParticipantsSheet(context);
        }
      },
    );

    final local = roomState.localParticipant;
    final remotes = roomState.remoteParticipants.values.toList();
    final heroSpeaker = roomState.activeSpeaker;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content Area
            Column(
              children: [
                // Top Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: Colors.white),
                        tooltip: context.tr('back'),
                        onPressed: () async {
                          await controller.leaveRoom();
                          if (context.mounted) {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/videoconference');
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  context.tr('tab_live').toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFFEF4444),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatElapsed(),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              session?.title ?? 'Session Live',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios_rounded,
                            color: Colors.white, size: 20),
                        tooltip: 'Changer de caméra',
                        onPressed: controller.flipCamera,
                      ),
                      IconButton(
                        icon: Badge.count(
                          count: remotes.length + (local != null ? 1 : 0),
                          backgroundColor: const Color(0xFF3B82F6),
                          child: const Icon(Icons.people_outline_rounded,
                              color: Colors.white, size: 20),
                        ),
                        tooltip: context.tr('participants'),
                        onPressed: () => _showParticipantsSheet(context),
                      ),
                    ],
                  ),
                ),

                // Video Stage Area with Tap-to-Toggle
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleControls,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: _buildAdaptiveVideoGrid(
                        roomState: roomState,
                        local: local,
                        remotes: remotes,
                        heroSpeaker: heroSpeaker,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Floating Pill when Controls are Hidden
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: !_isControlsVisible ? 1.0 : 0.0,
                child: Center(
                  child: IgnorePointer(
                    ignoring: _isControlsVisible,
                    child: GestureDetector(
                      onTap: _toggleControls,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.tune_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Commandes',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_up_rounded,
                                color: Colors.white70, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Sliding Bottom Controls Dock
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                offset: _isControlsVisible ? Offset.zero : const Offset(0, 1.2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isControlsVisible ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_isControlsVisible,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Collapse Handle Bar
                          GestureDetector(
                            onTap: _toggleControls,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Center(
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Quick Chat Pill
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: InkWell(
                              onTap: () => _showChatSheet(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B)
                                      .withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF334155)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 15,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        roomState.chatMessages.isNotEmpty
                                            ? '${roomState.chatMessages.last.senderDisplayName}: ${roomState.chatMessages.last.content}'
                                            : 'Toucher pour ouvrir le chat...',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          color: Colors.white70,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                    if (roomState.unreadChatCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${roomState.unreadChatCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Control Buttons Row
                          const LiveRoomControls(isMobile: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptiveVideoGrid({
    required LiveRoomState roomState,
    required LiveParticipant? local,
    required List<LiveParticipant> remotes,
    required LiveParticipant? heroSpeaker,
  }) {
    // Case 1: Only local participant in room
    if (remotes.isEmpty) {
      return Stack(
        children: [
          Positioned.fill(
            child: local != null
                ? ParticipantTile(participant: local, isHero: true)
                : _buildLoadingState(roomState),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

    // Case 2: 1-on-1 (You + 1 Remote participant, e.g. Teacher + 1 Student)
    if (remotes.length == 1 && local != null) {
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
              participant: local,
              isHero: true,
            ),
          ),
        ],
      );
    }

    // Case 3: Group class (3+ participants)
    final otherParticipants = <LiveParticipant>[
      if (local != null && heroSpeaker != local) local,
      ...remotes.where((p) => p != heroSpeaker),
    ];

    return Column(
      children: [
        // Main Hero Speaker
        Expanded(
          flex: 4,
          child: heroSpeaker != null
              ? ParticipantTile(participant: heroSpeaker, isHero: true)
              : _buildLoadingState(roomState),
        ),

        // Scrollable Peer Strip at Bottom
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

  Widget _buildLoadingState(LiveRoomState roomState) {
    return const LiveVideoTileLoader();
  }
}

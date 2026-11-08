import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/live_room_controller.dart';
import '../widgets/live_chat_panel.dart';
import '../widgets/live_room_controls.dart';
import '../widgets/live_room_leave_dialog.dart';
import '../widgets/mobile_live_video_stage.dart';
import '../widgets/participants_sheet.dart';
import '../widgets/recording_status_banner.dart';

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
    _startAutoHideTimer(const Duration(milliseconds: 3500));

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

    ref.listen<bool>(
      liveRoomControllerProvider.select((s) => s.isChatOpen),
      (prev, next) {
        if (next && (prev == null || !prev)) {
          _showChatSheet(context);
        }
      },
    );

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
    final heroSpeaker =
        roomState.screenSharingParticipant ?? roomState.activeSpeaker;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: Colors.white),
                        tooltip: context.tr('back'),
                        onPressed: () => LiveRoomLeaveHelper.showLeaveOrEndDialog(
                          context: context,
                          controller: controller,
                          roomState: roomState,
                          isHost: roomState.isHost,
                        ),
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
                                const SizedBox(width: 6),
                                Text(
                                  context.tr('live_badge').toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFFEF4444),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '•',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 10),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatElapsed(),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
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

                const RecordingStatusBanner(),

                // Video Stage with Tap to Toggle Dock
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleControls,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: MobileLiveVideoStage(
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
              bottom: 28,
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/live_room_controller.dart';
import 'live_room_leave_dialog.dart';

class LiveRoomControls extends ConsumerWidget {
  final bool isMobile;

  const LiveRoomControls({
    super.key,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(liveRoomControllerProvider);
    final controller = ref.read(liveRoomControllerProvider.notifier);
    final isHost = roomState.isHost;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Mic
              _buildControlIconBtn(
                icon: roomState.isMicEnabled
                    ? Icons.mic_rounded
                    : Icons.mic_off_rounded,
                color: roomState.isMicEnabled ? Colors.white : Colors.white,
                bgColor: roomState.isMicEnabled
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFEF4444),
                tooltip: roomState.isMicEnabled ? 'Couper micro' : 'Activer micro',
                onTap: controller.toggleMicrophone,
              ),

              // Camera
              _buildControlIconBtn(
                icon: roomState.isCameraEnabled
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
                color: Colors.white,
                bgColor: roomState.isCameraEnabled
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFEF4444),
                tooltip: roomState.isCameraEnabled ? 'Couper caméra' : 'Activer caméra',
                onTap: controller.toggleCamera,
              ),

              // Screen Share
              _buildControlIconBtn(
                icon: Icons.present_to_all_rounded,
                color: Colors.white,
                bgColor: roomState.isScreenSharing
                    ? const Color(0xFF10B981)
                    : (roomState.canShareScreen
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF0F172A)),
                tooltip: 'Partage d\'écran',
                onTap: () {
                  if (roomState.canShareScreen) {
                    controller.toggleScreenShare();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Partage d\'écran non autorisé par l\'enseignant'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),

              // Raise Hand
              _buildControlIconBtn(
                icon: Icons.front_hand_rounded,
                color: roomState.isHandRaised ? const Color(0xFFF59E0B) : Colors.white,
                bgColor: roomState.isHandRaised
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                    : const Color(0xFF1E293B),
                tooltip: roomState.isHandRaised ? 'Baisser la main' : 'Lever la main',
                onTap: controller.toggleRaiseHand,
              ),

              // End / Leave Call Button (Icon-Only Google Meet style)
              _buildControlIconBtn(
                icon: Icons.call_end_rounded,
                color: Colors.white,
                bgColor: const Color(0xFFDC2626),
                tooltip: isHost ? 'Fin de session' : 'Quitter la session',
                onTap: () => LiveRoomLeaveHelper.showLeaveOrEndDialog(
                  context: context,
                  controller: controller,
                  roomState: roomState,
                  isHost: isHost,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Desktop / Web Floating Dock (Google Meet / Zoom 2026 Style)
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Security & Connection Pill (Replaces clunky text)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF334155),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock_rounded, size: 13, color: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Text(
                      'E2EE • WebRTC HD',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (roomState.isRecording) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.circle, size: 8, color: Color(0xFFEF4444)),
                      SizedBox(width: 5),
                      Text(
                        'REC',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFEF4444),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Center: Main Meeting Controls (Floating Frosted Island)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Microphone
                _buildActionIconButton(
                  icon: roomState.isMicEnabled
                      ? Icons.mic_rounded
                      : Icons.mic_off_rounded,
                  tooltip: roomState.isMicEnabled
                      ? 'Couper le micro'
                      : 'Activer le micro',
                  isActive: roomState.isMicEnabled,
                  isDestructive: !roomState.isMicEnabled,
                  onPressed: controller.toggleMicrophone,
                ),
                const SizedBox(width: 8),

                // 2. Camera
                _buildActionIconButton(
                  icon: roomState.isCameraEnabled
                      ? Icons.videocam_rounded
                      : Icons.videocam_off_rounded,
                  tooltip: roomState.isCameraEnabled
                      ? 'Couper la caméra'
                      : 'Activer la caméra',
                  isActive: roomState.isCameraEnabled,
                  isDestructive: !roomState.isCameraEnabled,
                  onPressed: controller.toggleCamera,
                ),
                const SizedBox(width: 8),

                // 3. Screen Share (Present to All)
                _buildActionIconButton(
                  icon: Icons.present_to_all_rounded,
                  tooltip: roomState.isScreenSharing
                      ? 'Arrêter le partage'
                      : (roomState.canShareScreen
                          ? 'Partager l\'écran'
                          : 'Partage non autorisé'),
                  isActive: roomState.isScreenSharing,
                  activeColor: const Color(0xFF10B981),
                  onPressed: () {
                    if (roomState.canShareScreen) {
                      controller.toggleScreenShare();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Le partage d\'écran nécessite l\'autorisation de l\'enseignant'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),

                // 4. Raise Hand
                _buildActionIconButton(
                  icon: Icons.front_hand_rounded,
                  tooltip: roomState.isHandRaised
                      ? 'Baisser la main'
                      : 'Lever la main',
                  isActive: roomState.isHandRaised,
                  activeColor: const Color(0xFFF59E0B),
                  onPressed: controller.toggleRaiseHand,
                ),

                // 5. Host Recording Toggle Button
                if (isHost) ...[
                  const SizedBox(width: 8),
                  _buildActionIconButton(
                    icon: roomState.isRecording
                        ? Icons.stop_circle_rounded
                        : Icons.radio_button_checked_rounded,
                    tooltip: roomState.isRecording
                        ? context.tr('rec_stop')
                        : context.tr('rec_start'),
                    isActive: roomState.isRecording,
                    activeColor: const Color(0xFFDC2626),
                    isLoading: roomState.isRecordingBusy,
                    onPressed: roomState.isRecordingBusy
                        ? null
                        : () async {
                            final wasRecording = roomState.isRecording;
                            await controller.toggleRecording();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    wasRecording
                                        ? context.tr('rec_stopped_toast')
                                        : context.tr('rec_started_toast'),
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                  ),
                ],

                const SizedBox(width: 10),
                Container(width: 1, height: 26, color: const Color(0xFF334155)),
                const SizedBox(width: 10),

                // 6. Participants Drawer Toggle (with Badge)
                Badge(
                  isLabelVisible: true,
                  backgroundColor: const Color(0xFF2563EB),
                  label: Text(
                    '${roomState.remoteParticipants.length + (roomState.localParticipant != null ? 1 : 0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  child: _buildActionIconButton(
                    icon: Icons.people_alt_rounded,
                    tooltip: roomState.isParticipantsOpen
                        ? 'Masquer participants'
                        : 'Afficher participants',
                    isActive: roomState.isParticipantsOpen,
                    activeColor: const Color(0xFF3B82F6),
                    onPressed: () => controller.toggleParticipants(),
                  ),
                ),
                const SizedBox(width: 8),

                // 7. Discussion / Chat Toggle (with Badge)
                Badge(
                  isLabelVisible: roomState.unreadChatCount > 0,
                  backgroundColor: const Color(0xFFEF4444),
                  label: Text(
                    '${roomState.unreadChatCount}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  child: _buildActionIconButton(
                    icon: Icons.chat_bubble_rounded,
                    tooltip: roomState.isChatOpen
                        ? 'Masquer discussion'
                        : 'Ouvrir discussion',
                    isActive: roomState.isChatOpen,
                    activeColor: const Color(0xFF3B82F6),
                    onPressed: () => controller.toggleChat(),
                  ),
                ),
              ],
            ),
          ),

          // Right: Icon-Only End / Leave Call Button (Exact Google Meet & Zoom Style)
          Tooltip(
            message: isHost
                ? 'Mettre fin ou quitter la session'
                : 'Quitter la session',
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => LiveRoomLeaveHelper.showLeaveOrEndDialog(
                context: context,
                controller: controller,
                roomState: roomState,
                isHost: isHost,
              ),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEF4444),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call_end_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool isActive = false,
    bool isDestructive = false,
    Color? activeColor,
    bool isLoading = false,
  }) {
    Color bg;
    Color fg;
    Color border;

    if (isLoading) {
      bg = const Color(0xFF334155);
      fg = Colors.white;
      border = Colors.transparent;
    } else if (isDestructive) {
      bg = const Color(0xFFEF4444);
      fg = Colors.white;
      border = const Color(0xFFF87171);
    } else if (isActive) {
      bg = activeColor ?? const Color(0xFF2563EB);
      fg = Colors.white;
      border = (activeColor ?? const Color(0xFF3B82F6)).withValues(alpha: 0.6);
    } else {
      bg = const Color(0xFF0F172A);
      fg = const Color(0xFFCBD5E1);
      border = const Color(0xFF334155);
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 1.2),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, color: fg, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildControlIconBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF334155), width: 1),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/live_room_controller.dart';

class LiveRoomControls extends ConsumerWidget {
  final bool isMobile;

  const LiveRoomControls({
    super.key,
    this.isMobile = false,
  });

  Future<void> _handleLeave(BuildContext context, LiveRoomController controller) async {
    await controller.leaveRoom();
    if (context.mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/videoconference');
      }
    }
  }

  Future<void> _confirmEndSession(BuildContext context, LiveRoomController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('end_session_for_all'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          context.tr('confirm_end_session'),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('cancel'), style: const TextStyle(color: Colors.white60)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('leave_session')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await controller.endRoomForEveryone();
      if (context.mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/videoconference');
        }
      }
    }
  }

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
              _buildRoundBtn(
                icon: roomState.isMicEnabled
                    ? Icons.mic_rounded
                    : Icons.mic_off_rounded,
                color: roomState.isMicEnabled
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                bgColor: roomState.isMicEnabled
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFEF4444).withValues(alpha: 0.18),
                borderColor: roomState.isMicEnabled
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : const Color(0xFFEF4444).withValues(alpha: 0.5),
                onTap: controller.toggleMicrophone,
              ),

              // Camera
              _buildRoundBtn(
                icon: roomState.isCameraEnabled
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
                color: roomState.isCameraEnabled
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                bgColor: roomState.isCameraEnabled
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFEF4444).withValues(alpha: 0.18),
                borderColor: roomState.isCameraEnabled
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : const Color(0xFFEF4444).withValues(alpha: 0.5),
                onTap: controller.toggleCamera,
              ),

              // Hand
              _buildRoundBtn(
                icon: Icons.front_hand_rounded,
                color: roomState.isHandRaised
                    ? Colors.black
                    : const Color(0xFFF59E0B),
                bgColor: roomState.isHandRaised
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF1E293B),
                borderColor: roomState.isHandRaised
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF334155),
                onTap: controller.toggleRaiseHand,
              ),

              // Chat
              Stack(
                children: [
                  _buildRoundBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    bgColor: const Color(0xFF1E293B),
                    borderColor: const Color(0xFF334155),
                    onTap: () => controller.toggleChat(),
                  ),
                  if (roomState.unreadChatCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          '${roomState.unreadChatCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Leave / End
              if (isHost)
                _buildRoundBtn(
                  icon: Icons.call_end_rounded,
                  color: Colors.white,
                  bgColor: const Color(0xFFDC2626),
                  borderColor: const Color(0xFFEF4444),
                  onTap: () => _confirmEndSession(context, controller),
                )
              else
                _buildRoundBtn(
                  icon: Icons.call_end_rounded,
                  color: Colors.white,
                  bgColor: const Color(0xFFDC2626),
                  borderColor: const Color(0xFFEF4444),
                  onTap: () => _handleLeave(context, controller),
                ),
            ],
          ),
        ),
      );
    }

    // Desktop dock
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF151B2B),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Info
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_rounded, size: 14, color: Colors.grey),
              SizedBox(width: 6),
              Text(
                'LiveKit WebRTC',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),

          // Center: Main controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mic
              IconButton.filled(
                tooltip: roomState.isMicEnabled ? 'Couper le micro' : 'Activer le micro',
                icon: Icon(
                  roomState.isMicEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: roomState.isMicEnabled
                      ? const Color(0xFF1E2638)
                      : const Color(0xFFEF4444),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: controller.toggleMicrophone,
              ),
              const SizedBox(width: 10),

              // Camera
              IconButton.filled(
                tooltip: roomState.isCameraEnabled ? 'Couper la caméra' : 'Activer la caméra',
                icon: Icon(
                  roomState.isCameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: roomState.isCameraEnabled
                      ? const Color(0xFF1E2638)
                      : const Color(0xFFEF4444),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: controller.toggleCamera,
              ),
              const SizedBox(width: 10),

              // Screen Share (Host Only)
              if (roomState.canPublishScreen) ...[
                IconButton.filled(
                  tooltip: roomState.isScreenSharing ? 'Arrêter le partage' : 'Partager l\'écran',
                  icon: const Icon(Icons.present_to_all_rounded, size: 20, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: roomState.isScreenSharing
                        ? const Color(0xFF10B981)
                        : const Color(0xFF1E2638),
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: controller.toggleScreenShare,
                ),
                const SizedBox(width: 10),
              ],

              // Raise Hand
              IconButton.filled(
                tooltip: roomState.isHandRaised ? 'Baisser la main' : 'Lever la main',
                icon: Icon(
                  Icons.front_hand_rounded,
                  size: 20,
                  color: roomState.isHandRaised ? const Color(0xFFF59E0B) : Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: roomState.isHandRaised
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                      : const Color(0xFF1E2638),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: controller.toggleRaiseHand,
              ),
            ],
          ),

          // Right: Leave / End
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF475569)),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _handleLeave(context, controller),
                child: Text(context.tr('leave_session')),
              ),
              if (isHost) ...[
                const SizedBox(width: 10),
                FilledButton.icon(
                  icon: const Icon(Icons.call_end_rounded, size: 16),
                  label: Text(context.tr('end_session_for_all')),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                  onPressed: () => _confirmEndSession(context, controller),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor ?? const Color(0xFF334155), width: 1),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

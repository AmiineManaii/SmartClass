import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/live_room_controller.dart';
import '../../domain/entities/room_connection_state.dart';
import '../views/mobile_live_room_view.dart';
import '../views/web_live_room_view.dart';
import '../widgets/hand_raise_notice_overlay.dart';
import '../widgets/live_room_connecting_overlay.dart';

class LiveRoomPage extends ConsumerStatefulWidget {
  final String sessionId;
  final bool? initialMic;
  final bool? initialCamera;

  const LiveRoomPage({
    super.key,
    required this.sessionId,
    this.initialMic,
    this.initialCamera,
  });

  @override
  ConsumerState<LiveRoomPage> createState() => _LiveRoomPageState();
}

class _LiveRoomPageState extends ConsumerState<LiveRoomPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveRoomControllerProvider.notifier).joinRoom(
            widget.sessionId,
            initialMic: widget.initialMic,
            initialCamera: widget.initialCamera,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(liveRoomControllerProvider);

    // Cleanly pop/redirect when disconnected
    ref.listen<RoomConnectionState>(
      liveRoomControllerProvider.select((s) => s.connectionState),
      (prev, next) {
        if (next == RoomConnectionState.disconnected) {
          if (context.mounted) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/videoconference');
            }
          }
        }
      },
    );

    if (roomState.connectionState == RoomConnectionState.disconnected) {
      return const LiveRoomConnectingOverlay();
    }

    // Overlays for specific terminal states
    if (roomState.connectionState == RoomConnectionState.endedByHost) {
      return _buildTerminalScreen(
        icon: Icons.check_circle_outline_rounded,
        title: context.tr('session_ended'),
        message: 'Cette session de cours est désormais terminée.',
        buttonText: context.tr('back'),
        onPressed: () => context.go('/videoconference'),
      );
    }

    if (roomState.connectionState == RoomConnectionState.removed) {
      return _buildTerminalScreen(
        icon: Icons.block_flipped,
        title: 'Session terminée',
        message: 'Vous avez été retiré de la session par l\'enseignant.',
        buttonText: context.tr('back'),
        onPressed: () => context.go('/videoconference'),
      );
    }

    if (roomState.connectionState == RoomConnectionState.error) {
      return _buildTerminalScreen(
        icon: Icons.error_outline_rounded,
        title: context.tr('something_went_wrong'),
        message: roomState.errorMessage ?? 'Erreur de connexion au serveur vidéo.',
        buttonText: context.tr('retry'),
        onPressed: () => ref
            .read(liveRoomControllerProvider.notifier)
            .joinRoom(widget.sessionId),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1024;
        return Stack(
          children: [
            isWide ? const WebLiveRoomView() : const MobileLiveRoomView(),

            // Wave / Hand Raise animated notice and celebration particles overlay
            const HandRaiseNoticeOverlay(),

            // Modern connecting radar overlay
            if (roomState.connectionState == RoomConnectionState.connecting)
              const LiveRoomConnectingOverlay(),

            // Reconnecting top banner
            if (roomState.connectionState == RoomConnectionState.reconnecting)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.orange.shade800,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Reconnexion au flux vidéo en cours...',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTerminalScreen({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: const Color(0xFF4056B9)),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: buttonText,
                variant: AppButtonVariant.primary,
                onPressed: onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

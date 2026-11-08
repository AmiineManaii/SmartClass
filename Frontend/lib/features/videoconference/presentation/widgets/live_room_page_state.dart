part of '../pages/live_room_page.dart';

class _LiveRoomPageState extends ConsumerState<LiveRoomPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(liveRoomControllerProvider.notifier)
          .joinRoom(
            widget.sessionId,
            initialMic: widget.initialMic,
            initialCamera: widget.initialCamera,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(liveRoomControllerProvider);

    // Cleanly redirect to videoconference dashboard when disconnected
    ref.listen<RoomConnectionState>(
      liveRoomControllerProvider.select((s) => s.connectionState),
      (prev, next) {
        if (next == RoomConnectionState.disconnected) {
          if (context.mounted) {
            context.go('/videoconference');
          }
        }
      },
    );

    if (roomState.connectionState == RoomConnectionState.disconnected) {
      return const Scaffold(
        backgroundColor: Color(0xFF04060B),
        body: LiveRoomConnectingOverlay(),
      );
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
        message:
            roomState.errorMessage ?? 'Erreur de connexion au serveur vidéo.',
        buttonText: context.tr('retry'),
        onPressed: () => ref
            .read(liveRoomControllerProvider.notifier)
            .joinRoom(widget.sessionId),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF04060B),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1024;
          return Stack(
            children: [
              isWide ? const WebLiveRoomView() : const MobileLiveRoomView(),

            // Automatic Recording indicator (visible to everyone when live is recording)
            if (roomState.isRecording)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'REC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Transcript FAB (if available)
            if (roomState.session?.transcript != null &&
                roomState.session!.transcript!.isNotEmpty)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'transcript_view',
                  backgroundColor: Colors.black54,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Transcript'),
                        content: SingleChildScrollView(
                          child: Text(roomState.session!.transcript!),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fermer'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(Icons.subtitles, color: Colors.white),
                ),
              ),

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.orange.shade800,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Reconnexion au flux vidéo en cours...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/live_room_controller.dart';
import '../../infrastructure/adapters/live_speech_recorder.dart';

class LiveRoomLeaveHelper {
  static Future<void> showLeaveOrEndDialog({
    required BuildContext context,
    required LiveRoomController controller,
    required LiveRoomState roomState,
    required bool isHost,
  }) async {
    final router = GoRouter.of(context);
    final isRecording =
        roomState.isRecording || LiveSpeechRecorder.instance.isRecording;
    final sessionId = roomState.session?.id;

    if (!isHost) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.call_end_rounded, color: Color(0xFFEF4444), size: 24),
              SizedBox(width: 10),
              Text(
                'Quitter l\'appel',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: const Text(
            'Voulez-vous vraiment quitter ce cours en direct ? Vous pourrez le rejoindre à nouveau tant qu\'il est actif.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                context.tr('cancel'),
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.call_end_rounded, size: 16),
              label: const Text(
                'Quitter l\'appel',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          await controller.leaveRoom();
        } catch (e) {
          debugPrint('[LiveRoomLeaveHelper] leaveRoom error: $e');
        }
        router.go('/videoconference');
      }
      return;
    }

    // Host Dialog with 2 Clear Options (Google Meet & Zoom Style)
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        title: Row(
          children: const [
            Icon(Icons.call_end_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text(
              'Quitter ou Terminer l\'appel',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'En tant qu\'enseignant, vous pouvez mettre fin au cours pour toute la classe ou quitter temporairement.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF94A3B8),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Option 1: Terminer l'appel pour tout le monde (End for everyone)
              InkWell(
                onTap: () => Navigator.of(ctx).pop('end_all'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.power_settings_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Terminer l\'appel pour tout le monde',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Clôture la séance et enregistre le cours',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Option 2: Quitter l'appel (Leave room only)
              InkWell(
                onTap: () => Navigator.of(ctx).pop('leave_only'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF334155),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Quitter l\'appel',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Vous quittez sans fermer la salle pour les élèves',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: Text(
              context.tr('cancel'),
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (action == 'end_all') {
      try {
        await controller.endRoomForEveryone();
      } catch (e) {
        debugPrint('[LiveRoomLeaveHelper] endRoomForEveryone error: $e');
      }
      if (sessionId != null && isRecording) {
        router.go('/videoconference/$sessionId/review');
      } else {
        router.go('/videoconference');
      }
    } else if (action == 'leave_only') {
      try {
        await controller.leaveRoom();
      } catch (e) {
        debugPrint('[LiveRoomLeaveHelper] leaveRoom error: $e');
      }
      router.go('/videoconference');
    }
  }
}

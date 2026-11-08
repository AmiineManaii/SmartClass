import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/live_room_controller.dart';

/// Displays a clear recording indicator and participant consent notice
/// whenever server-side recording is active in a LiveKit session.
class RecordingStatusBanner extends ConsumerWidget {
  final bool compact;

  const RecordingStatusBanner({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecording = ref.watch(
      liveRoomControllerProvider.select((s) => s.isRecording),
    );
    if (!isRecording) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.radio_button_checked_rounded,
              color: Color(0xFFEF4444),
              size: 12,
            ),
            const SizedBox(width: 5),
            Text(
              context.tr('rec_active_badge'),
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.radio_button_checked_rounded,
            color: Color(0xFFF87171),
            size: 15,
          ),
          const SizedBox(width: 8),
          Text(
            context.tr('rec_active_badge'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('rec_consent_notice'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFECACA),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


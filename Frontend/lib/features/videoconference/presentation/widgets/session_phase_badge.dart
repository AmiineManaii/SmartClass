import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/session_phase.dart';

class SessionPhaseBadge extends StatelessWidget {
  final SessionPhase phase;

  const SessionPhaseBadge({
    super.key,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String labelKey;
    IconData icon;

    switch (phase) {
      case SessionPhase.live:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        fg = const Color(0xFFDC2626);
        labelKey = 'phase_live';
        icon = Icons.fiber_manual_record;
        break;
      case SessionPhase.joinOpen:
        bg = const Color(0xFF10B981).withValues(alpha: 0.12);
        fg = const Color(0xFF059669);
        labelKey = 'phase_join_open';
        icon = Icons.meeting_room_outlined;
        break;
      case SessionPhase.upcoming:
        bg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        fg = const Color(0xFF2563EB);
        labelKey = 'phase_upcoming';
        icon = Icons.schedule_rounded;
        break;
      case SessionPhase.ended:
        bg = Colors.grey.withValues(alpha: 0.12);
        fg = Colors.grey.shade700;
        labelKey = 'phase_ended';
        icon = Icons.check_circle_outline_rounded;
        break;
      case SessionPhase.canceled:
        bg = Colors.red.withValues(alpha: 0.08);
        fg = Colors.red.shade600;
        labelKey = 'phase_canceled';
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: phase == SessionPhase.live ? 10 : 13,
            color: fg,
          ),
          const SizedBox(width: 5),
          Text(
            context.tr(labelKey),
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

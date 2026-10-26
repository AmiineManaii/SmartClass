import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';
import '../../application/videoconference_providers.dart';
import '../../domain/entities/session_phase.dart';
import '../../domain/entities/video_session.dart';
import 'cancel_session_dialog.dart';
import 'schedule_session_dialog.dart';
import 'session_phase_badge.dart';

class VideoSessionCard extends ConsumerWidget {
  final VideoSession session;
  final bool isTeacher;
  final VoidCallback? onTap;

  const VideoSessionCard({
    super.key,
    required this.session,
    required this.isTeacher,
    this.onTap,
  });

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month à $hour:$min';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final phase = phaseOf(session, DateTime.now());
    final isScheduled = session.status == VideoSessionStatus.scheduled;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class and Subject badge
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (session.className != null &&
                        session.className!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          session.className!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    if (session.subject != null &&
                        session.subject!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          session.subject!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SessionPhaseBadge(phase: phase),
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            session.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (session.description != null &&
              session.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              session.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Host and Timing
          Row(
            children: [
              if (session.hostName != null &&
                  session.hostName!.isNotEmpty) ...[
                Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  session.hostName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Icon(
                Icons.access_time_rounded,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatDateTime(session.startsAt)} - ${_formatTime(session.endsAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (session.participantCount != null &&
                  session.participantCount! > 0) ...[
                Icon(
                  Icons.people_outline_rounded,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.participantCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
          // Action Buttons: Only show when session is active or joinable
          if (phase != SessionPhase.ended && phase != SessionPhase.canceled) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Scheduled session actions for teacher (Edit / Cancel)
                if (isTeacher && isScheduled) ...[
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(context.tr('edit')),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () {
                      ScheduleSessionDialog.show(context, initialSession: session);
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                    label: Text(context.tr('cancel'), style: const TextStyle(color: Colors.red)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => CancelSessionDialog(session: session),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // Live session actions for teacher (End live session)
                if (isTeacher && phase == SessionPhase.live) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.stop_circle_outlined, size: 16, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Terminer',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Terminer la séance ?'),
                          content: const Text(
                              'Voulez-vous clore définitivement cette séance en direct pour tous les participants ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Annuler'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626)),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Terminer pour tous'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref
                            .read(sessionActionsNotifierProvider.notifier)
                            .endSession(session.id);
                        ref.read(videoSessionsProvider('live').notifier).refresh();
                        ref.read(videoSessionsProvider('past').notifier).refresh();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // Join button (for live, lobby, or teacher)
                if (phase == SessionPhase.live || phase == SessionPhase.joinOpen || isTeacher)
                  FilledButton.icon(
                    icon: Icon(
                      phase == SessionPhase.live
                          ? Icons.videocam_rounded
                          : Icons.meeting_room_outlined,
                      size: 16,
                    ),
                    label: Text(
                      phase == SessionPhase.live
                          ? context.tr('join_room')
                          : context.tr('join_lobby'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: phase == SessionPhase.live
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF122675),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () =>
                        context.push('/videoconference/${session.id}/lobby'),
                  ),
              ],
            ),
          ] else if (phase == SessionPhase.ended) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Séance terminée • Heure expirée',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

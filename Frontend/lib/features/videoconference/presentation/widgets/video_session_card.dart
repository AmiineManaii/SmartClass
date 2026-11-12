import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/smart_toast.dart';
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
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m à $h:$min';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _getTeacherInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'PR';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phase = phaseOf(session, DateTime.now());
    final isScheduled = session.status == VideoSessionStatus.scheduled;
    final isLive = phase == SessionPhase.live;
    final isEnded = phase == SessionPhase.ended;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF161F33), const Color(0xFF0F1728)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        border: Border.all(
          color: isLive
              ? const Color(0xFFEF4444).withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF334155).withValues(alpha: 0.55) : const Color(0xFFE2E8F0)),
          width: isLive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                : (isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFF64748B).withValues(alpha: 0.08)),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Class & Subject Pills + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (session.className != null &&
                              session.className!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: isDark ? 0.18 : 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF3B82F6)
                                      .withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.school_rounded,
                                      size: 11, color: Color(0xFF60A5FA)),
                                  const SizedBox(width: 4),
                                  Text(
                                    session.className!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF60A5FA),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (session.subject != null &&
                              session.subject!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                session.subject!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),

                if (session.description != null &&
                    session.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    session.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // Teacher Avatar + Schedule + Participants
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getTeacherInitials(session.hostName),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF93C5FD),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        session.hostName ?? 'Enseignant',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDateTime(session.startsAt)} - ${_formatTime(session.endsAt)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    if (session.participantCount != null &&
                        session.participantCount! > 0) ...[
                      const Icon(Icons.group_rounded,
                          size: 14, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 4),
                      Text(
                        '${session.participantCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ],
                ),

                // AI Highlights Strip for Ended Sessions
                if (isEnded) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF064E3B).withValues(alpha: 0.25), const Color(0xFF1E3A8A).withValues(alpha: 0.20)]
                            : [const Color(0xFFECFDF5), const Color(0xFFEFF6FF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 13, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        const Text('Replay HD • Synthèse & Quiz IA prêts',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Pack complet',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.8),
                const SizedBox(height: 10),

                if (isEnded)
                  _buildEndedActions(context)
                else if (isLive || phase == SessionPhase.joinOpen || isTeacher)
                  _buildActiveActions(context, ref, phase, isScheduled)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndedActions(BuildContext context) {
    return Row(
      children: [
        if (isTeacher) ...[
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.rate_review_rounded,
                  size: 15, color: Color(0xFF93C5FD)),
              label: Text(
                context.tr('btn_review_studio'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF93C5FD),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                side: BorderSide(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                    width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () =>
                  context.push('/videoconference/${session.id}/review'),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.play_circle_fill_rounded,
                size: 16, color: Colors.white),
            label: Text(
              isTeacher
                  ? context.tr('btn_preview_replay')
                  : context.tr('btn_watch_replay'),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () =>
                context.push('/videoconference/${session.id}/replay'),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveActions(
    BuildContext context,
    WidgetRef ref,
    SessionPhase phase,
    bool isScheduled,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (isTeacher && isScheduled) ...[
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: Text(context.tr('edit'), style: const TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: () =>
                ScheduleSessionDialog.show(context, initialSession: session),
          ),
          TextButton.icon(
            icon: const Icon(Icons.cancel_outlined, size: 15, color: Colors.red),
            label: Text(context.tr('cancel'),
                style: const TextStyle(color: Colors.red, fontSize: 12)),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => CancelSessionDialog(session: session),
            ),
          ),
        ],
        if (isTeacher && phase == SessionPhase.live)
          OutlinedButton.icon(
            icon: const Icon(Icons.stop_circle_outlined,
                size: 15, color: Color(0xFFDC2626)),
            label: const Text('Terminer',
                style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFDC2626)),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () async {
              final ok = await showDialog<bool>(
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
              if (ok == true) {
                await ref
                    .read(sessionActionsNotifierProvider.notifier)
                    .endSession(session.id);
                if (context.mounted) {
                  SmartToast.info(context,
                      'La séance a été terminée pour tous les participants.',
                      title: 'Séance clôturée');
                  ref.read(videoSessionsProvider('live').notifier).refresh();
                  ref.read(videoSessionsProvider('past').notifier).refresh();
                }
              }
            },
          ),
        if (phase == SessionPhase.live ||
            phase == SessionPhase.joinOpen ||
            isTeacher)
          FilledButton.icon(
            icon: Icon(
              phase == SessionPhase.live
                  ? Icons.videocam_rounded
                  : Icons.meeting_room_outlined,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              phase == SessionPhase.live
                  ? context.tr('join_room')
                  : context.tr('join_lobby'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: phase == SessionPhase.live
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF2563EB),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () =>
                context.push('/videoconference/${session.id}/lobby'),
          ),
      ],
    );
  }
}

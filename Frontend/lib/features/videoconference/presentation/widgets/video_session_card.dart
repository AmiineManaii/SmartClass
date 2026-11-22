import 'dart:async';

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

class VideoSessionCard extends ConsumerStatefulWidget {
  final VideoSession session;
  final bool isTeacher;
  final VoidCallback? onTap;

  const VideoSessionCard({
    super.key,
    required this.session,
    required this.isTeacher,
    this.onTap,
  });

  @override
  ConsumerState<VideoSessionCard> createState() => _VideoSessionCardState();
}

class _VideoSessionCardState extends ConsumerState<VideoSessionCard> {
  bool _isHovered = false;
  bool _isEnding = false;

  VideoSession get session => widget.session;
  bool get isTeacher => widget.isTeacher;

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDuration(DateTime start, DateTime end) {
    final mins = end.difference(start).inMinutes;
    if (mins <= 0) return '—';
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final rem = mins % 60;
    return rem == 0 ? '${h}h' : '${h}h${rem.toString().padLeft(2, '0')}';
  }

  String _formatRelativeStart(DateTime now) {
    final diff = session.startsAt.difference(now);
    if (diff.isNegative) return 'En cours';
    if (diff.inMinutes < 1) return 'Imminent';
    if (diff.inMinutes < 60) return 'Dans ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return m == 0 ? 'Dans ${h}h' : 'Dans ${h}h${m.toString().padLeft(2, '0')}';
    }
    return 'Dans ${diff.inDays} j';
  }

  String _formatLiveElapsed(DateTime now) {
    final startRef = session.startedAt ?? session.startsAt;
    final mins = now.difference(startRef).inMinutes;
    if (mins <= 0) return 'À l\'instant';
    if (mins < 60) return 'Depuis $mins min';
    final h = mins ~/ 60;
    final rem = mins % 60;
    return 'Depuis ${h}h${rem.toString().padLeft(2, '0')}';
  }

  String _getTeacherInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'PR';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  List<Color> _accentColorsForPhase(SessionPhase phase) {
    switch (phase) {
      case SessionPhase.live:
        return const [Color(0xFFEF4444), Color(0xFFF97316)];
      case SessionPhase.joinOpen:
        return const [Color(0xFF10B981), Color(0xFF06B6D4)];
      case SessionPhase.upcoming:
        return const [Color(0xFF3B82F6), Color(0xFF6366F1)];
      case SessionPhase.ended:
        final s = session.recordingSummary;
        if (s != null && s.isProcessing) {
          return const [Color(0xFFF59E0B), Color(0xFF3B82F6)];
        }
        if (s != null && s.isFailed) {
          return const [Color(0xFFEF4444), Color(0xFFF59E0B)];
        }
        if (s != null && (s.isPublished || s.isReadyForReview)) {
          return const [Color(0xFF10B981), Color(0xFF3B82F6)];
        }
        return const [Color(0xFF64748B), Color(0xFF475569)];
      case SessionPhase.canceled:
        return const [Color(0xFF64748B), Color(0xFF94A3B8)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final phase = phaseOf(session, now);
    final isScheduled = session.status == VideoSessionStatus.scheduled;
    final isLive = phase == SessionPhase.live;
    final isJoinOpen = phase == SessionPhase.joinOpen;
    final isEnded = phase == SessionPhase.ended;
    final accentColors = _accentColorsForPhase(phase);
    final primaryAccent = accentColors.first;

    final borderColor = isLive
        ? const Color(0xFFEF4444).withValues(alpha: _isHovered ? 0.8 : 0.5)
        : (_isHovered
            ? primaryAccent.withValues(alpha: isDark ? 0.55 : 0.45)
            : (isDark
                ? const Color(0xFF334155).withValues(alpha: 0.65)
                : const Color(0xFFE2E8F0)));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF131D31), const Color(0xFF0C1322)]
                : [Colors.white, const Color(0xFFF8FAFC)],
          ),
          border: Border.all(
            color: borderColor,
            width: isLive ? 1.5 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLive
                  ? const Color(0xFFEF4444)
                      .withValues(alpha: _isHovered ? 0.22 : 0.13)
                  : (isDark
                      ? Colors.black.withValues(alpha: _isHovered ? 0.45 : 0.32)
                      : primaryAccent
                          .withValues(alpha: _isHovered ? 0.12 : 0.06)),
              blurRadius: _isHovered ? 24 : 16,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children: [
              // Subtle ambient corner glow matching session status
              Positioned(
                top: -40,
                right: -30,
                child: IgnorePointer(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryAccent.withValues(
                            alpha: isLive
                                ? (isDark ? 0.16 : 0.09)
                                : (isDark ? 0.09 : 0.06),
                          ),
                          primaryAccent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Main card body
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(19),
                  onTap: widget.onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top signature gradient strip
                      Container(
                        height: 3.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: accentColors),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Header Row: Class/Subject tags + Live/Phase Badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 5,
                                    children: [
                                      if (session.className != null &&
                                          session.className!.isNotEmpty)
                                        _MetaTagChip(
                                          icon: Icons.school_rounded,
                                          label: session.className!,
                                          color: const Color(0xFF60A5FA),
                                          isDark: isDark,
                                        ),
                                      if (session.subject != null &&
                                          session.subject!.isNotEmpty)
                                        _MetaTagChip(
                                          icon: Icons.auto_stories_rounded,
                                          label: session.subject!,
                                          color: isDark
                                              ? const Color(0xFFCBD5E1)
                                              : const Color(0xFF475569),
                                          isDark: isDark,
                                          neutral: true,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isLive)
                                  const _PulsingLiveBadge()
                                else
                                  SessionPhaseBadge(phase: phase),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // 2. Title & optional description
                            Text(
                              session.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.35,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                height: 1.25,
                              ),
                            ),

                            if (session.description != null &&
                                session.description!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                session.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],

                            const SizedBox(height: 13),

                            // 3. Host + Schedule + Duration + Participants strip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.035)
                                    : const Color(0xFFF1F5F9)
                                        .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Host avatar
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF3B82F6)
                                              .withValues(alpha: 0.9),
                                          const Color(0xFF6366F1)
                                              .withValues(alpha: 0.9),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF3B82F6)
                                              .withValues(alpha: 0.25),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _getTeacherInitials(session.hostName),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          session.hostName ?? 'Enseignant',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 10.5,
                                              color: isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                '${_formatDate(session.startsAt)} • ${_formatTime(session.startsAt)} – ${_formatTime(session.endsAt)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Duration chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 11.5,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          _formatDuration(
                                            session.startsAt,
                                            session.endsAt,
                                          ),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? const Color(0xFFCBD5E1)
                                                : const Color(0xFF334155),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (session.participantCount != null &&
                                      session.participantCount! > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6)
                                            .withValues(
                                                alpha: isDark ? 0.2 : 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.group_rounded,
                                            size: 12,
                                            color: Color(0xFF60A5FA),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${session.participantCount}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF60A5FA),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 11),

                            // 4. Contextual Highlight Strip (Live / JoinOpen / Upcoming / Real AI Status)
                            if (isEnded)
                              _SessionAiStatusStrip(
                                summary: session.recordingSummary,
                                isTeacher: isTeacher,
                                isDark: isDark,
                              )
                            else if (isLive)
                              _buildContextualStrip(
                                icon: Icons.podcasts_rounded,
                                label:
                                    'Salle en direct active • Flux HD & Partage',
                                badge: _formatLiveElapsed(now),
                                color: const Color(0xFFEF4444),
                                isDark: isDark,
                              )
                            else if (isJoinOpen)
                              _buildContextualStrip(
                                icon: Icons.meeting_room_rounded,
                                label: 'Salle d\'attente ouverte • Prêt à démarrer',
                                badge: 'Accès ouvert',
                                color: const Color(0xFF10B981),
                                isDark: isDark,
                              )
                            else if (isScheduled)
                              _buildContextualStrip(
                                icon: Icons.event_available_rounded,
                                label:
                                    'Ouverture de la salle ${session.joinOpensMinutesBefore} min avant le début',
                                badge: _formatRelativeStart(now),
                                color: const Color(0xFF60A5FA),
                                isDark: isDark,
                              ),

                            const SizedBox(height: 14),

                            // 5. Action Footer
                            if (isEnded)
                              _buildEndedActions(context)
                            else if (isLive || isJoinOpen || isTeacher)
                              _buildActiveActions(context, phase, isScheduled),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextualStrip({
    required IconData icon,
    required String label,
    required String badge,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.11 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.2,
                fontWeight: FontWeight.w700,
                color: isDark ? color : color.withValues(alpha: 0.95),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndedActions(BuildContext context) {
    final summary = session.recordingSummary;
    final isProcessing = summary?.isProcessing ?? false;
    final isFailed = summary?.isFailed ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        if (isTeacher) ...[
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(
                isProcessing
                    ? Icons.hourglass_top_rounded
                    : (isFailed
                        ? Icons.refresh_rounded
                        : Icons.auto_awesome_rounded),
                size: 15,
                color: isProcessing
                    ? const Color(0xFFF59E0B)
                    : (isFailed
                        ? const Color(0xFFF87171)
                        : const Color(0xFF93C5FD)),
              ),
              label: Text(
                isProcessing
                    ? 'Suivre l\'analyse IA'
                    : (isFailed
                        ? 'Relancer dans le Studio'
                        : context.tr('btn_review_studio')),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isProcessing
                      ? const Color(0xFFFBBF24)
                      : (isFailed
                          ? const Color(0xFFFCA5A5)
                          : (isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF1D4ED8))),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                    : const Color(0xFFEFF6FF),
                side: BorderSide(
                  color: (isProcessing
                          ? const Color(0xFFF59E0B)
                          : (isFailed
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF3B82F6)))
                      .withValues(alpha: 0.5),
                  width: 1.2,
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              onPressed: () async {
                await context.push('/videoconference/${session.id}/review');
                if (context.mounted) {
                  ref
                      .read(videoSessionsProvider('past').notifier)
                      .silentRefresh();
                }
              },
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(
              Icons.play_circle_fill_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              isTeacher
                  ? context.tr('btn_preview_replay')
                  : context.tr('btn_watch_replay'),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            onPressed: () async {
              await context.push('/videoconference/${session.id}/replay');
              if (context.mounted) {
                ref.read(videoSessionsProvider('past').notifier).silentRefresh();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveActions(
    BuildContext context,
    SessionPhase phase,
    bool isScheduled,
  ) {
    final isLive = phase == SessionPhase.live;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLive) {
      return Row(
        children: [
          if (isTeacher) ...[
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                icon: _isEnding
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFEF4444),
                        ),
                      )
                    : const Icon(
                        Icons.power_settings_new_rounded,
                        size: 15,
                        color: Color(0xFFEF4444),
                      ),
                label: Text(
                  _isEnding ? 'Clôture...' : 'Terminer',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFFEF4444),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFEF4444).withValues(alpha: 0.08),
                  side: BorderSide(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.55),
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                onPressed: _isEnding ? null : () => _confirmEndSession(context),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 6,
            child: FilledButton.icon(
              icon: const Icon(
                Icons.videocam_rounded,
                size: 17,
                color: Colors.white,
              ),
              label: Text(
                context.tr('join_room'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 11),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              onPressed: () =>
                  context.push('/videoconference/${session.id}/lobby'),
            ),
          ),
        ],
      );
    }

    // Scheduled / Join Open actions
    return Row(
      children: [
        if (isTeacher && isScheduled) ...[
          Tooltip(
            message: context.tr('edit'),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                minimumSize: const Size(0, 40),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () =>
                  ScheduleSessionDialog.show(context, initialSession: session),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF334155),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    context.tr('edit'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: context.tr('cancel'),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                minimumSize: const Size(0, 40),
                side: BorderSide(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => CancelSessionDialog(session: session),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(
              Icons.meeting_room_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              context.tr('join_lobby'),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: phase == SessionPhase.joinOpen
                  ? const Color(0xFF059669)
                  : const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 11),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            onPressed: () =>
                context.push('/videoconference/${session.id}/lobby'),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmEndSession(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: const Row(
          children: [
            Icon(Icons.power_settings_new_rounded,
                color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 10),
            Text(
              'Terminer la séance ?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: const Text(
          'Voulez-vous clore définitivement cette séance en direct pour tous les participants ? L\'enregistrement en cours sera sauvegardé et analysé par l\'IA.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('Annuler', style: TextStyle(color: Colors.white60)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Terminer pour tous'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _isEnding = true);
    try {
      await ref
          .read(sessionActionsNotifierProvider.notifier)
          .endSession(session.id);
      if (context.mounted) {
        SmartToast.success(
          context,
          'La séance a été clôturée pour tous les participants.',
          title: 'Séance terminée',
        );
        ref.read(videoSessionsProvider('live').notifier).silentRefresh();
        ref.read(videoSessionsProvider('past').notifier).silentRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        SmartToast.error(
          context,
          'Impossible de clôturer la séance : $e',
          title: 'Erreur',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnding = false);
      }
    }
  }
}

class _MetaTagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool neutral;

  const _MetaTagChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: neutral
            ? (isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9))
            : color.withValues(alpha: isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: neutral
              ? (isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0))
              : color.withValues(alpha: 0.32),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingLiveBadge extends StatelessWidget {
  const _PulsingLiveBadge();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 6.5,
              height: 6.5,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            context.tr('phase_live'),
            style: TextStyle(
              fontFamily: 'Inter',
              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionAiStatusStrip extends StatelessWidget {
  final VideoSessionRecordingSummary? summary;
  final bool isTeacher;
  final bool isDark;

  const _SessionAiStatusStrip({
    required this.summary,
    required this.isTeacher,
    required this.isDark,
  });

  String _stageShortLabel(String? stage) {
    switch (stage) {
      case 'VALIDATION':
        return 'Validation vidéo';
      case 'AUDIO_EXTRACTION':
        return 'Extraction audio';
      case 'TRANSCRIPTION':
        return 'Transcription vocale';
      case 'VISUAL_ANALYSIS':
        return 'Analyse slides & vision';
      case 'DOCUMENT_ANALYSIS':
        return 'Analyse supports';
      case 'TEMPORAL_ALIGNMENT':
        return 'Découpage chapitres';
      case 'LESSON_GENERATION':
        return 'Génération synthèse & quiz';
      case 'QUALITY_VALIDATION':
        return 'Contrôle qualité IA';
      case 'COMPLETED':
        return 'Finalisation';
      default:
        return 'Préparation IA';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = summary;

    // 1. Actively processing
    if (s != null && s.isProcessing) {
      final progress = (s.jobProgress ?? 8).clamp(4, 99);
      final stageLabel = s.status == 'FINALIZING'
          ? 'Finalisation vidéo'
          : _stageShortLabel(s.jobStage);

      return Container(
        padding: const EdgeInsets.fromLTRB(11, 7, 11, 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF78350F).withValues(alpha: 0.28),
                    const Color(0xFF1E3A8A).withValues(alpha: 0.24),
                  ]
                : [const Color(0xFFFFFBEB), const Color(0xFFEFF6FF)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'IA en cours • $stageLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.5,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B)
                        .withValues(alpha: isDark ? 0.22 : 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$progress%',
                        style: const TextStyle(
                          fontSize: 9.8,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                      if (s.jobStartedAt != null) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 9.8,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFBBF24),
                          ),
                        ),
                        _CompactElapsedTimer(startedAt: s.jobStartedAt!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 100.0,
                minHeight: 3.5,
                backgroundColor:
                    const Color(0xFFF59E0B).withValues(alpha: 0.18),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Failed (e.g. Ollama offline)
    if (s != null && s.isFailed) {
      final isOffline = s.errorCode == 'AI_OFFLINE';
      return _buildStrip(
        icon: isOffline
            ? Icons.cloud_off_rounded
            : Icons.error_outline_rounded,
        label: isOffline
            ? 'IA hors ligne (Ollama arrêté) • Analyse en attente'
            : 'Échec de la génération du résumé IA',
        badge: isOffline ? 'IA hors ligne' : 'Échec IA',
        color: const Color(0xFFEF4444),
        darkGradStart: const Color(0xFF7F1D1D).withValues(alpha: 0.28),
        darkGradEnd: const Color(0xFF78350F).withValues(alpha: 0.20),
        lightGradStart: const Color(0xFFFEF2F2),
        lightGradEnd: const Color(0xFFFFF7ED),
      );
    }

    // 3. Published for students
    if (s != null && s.isPublished) {
      return _buildStrip(
        icon: Icons.verified_rounded,
        label: 'Replay HD • Résumé & Quiz IA publiés',
        badge: 'Publié',
        color: const Color(0xFF10B981),
        darkGradStart: const Color(0xFF064E3B).withValues(alpha: 0.25),
        darkGradEnd: const Color(0xFF1E3A8A).withValues(alpha: 0.20),
        lightGradStart: const Color(0xFFECFDF5),
        lightGradEnd: const Color(0xFFEFF6FF),
      );
    }

    // 4. Ready for teacher review / approved
    if (s != null && s.isReadyForReview) {
      if (!isTeacher) {
        return _buildStrip(
          icon: Icons.hourglass_bottom_rounded,
          label: 'Résumé IA en cours de validation par l\'enseignant',
          badge: 'En attente',
          color: const Color(0xFF60A5FA),
          darkGradStart: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
          darkGradEnd: const Color(0xFF1E293B).withValues(alpha: 0.30),
          lightGradStart: const Color(0xFFEFF6FF),
          lightGradEnd: const Color(0xFFF8FAFC),
        );
      }
      return _buildStrip(
        icon: Icons.auto_awesome_rounded,
        label: s.isApproved
            ? 'Replay HD • Résumé IA approuvé (prêt à publier)'
            : 'Replay HD • Résumé & Quiz IA prêts à valider',
        badge: s.isApproved ? 'Approuvé' : 'Résumé prêt',
        color: const Color(0xFF10B981),
        darkGradStart: const Color(0xFF064E3B).withValues(alpha: 0.25),
        darkGradEnd: const Color(0xFF1E3A8A).withValues(alpha: 0.20),
        lightGradStart: const Color(0xFFECFDF5),
        lightGradEnd: const Color(0xFFEFF6FF),
      );
    }

    // 5. No recording / not started
    return _buildStrip(
      icon: Icons.videocam_off_outlined,
      label: 'Aucun enregistrement IA pour cette séance',
      badge: 'Sans replay',
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      darkGradStart: const Color(0xFF1E293B).withValues(alpha: 0.60),
      darkGradEnd: const Color(0xFF0F172A).withValues(alpha: 0.60),
      lightGradStart: const Color(0xFFF8FAFC),
      lightGradEnd: const Color(0xFFF1F5F9),
    );
  }

  Widget _buildStrip({
    required IconData icon,
    required String label,
    required String badge,
    required Color color,
    required Color darkGradStart,
    required Color darkGradEnd,
    required Color lightGradStart,
    required Color lightGradEnd,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [darkGradStart, darkGradEnd]
              : [lightGradStart, lightGradEnd],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.2,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 9.8,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactElapsedTimer extends StatefulWidget {
  final DateTime startedAt;

  const _CompactElapsedTimer({required this.startedAt});

  @override
  State<_CompactElapsedTimer> createState() => _CompactElapsedTimerState();
}

class _CompactElapsedTimerState extends State<_CompactElapsedTimer> {
  Timer? _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = _computeElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = _computeElapsed());
    });
  }

  @override
  void didUpdateWidget(covariant _CompactElapsedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt) {
      _elapsed = _computeElapsed();
    }
  }

  Duration _computeElapsed() {
    final diff = DateTime.now().difference(widget.startedAt);
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = _elapsed.inMinutes.toString().padLeft(2, '0');
    final secs = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$mins:$secs',
      style: const TextStyle(
        fontSize: 9.8,
        fontWeight: FontWeight.w800,
        color: Color(0xFFFBBF24),
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

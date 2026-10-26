import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../videoconference/domain/entities/session_phase.dart';
import '../../../videoconference/domain/entities/video_session.dart';
import '../../domain/entities/today_live_session.dart';

/// Rendered ONLY when [session] comes from real data (see
/// `studentTodayLiveProvider`). Never feed invented sessions.
///
/// Features pure presentation visual ticking for clock-skew compensated countdown,
/// real-time phase badge, and dynamic join CTA button state.
class StudentImminentLiveCard extends StatefulWidget {
  final TodayLiveSession session;
  final VoidCallback onJoin;

  const StudentImminentLiveCard({
    required this.session,
    required this.onJoin,
    super.key,
  });

  @override
  State<StudentImminentLiveCard> createState() => _StudentImminentLiveCardState();
}

class _StudentImminentLiveCardState extends State<StudentImminentLiveCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _ticker;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Pure presentation ticking timer (1s) — purely updates local UI state, NO network requests!
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  SessionPhase _computePhase() {
    final videoSession = widget.session.videoSession;
    if (videoSession != null) {
      return phaseOf(videoSession, _currentTime, serverOffset: widget.session.serverOffset);
    }
    if (widget.session.minutesRemaining <= 0) {
      return SessionPhase.live;
    }
    return SessionPhase.upcoming;
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final session = widget.session;
    final videoSession = session.videoSession;
    final phase = _computePhase();
    if (phase == SessionPhase.ended ||
        phase == SessionPhase.canceled ||
        videoSession?.status == VideoSessionStatus.completed ||
        videoSession?.status == VideoSessionStatus.canceled) {
      return const SizedBox.shrink();
    }

    final adjustedNow = _currentTime.add(session.serverOffset);

    // Compute countdown string and timing details
    String countdownLabel;
    final bool canJoin;

    switch (phase) {
      case SessionPhase.live:
        countdownLabel = context.tr('in_progress');
        canJoin = true;
        break;
      case SessionPhase.joinOpen:
        if (videoSession != null) {
          final diff = videoSession.startsAt.difference(adjustedNow);
          countdownLabel = 'Début dans ${_formatDuration(diff)}';
        } else {
          countdownLabel = 'Accès ouvert';
        }
        canJoin = true;
        break;
      case SessionPhase.upcoming:
        if (videoSession != null) {
          final joinOpensAt = videoSession.startsAt.subtract(
            Duration(minutes: videoSession.joinOpensMinutesBefore),
          );
          final diff = joinOpensAt.difference(adjustedNow);
          countdownLabel = 'Ouverture dans ${_formatDuration(diff)}';
        } else {
          countdownLabel = context.tr(
            'in_minutes',
            args: {'min': session.minutesRemaining.toString()},
          );
        }
        canJoin = false;
        break;
      case SessionPhase.ended:
      case SessionPhase.canceled:
        countdownLabel = context.tr('session_ended');
        canJoin = false;
        break;
    }

    // Badge styling depending on phase
    final Color badgeBg;
    final Color badgeFg;
    final String badgeText;
    final bool showPulse;

    if (phase == SessionPhase.live) {
      badgeBg = colorScheme.errorContainer;
      badgeFg = colorScheme.onErrorContainer;
      badgeText = context.tr('tab_live');
      showPulse = true;
    } else if (phase == SessionPhase.joinOpen) {
      badgeBg = const Color(0xFF10B981).withValues(alpha: 0.2);
      badgeFg = const Color(0xFF10B981);
      badgeText = 'ACCÈS OUVERT';
      showPulse = false;
    } else {
      badgeBg = colorScheme.secondaryContainer;
      badgeFg = colorScheme.onSecondaryContainer;
      badgeText = context.tr('live_imminent');
      showPulse = false;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: phase == SessionPhase.live
              ? colorScheme.error.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: phase == SessionPhase.live ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: phase == SessionPhase.live
                ? colorScheme.error.withValues(alpha: 0.08)
                : colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Soft ambient decorative blur
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (Theme.of(context).brightness == Brightness.dark)
                    ? colorScheme.secondary.withValues(alpha: 0.12)
                    : colorScheme.secondaryFixed.withValues(alpha: 0.25),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Phase Badge + Time + Countdown
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showPulse)
                                FadeTransition(
                                  opacity: _pulseAnimation,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colorScheme.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              if (showPulse) const SizedBox(width: 6),
                              Text(
                                badgeText,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: badgeFg,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          session.time,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            countdownLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Title & Subtitle
                Text(
                  session.subject,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.instructor} · ${session.chapter}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                // Footer: Avatar Stack & CTA button
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    // Avatar stack
                    _AttendeeAvatarStack(
                      initials: session.attendeesInitials,
                      remainingCount: session.extraAttendeesCount,
                    ),
                    // Action button
                    ElevatedButton.icon(
                      onPressed: canJoin ? widget.onJoin : null,
                      icon: Icon(
                        phase == SessionPhase.live
                            ? Icons.sensors_rounded
                            : Icons.videocam_rounded,
                        size: 20,
                      ),
                      label: Text(
                        phase == SessionPhase.live
                            ? context.tr('join_live')
                            : (phase == SessionPhase.joinOpen
                                ? context.tr('join_lobby')
                                : 'Bientôt disponible'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: phase == SessionPhase.live
                            ? colorScheme.error
                            : colorScheme.secondaryContainer,
                        foregroundColor: phase == SessionPhase.live
                            ? Colors.white
                            : colorScheme.onSecondaryContainer,
                        disabledBackgroundColor:
                            colorScheme.surfaceContainerHighest,
                        disabledForegroundColor:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        elevation: 0,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeeAvatarStack extends StatelessWidget {
  final List<String> initials;
  final int remainingCount;

  const _AttendeeAvatarStack({
    required this.initials,
    required this.remainingCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final avatarColors = [
      (colorScheme.primaryFixed, colorScheme.onPrimaryFixed),
      (colorScheme.secondaryFixed, colorScheme.onSecondaryFixed),
      (colorScheme.tertiaryFixed, colorScheme.onTertiaryFixed),
    ];

    return SizedBox(
      height: 28,
      width: 28.0 + (initials.length * 18.0),
      child: Stack(
        children: [
          for (int i = 0; i < initials.length; i++)
            Positioned(
              left: i * 18.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: avatarColors[i % avatarColors.length].$1,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surfaceContainerLowest,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials[i],
                  style: TextStyle(
                    color: avatarColors[i % avatarColors.length].$2,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            left: initials.length * 18.0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surfaceContainerLowest,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '+$remainingCount',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

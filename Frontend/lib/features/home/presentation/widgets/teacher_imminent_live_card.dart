import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../videoconference/domain/entities/session_phase.dart';
import '../../../videoconference/domain/entities/video_session.dart';

/// Card displayed on the teacher dashboard when the teacher has an active
/// or imminent live videoconference session.
///
/// Features pure presentation visual ticking for clock-skew compensated countdown,
/// real-time participant counter with attendee avatar stack, phase badge, and dynamic action buttons.
class TeacherImminentLiveCard extends StatefulWidget {
  final VideoSession session;
  final Duration serverOffset;

  const TeacherImminentLiveCard({
    required this.session,
    this.serverOffset = Duration.zero,
    super.key,
  });

  @override
  State<TeacherImminentLiveCard> createState() => _TeacherImminentLiveCardState();
}

class _TeacherImminentLiveCardState extends State<TeacherImminentLiveCard>
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

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
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
    return phaseOf(widget.session, _currentTime, serverOffset: widget.serverOffset);
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
    final isDark = theme.brightness == Brightness.dark;
    final session = widget.session;
    final phase = _computePhase();

    if (phase == SessionPhase.ended ||
        phase == SessionPhase.canceled ||
        session.status == VideoSessionStatus.completed ||
        session.status == VideoSessionStatus.canceled) {
      return const SizedBox.shrink();
    }

    final adjustedNow = _currentTime.add(widget.serverOffset);

    String countdownLabel;
    final bool canStartOrJoin;

    switch (phase) {
      case SessionPhase.live:
        countdownLabel = context.tr('in_progress');
        canStartOrJoin = true;
        break;
      case SessionPhase.joinOpen:
        final diff = session.startsAt.difference(adjustedNow);
        countdownLabel = 'Début dans ${_formatDuration(diff)}';
        canStartOrJoin = true;
        break;
      case SessionPhase.upcoming:
        final joinOpensAt = session.startsAt.subtract(
          Duration(minutes: session.joinOpensMinutesBefore),
        );
        final diff = joinOpensAt.difference(adjustedNow);
        countdownLabel = 'Sas ouvert dans ${_formatDuration(diff)}';
        canStartOrJoin = false;
        break;
      case SessionPhase.ended:
      case SessionPhase.canceled:
        countdownLabel = context.tr('session_ended');
        canStartOrJoin = false;
        break;
    }

    final Color badgeBg;
    final Color badgeFg;
    final String badgeText;
    final bool showPulse;
    final Color cardBorderColor;
    final Color ambientColor;

    if (phase == SessionPhase.live) {
      badgeBg = colorScheme.errorContainer;
      badgeFg = colorScheme.onErrorContainer;
      badgeText = context.tr('tab_live');
      showPulse = true;
      cardBorderColor = colorScheme.error.withValues(alpha: isDark ? 0.6 : 0.4);
      ambientColor = colorScheme.error.withValues(alpha: isDark ? 0.14 : 0.08);
    } else if (phase == SessionPhase.joinOpen) {
      badgeBg = const Color(0xFF10B981).withValues(alpha: 0.2);
      badgeFg = const Color(0xFF10B981);
      badgeText = 'ACCÈS OUVERT';
      showPulse = false;
      cardBorderColor = const Color(0xFF10B981).withValues(alpha: 0.5);
      ambientColor = const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.07);
    } else {
      badgeBg = colorScheme.secondaryContainer;
      badgeFg = colorScheme.onSecondaryContainer;
      badgeText = 'PROGRAMMÉE';
      showPulse = false;
      cardBorderColor = const Color(0xFF4056B9).withValues(alpha: isDark ? 0.45 : 0.25);
      ambientColor = const Color(0xFF4056B9).withValues(alpha: isDark ? 0.12 : 0.06);
    }

    final participantCount = session.participantCount ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardBorderColor,
          width: phase == SessionPhase.live ? 1.75 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: ambientColor,
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ambient decorative soft blur circle
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ambientColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Status Badges & Class Pill & Timing
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Live / Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.error.withValues(alpha: 0.6),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (showPulse) const SizedBox(width: 6),
                              Text(
                                badgeText,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: badgeFg,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Class Name Pill
                        if (session.className != null && session.className!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFC7D2FE),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 13,
                                  color: isDark
                                      ? const Color(0xFF93C5FD)
                                      : const Color(0xFF4338CA),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  session.className!,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFE2E8F0)
                                        : const Color(0xFF3730A3),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Countdown / Clock Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            countdownLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Title & Subject Line
                Text(
                  session.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.2,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (session.subject != null && session.subject!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    session.subject!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Bottom Row: Attendee Avatar Stack & Action Button
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Real-time Attendee Avatar Stack or Waiting Indicator
                    if (participantCount > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TeacherAttendeeAvatarStack(
                            count: participantCount,
                            initials: _generateInitials(participantCount),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$participantCount en direct',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.group_outlined,
                              size: 16,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              phase == SessionPhase.live
                                  ? 'En attente d\'élèves...'
                                  : '0 participant',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Action Button (Rejoindre / Démarrer)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/videoconference/${session.id}/lobby');
                      },
                      icon: Icon(
                        phase == SessionPhase.live
                            ? Icons.sensors_rounded
                            : (phase == SessionPhase.joinOpen
                                ? Icons.play_arrow_rounded
                                : Icons.videocam_rounded),
                        size: 19,
                      ),
                      label: Text(
                        phase == SessionPhase.live
                            ? context.tr('join_room')
                            : (canStartOrJoin
                                ? context.tr('start_session')
                                : context.tr('join_lobby')),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: phase == SessionPhase.live
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        elevation: phase == SessionPhase.live ? 4 : 2,
                        shadowColor: phase == SessionPhase.live
                            ? const Color(0xFFDC2626).withValues(alpha: 0.4)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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

  List<String> _generateInitials(int count) {
    const defaultInitials = ['AM', 'SC', 'ET', 'JD', 'KL', 'MR'];
    return defaultInitials.take(count.clamp(1, 3)).toList();
  }
}

class _TeacherAttendeeAvatarStack extends StatelessWidget {
  final int count;
  final List<String> initials;

  const _TeacherAttendeeAvatarStack({
    required this.count,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final avatarColors = [
      (const Color(0xFF3B82F6), Colors.white),
      (const Color(0xFF10B981), Colors.white),
      (const Color(0xFF8B5CF6), Colors.white),
    ];

    final displayedCount = initials.length;
    final remaining = count - displayedCount;

    return SizedBox(
      height: 28,
      width: 28.0 + (displayedCount * 18.0) + (remaining > 0 ? 18.0 : 0.0),
      child: Stack(
        children: [
          for (int i = 0; i < displayedCount; i++)
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 3,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials[i],
                  style: TextStyle(
                    color: avatarColors[i % avatarColors.length].$2,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: displayedCount * 18.0,
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
                  '+$remaining',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/live_room_controller.dart';

/// Ultra-modern, premium connecting overlay displayed when entering a live videoconference session.
/// Features concentric glowing radar pulses, sleek glassmorphism, animated status messages,
/// and a quick-cancel button.
class LiveRoomConnectingOverlay extends ConsumerStatefulWidget {
  const LiveRoomConnectingOverlay({super.key});

  @override
  ConsumerState<LiveRoomConnectingOverlay> createState() =>
      _LiveRoomConnectingOverlayState();
}

class _LiveRoomConnectingOverlayState extends ConsumerState<LiveRoomConnectingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _spinController;
  late final Animation<double> _radar1;
  late final Animation<double> _radar2;
  late final Animation<double> _opacity1;
  late final Animation<double> _opacity2;

  Timer? _statusTimer;
  int _statusIndex = 0;

  final List<String> _statusMessages = const [
    'Établissement de la liaison WebRTC...',
    'Synchronisation audio & vidéo HD...',
    'Connexion à la salle de classe...',
    'Finalisation du flux en direct...',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _radar1 = Tween<double>(begin: 0.8, end: 2.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _opacity1 = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _radar2 = Tween<double>(begin: 0.8, end: 2.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _opacity2 = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _statusTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (mounted) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _statusMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _pulseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(
      liveRoomControllerProvider.select((s) => s.session),
    );
    final sessionTitle = session?.title ?? 'Session de cours';
    final subject = session?.subject;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.15),
          radius: 1.2,
          colors: [
            Color(0xFF131D36),
            Color(0xFF090D18),
            Color(0xFF04060B),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Ambient soft background glow spots
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15,
              left: MediaQuery.of(context).size.width * 0.5 - 120,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Top Header: Live Pill & Class Subject
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF38BDF8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          subject != null && subject.isNotEmpty
                              ? '$subject • $sessionTitle'
                              : sessionTitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Center Content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Concentric Radar Rings & Central Icon
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Radar Ring 1
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _radar1.value,
                                child: Opacity(
                                  opacity: _opacity1.value.clamp(0.0, 1.0),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF3B82F6),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Radar Ring 2
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _radar2.value,
                                child: Opacity(
                                  opacity: _opacity2.value.clamp(0.0, 1.0),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF60A5FA),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Spinning Modern Loader Border
                          RotationTransition(
                            turns: _spinController,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    Color(0x003B82F6),
                                    Color(0xFF38BDF8),
                                    Color(0xFF2563EB),
                                  ],
                                  stops: [0.0, 0.6, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // Central Glassmorphic Core
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.sensors_rounded,
                                color: Color(0xFF38BDF8),
                                size: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Title
                    const Text(
                      'Connexion au cours en direct',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // Dynamic Subtitle Status Message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusMessages[_statusIndex],
                        key: ValueKey<int>(_statusIndex),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Security & Protocol Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Chiffré E2EE • WebRTC HD',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF6EE7B7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Cancel / Leave CTA
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    ref.read(liveRoomControllerProvider.notifier).leaveRoom();
                    if (context.mounted) {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/videoconference');
                      }
                    }
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white60,
                    size: 18,
                  ),
                  label: const Text(
                    'Annuler et quitter',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/live_room_controller.dart';

/// Floating notification banner and celebratory particle effect shown
/// whenever a participant (local or remote) clicks the wave / raise hand icon.
class HandRaiseNoticeOverlay extends ConsumerStatefulWidget {
  const HandRaiseNoticeOverlay({super.key});

  @override
  ConsumerState<HandRaiseNoticeOverlay> createState() => _HandRaiseNoticeOverlayState();
}

class _HandRaiseNoticeOverlayState extends ConsumerState<HandRaiseNoticeOverlay>
    with TickerProviderStateMixin {
  HandRaiseNotice? _currentNotice;
  Timer? _dismissTimer;

  // Banner slide & fade animation
  late final AnimationController _bannerController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  // Waving hand rotation wobble
  late final AnimationController _waveController;
  late final Animation<double> _waveAnimation;

  // Floating particles
  final List<_FloatingWaveParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bannerController, curve: Curves.easeIn),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _waveAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.25, end: -0.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _waveController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _bannerController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onHandRaised(HandRaiseNotice notice) {
    if (!notice.isRaised) return;

    // Trigger audible alert and haptic feedback
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    } catch (_) {
      // Best-effort sound on platforms without system sound
    }

    setState(() {
      _currentNotice = notice;
    });

    _bannerController.forward(from: 0.0);
    _waveController.repeat(reverse: true);

    // Spawn floating wave particles
    _spawnParticles();

    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(milliseconds: 3800), () {
      if (mounted) {
        _bannerController.reverse().then((_) {
          if (mounted) {
            _waveController.stop();
            setState(() {
              _currentNotice = null;
            });
          }
        });
      }
    });
  }

  void _spawnParticles() {
    final rand = math.Random();
    for (int i = 0; i < 4; i++) {
      final particle = _FloatingWaveParticle(
        id: DateTime.now().microsecondsSinceEpoch + i,
        startX: 0.4 + (rand.nextDouble() * 0.4),
        startY: 0.75 + (rand.nextDouble() * 0.1),
        size: 24.0 + (rand.nextDouble() * 16.0),
        driftX: (rand.nextDouble() - 0.5) * 80,
      );
      _particles.add(particle);
    }
  }

  void _removeParticle(int id) {
    setState(() {
      _particles.removeWhere((p) => p.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localIdentity = ref.watch(
      liveRoomControllerProvider.select((s) => s.localParticipant?.identity),
    );

    // Listen to hand raise events reactively
    ref.listen<HandRaiseNotice?>(
      liveRoomControllerProvider.select((s) => s.latestHandRaise),
      (prev, next) {
        if (next != null && next.isRaised) {
          _onHandRaised(next);
        }
      },
    );

    final isSelf = _currentNotice != null &&
        localIdentity != null &&
        _currentNotice!.identity == localIdentity;

    final displayName = _currentNotice?.displayName ?? 'Un participant';

    return IgnorePointer(
      ignoring: _currentNotice == null,
      child: Stack(
        children: [
          // Floating wave particles
          for (final p in _particles)
            _ParticleWidget(
              key: ValueKey(p.id),
              particle: p,
              onComplete: () => _removeParticle(p.id),
            ),

          // Top floating notification banner
          if (_currentNotice != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14, left: 16, right: 16),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: GestureDetector(
                        onTap: () {
                          _bannerController.reverse().then((_) {
                            if (mounted) {
                              setState(() => _currentNotice = null);
                            }
                          });
                        },
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 380),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD97706), Color(0xFFB45309)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFDE68A).withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD97706).withValues(alpha: 0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Waving Hand Icon with Wobble Rotation
                              AnimatedBuilder(
                                animation: _waveAnimation,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _waveAnimation.value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      width: 1.2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '👋',
                                    style: TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Text details
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            isSelf
                                                ? 'Vous avez levé la main ✋'
                                                : '$displayName a levé la main ✋',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isSelf
                                          ? 'Prêt pour prendre la parole'
                                          : 'Demande la parole dans le cours',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Dismiss icon
                              Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingWaveParticle {
  final int id;
  final double startX;
  final double startY;
  final double size;
  final double driftX;

  const _FloatingWaveParticle({
    required this.id,
    required this.startX,
    required this.startY,
    required this.size,
    required this.driftX,
  });
}

class _ParticleWidget extends StatefulWidget {
  final _FloatingWaveParticle particle;
  final VoidCallback onComplete;

  const _ParticleWidget({
    super.key,
    required this.particle,
    required this.onComplete,
  });

  @override
  State<_ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<_ParticleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _translateY;
  late final Animation<double> _translateX;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _translateY = Tween<double>(begin: 0, end: -160).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _translateX = Tween<double>(
      begin: 0,
      end: widget.particle.driftX,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 40),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final baseX = size.width * widget.particle.startX;
    final baseY = size.height * widget.particle.startY;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: baseX + _translateX.value,
          top: baseY + _translateY.value,
          child: Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: _scale.value,
              child: Text(
                '👋',
                style: TextStyle(fontSize: widget.particle.size),
              ),
            ),
          ),
        );
      },
    );
  }
}

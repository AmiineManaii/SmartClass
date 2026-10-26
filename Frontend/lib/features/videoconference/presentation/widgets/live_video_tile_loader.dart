import 'package:flutter/material.dart';

/// An ultra-smooth, glowing video tile loading state widget.
/// Used inside video grid slots when waiting for peer or local video tracks to initialize.
class LiveVideoTileLoader extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool compact;

  const LiveVideoTileLoader({
    super.key,
    this.title = 'Initialisation du flux vidéo HD...',
    this.subtitle = 'Synchronisation des caméras et micros',
    this.compact = false,
  });

  @override
  State<LiveVideoTileLoader> createState() => _LiveVideoTileLoaderState();
}

class _LiveVideoTileLoaderState extends State<LiveVideoTileLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0.0, -0.15),
          radius: 0.95,
          colors: [
            Color(0xFF131E38),
            Color(0xFF0F172A),
            Color(0xFF070B14),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulse.value,
                    child: Container(
                      width: widget.compact ? 44 : 58,
                      height: widget.compact ? 44 : 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(
                              alpha: 0.25 + (_pulse.value - 0.92) * 1.2,
                            ),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: SizedBox(
                          width: widget.compact ? 22 : 30,
                          height: widget.compact ? 22 : 30,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.8,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: widget.compact ? 12 : 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: widget.compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Available sizes for [SmartLoader].
enum SmartLoaderSize {
  /// 20x20 - Ideal for buttons, inline badges, and list item trailing icons.
  small(22, 2.4),

  /// 48x48 - Ideal for dialogs, cards, and modal components.
  medium(54, 3.2),

  /// 96x96 - Ideal for full-screen loading, page transitions, and major states.
  large(96, 4.0);

  final double dimension;
  final double strokeWidth;

  const SmartLoaderSize(this.dimension, this.strokeWidth);
}

/// A signature, premium animated loader designed specifically for SmartClass.
///
/// Features:
/// - Smooth multi-layer orbital gradient tracks.
/// - Synchronized breathing emblem / logo core for medium & large sizes.
/// - Crisp, elegant tapered arc with rounded caps for small button spinners.
/// - Optional animated caption text with pulsing ellipsis.
/// - Dark/Light mode adaptive palette with vibrant SmartClass Indigo, Cyan, and Emerald accents.
class SmartLoader extends StatefulWidget {
  /// Predefined size tier (small, medium, large).
  final SmartLoaderSize size;

  /// Custom dimension override. When set, overrides [size.dimension].
  final double? customSize;

  /// Custom stroke width override.
  final double? strokeWidth;

  /// Primary color accent. If null, uses the SmartClass signature brand gradient.
  final Color? color;

  /// Optional message displayed below the loader (typically for medium & large).
  final String? message;

  /// Optional subtitle or helper hint under the message.
  final String? subMessage;

  /// Whether to display the SmartClass emblem in the center (medium & large only).
  final bool showEmblem;

  /// Custom central icon if [showEmblem] is false and size is medium/large.
  final IconData? icon;

  const SmartLoader({
    super.key,
    this.size = SmartLoaderSize.medium,
    this.customSize,
    this.strokeWidth,
    this.color,
    this.message,
    this.subMessage,
    this.showEmblem = true,
    this.icon,
  });

  /// Convenient constructor for compact button / inline spinners.
  const SmartLoader.small({
    super.key,
    this.color,
    this.strokeWidth = 2.4,
    this.customSize = 22,
  })  : size = SmartLoaderSize.small,
        message = null,
        subMessage = null,
        showEmblem = false,
        icon = null;

  /// Convenient constructor for medium card / sheet spinners.
  const SmartLoader.medium({
    super.key,
    this.color,
    this.message,
    this.subMessage,
    this.showEmblem = true,
    this.icon,
  })  : size = SmartLoaderSize.medium,
        customSize = null,
        strokeWidth = null;

  /// Convenient constructor for full-page loading indicators.
  const SmartLoader.large({
    super.key,
    this.color,
    this.message,
    this.subMessage,
    this.showEmblem = true,
    this.icon,
  })  : size = SmartLoaderSize.large,
        customSize = null,
        strokeWidth = null;

  @override
  State<SmartLoader> createState() => _SmartLoaderState();
}

class _SmartLoaderState extends State<SmartLoader>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;
  late final AnimationController _dotsController;

  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseGlow;

  @override
  void initState() {
    super.initState();

    // Smooth continuous spin (1 full revolution in 1100ms)
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    // Gentle breathing pulse for central emblem and glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.93, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _pulseGlow = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Bouncing dots animation
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  double get _dimension => widget.customSize ?? widget.size.dimension;
  double get _stroke => widget.strokeWidth ?? widget.size.strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryAccent = widget.color ??
        (isDark ? const Color(0xFF6366F1) : const Color(0xFF122675));
    final secondaryAccent = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F9D78);

    final isCompact = _dimension <= 32;

    Widget loaderCore;
    if (isCompact) {
      // Small / Button inline spinner
      loaderCore = SizedBox(
        width: _dimension,
        height: _dimension,
        child: AnimatedBuilder(
          animation: _spinController,
          builder: (context, child) {
            return CustomPaint(
              painter: _SmallSpinPainter(
                progress: _spinController.value,
                color: widget.color ?? (isDark ? Colors.white : primaryAccent),
                strokeWidth: _stroke,
              ),
            );
          },
        ),
      );
    } else {
      // Medium / Large orbital branded spinner
      loaderCore = SizedBox(
        width: _dimension,
        height: _dimension,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient breathing glow halo behind the ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: _dimension * 0.75,
                  height: _dimension * 0.75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryAccent.withValues(
                          alpha: _pulseGlow.value * (isDark ? 0.35 : 0.18),
                        ),
                        blurRadius: _dimension * 0.4,
                        spreadRadius: _dimension * 0.08,
                      ),
                      BoxShadow(
                        color: secondaryAccent.withValues(
                          alpha: _pulseGlow.value * (isDark ? 0.25 : 0.12),
                        ),
                        blurRadius: _dimension * 0.25,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),

            // Background static subtle guide ring
            Container(
              width: _dimension,
              height: _dimension,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : primaryAccent.withValues(alpha: 0.08),
                  width: _stroke * 0.8,
                ),
              ),
            ),

            // Rotating gradient orbit ring with comet trailing effect
            AnimatedBuilder(
              animation: _spinController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(_dimension, _dimension),
                  painter: _OrbitalOrbitPainter(
                    angle: _spinController.value * 2 * math.pi,
                    primaryColor: primaryAccent,
                    secondaryColor: secondaryAccent,
                    tertiaryColor: const Color(0xFFF59E0B),
                    strokeWidth: _stroke,
                    isDark: isDark,
                  ),
                );
              },
            ),

            // Counter-rotating outer micro-satellite ring for large loader
            if (_dimension >= 80)
              AnimatedBuilder(
                animation: _spinController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(_dimension * 1.16, _dimension * 1.16),
                    painter: _SatelliteOrbitPainter(
                      angle: -_spinController.value * 2 * math.pi * 0.65,
                      color: secondaryAccent,
                      dotSize: 3.5,
                    ),
                  );
                },
              ),

            // Central SmartClass Emblem or Icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final emblemSize = _dimension * 0.44;
                return Transform.scale(
                  scale: _pulseScale.value,
                  child: Container(
                    width: emblemSize,
                    height: emblemSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF1E2438)
                          : Colors.white,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : primaryAccent.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.06,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(emblemSize * 0.15),
                    child: Center(
                      child: widget.showEmblem
                          ? Image.asset(
                              'assets/images/logo_emblem.png',
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, error, stackTrace) => Icon(
                                widget.icon ?? Icons.school_rounded,
                                size: emblemSize * 0.55,
                                color: primaryAccent,
                              ),
                            )
                          : Icon(
                              widget.icon ?? Icons.auto_awesome_rounded,
                              size: emblemSize * 0.55,
                              color: primaryAccent,
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // Return standalone spinner if no message
    if (widget.message == null && widget.subMessage == null) {
      return loaderCore;
    }

    // Column with typography & animated bouncing dots
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        loaderCore,
        const SizedBox(height: 18),
        if (widget.message != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: _dimension >= 80 ? 15 : 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildAnimatedDots(isDark, primaryAccent),
            ],
          ),
        if (widget.subMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.subMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }

  /// 3 Bouncing dots animation
  Widget _buildAnimatedDots(bool isDark, Color accent) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = ((_dotsController.value * 3) - index).clamp(0.0, 1.0);
            final bounce = math.sin(phase * math.pi);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3.5,
              height: 3.5 + (bounce * 2.5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.6 + (bounce * 0.4)),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Full-screen or Container page loader with polished glassmorphic / centered card presentation.
class SmartPageLoader extends StatelessWidget {
  final String? message;
  final String? subMessage;
  final bool showCard;
  final Color? color;

  const SmartPageLoader({
    super.key,
    this.message = 'Chargement en cours',
    this.subMessage = 'Veuillez patienter quelques instants...',
    this.showCard = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final loader = SmartLoader.large(
      message: message,
      subMessage: subMessage,
      color: color,
    );

    if (!showCard) {
      return Center(child: loader);
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E2438).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFF122675).withValues(alpha: 0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: loader,
        ),
      ),
    );
  }
}

/// Modal barrier overlay with custom animated loader.
class SmartOverlayLoader {
  static OverlayEntry? _currentEntry;

  /// Shows a modal full-screen loader overlay.
  static void show(
    BuildContext context, {
    String? message = 'Traitement en cours',
    String? subMessage = 'Veuillez ne pas fermer cette page.',
  }) {
    if (_currentEntry != null) return;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          ModalBarrier(
            color: Colors.black.withValues(alpha: 0.45),
            dismissible: false,
          ),
          SmartPageLoader(
            message: message,
            subMessage: subMessage,
            showCard: true,
          ),
        ],
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Hides the active modal loader overlay.
  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

// ---------------------------------------------------------------------------
// CUSTOM PAINTERS
// ---------------------------------------------------------------------------

/// Painter for small compact button spinner with high precision and glowing head.
class _SmallSpinPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _SmallSpinPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Faint full circle track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Active spinning arc (covers ~270 degrees with rotation)
    final startAngle = progress * 2 * math.pi;
    const sweepAngle = 1.45 * math.pi;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SmallSpinPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Painter for orbital gradient ring with dynamic comet glow.
class _OrbitalOrbitPainter extends CustomPainter {
  final double angle;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final double strokeWidth;
  final bool isDark;

  _OrbitalOrbitPainter({
    required this.angle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.strokeWidth,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);

    // Sweep gradient shader: Transparent -> Primary -> Secondary -> White/Gleam
    final sweepGradient = SweepGradient(
      colors: [
        primaryColor.withValues(alpha: 0.0),
        primaryColor.withValues(alpha: 0.25),
        secondaryColor,
        tertiaryColor,
        isDark ? Colors.white : primaryColor,
      ],
      stops: const [0.0, 0.35, 0.70, 0.92, 1.0],
    );

    final orbitPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Draw main arc (approx 300 degrees)
    canvas.drawArc(rect, 0, 1.7 * math.pi, false, orbitPaint);

    // Leading glowing head particle
    final headAngle = 1.7 * math.pi;
    final headX = radius * math.cos(headAngle);
    final headY = radius * math.sin(headAngle);

    final glowPaint = Paint()
      ..color = (isDark ? Colors.white : tertiaryColor).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(headX, headY), strokeWidth * 0.95, glowPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbitalOrbitPainter oldDelegate) =>
      oldDelegate.angle != angle ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Micro satellite dot painter orbiting at the periphery.
class _SatelliteOrbitPainter extends CustomPainter {
  final double angle;
  final Color color;
  final double dotSize;

  _SatelliteOrbitPainter({
    required this.angle,
    required this.color,
    required this.dotSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final dotX = center.dx + radius * math.cos(angle);
    final dotY = center.dy + radius * math.sin(angle);

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), dotSize, dotPaint);

    // Minor trailing glow
    final trailPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final trailX = center.dx + radius * math.cos(angle - 0.2);
    final trailY = center.dy + radius * math.sin(angle - 0.2);
    canvas.drawCircle(Offset(trailX, trailY), dotSize * 0.65, trailPaint);
  }

  @override
  bool shouldRepaint(covariant _SatelliteOrbitPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.color != color;
}

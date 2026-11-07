part of '../pages/exam_ai_score_page.dart';
class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  const _ScoreRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 12.0;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Gradient Progress Arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepGradient = SweepGradient(
      colors: [primaryColor, secondaryColor, tertiaryColor],
      startAngle: 0.0,
      endAngle: math.pi * 2,
    );
    final progressPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    const startAngle = -math.pi / 2;
    final sweepAngle = math.pi * 2 * progress;
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

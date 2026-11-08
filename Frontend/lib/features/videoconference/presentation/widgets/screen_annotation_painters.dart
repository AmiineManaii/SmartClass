import 'package:flutter/material.dart';

import '../../domain/entities/screen_annotation.dart';

class AnnotationPainter extends CustomPainter {
  final List<AnnotationStroke> strokes;
  final List<AnnotationPoint> currentPoints;
  final Color currentColor;

  AnnotationPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = Color(stroke.colorValue)
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(
        stroke.points.first.x * size.width,
        stroke.points.first.y * size.height,
      );

      for (int i = 1; i < stroke.points.length; i++) {
        final p = stroke.points[i];
        path.lineTo(p.x * size.width, p.y * size.height);
      }
      canvas.drawPath(path, paint);
    }

    if (currentPoints.length > 1) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(
        currentPoints.first.x * size.width,
        currentPoints.first.y * size.height,
      );
      for (int i = 1; i < currentPoints.length; i++) {
        final p = currentPoints[i];
        path.lineTo(p.x * size.width, p.y * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) => true;
}

class LaserPointerPainter extends CustomPainter {
  final List<LivePointerState> pointers;
  final double pulseValue;

  LaserPointerPainter({
    required this.pointers,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();

    for (final p in pointers) {
      // Fade out pointer if inactive for over 4.5 seconds
      final diff = now.difference(p.updatedAt).inMilliseconds;
      if (diff > 4500) continue;

      final px = p.x * size.width;
      final py = p.y * size.height;

      // Expanding glowing outer ring
      final haloPaint = Paint()
        ..color = p.color
            .withValues(alpha: (0.35 * (1.0 - pulseValue * 0.4)).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), 12.0 + (pulseValue * 8.0), haloPaint);

      // Core laser dot
      final corePaint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), 6.5, corePaint);

      final centerWhite = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), 2.5, centerWhite);

      // Name label tag
      final textSpan = TextSpan(
        text: '● ${p.name}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.transparent,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelRect = Rect.fromLTWH(
        px - textPainter.width / 2 - 5,
        py - 24,
        textPainter.width + 10,
        16,
      );
      final labelBg = Paint()
        ..color = const Color(0xFF0F172A).withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(8)),
        labelBg,
      );
      textPainter.paint(canvas, Offset(px - textPainter.width / 2, py - 23));
    }
  }

  @override
  bool shouldRepaint(covariant LaserPointerPainter oldDelegate) => true;
}


import 'package:flutter/material.dart';

/// Normalized 2D point (0.0 to 1.0) relative to the screen dimensions
class AnnotationPoint {
  final double x;
  final double y;

  const AnnotationPoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory AnnotationPoint.fromJson(Map<String, dynamic> json) =>
      AnnotationPoint((json['x'] as num).toDouble(), (json['y'] as num).toDouble());
}

/// A freehand drawing stroke made on top of a shared screen
class AnnotationStroke {
  final String id;
  final String authorIdentity;
  final String authorName;
  final int colorValue;
  final double strokeWidth;
  final List<AnnotationPoint> points;

  const AnnotationStroke({
    required this.id,
    required this.authorIdentity,
    required this.authorName,
    required this.colorValue,
    required this.strokeWidth,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorIdentity': authorIdentity,
        'authorName': authorName,
        'color': colorValue,
        'width': strokeWidth,
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory AnnotationStroke.fromJson(Map<String, dynamic> json) {
    return AnnotationStroke(
      id: json['id'] as String? ?? UniqueKey().toString(),
      authorIdentity: json['authorIdentity'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Participant',
      colorValue: json['color'] as int? ?? 0xFFEF4444,
      strokeWidth: (json['width'] as num?)?.toDouble() ?? 3.0,
      points: (json['points'] as List? ?? [])
          .map((p) => AnnotationPoint.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
    );
  }
}

/// Real-time live laser pointer position of a participant
class LivePointerState {
  final String identity;
  final String name;
  final double x; // normalized 0.0 to 1.0
  final double y; // normalized 0.0 to 1.0
  final Color color;
  final DateTime updatedAt;

  const LivePointerState({
    required this.identity,
    required this.name,
    required this.x,
    required this.y,
    required this.color,
    required this.updatedAt,
  });

  LivePointerState copyWith({
    double? x,
    double? y,
    DateTime? updatedAt,
  }) {
    return LivePointerState(
      identity: identity,
      name: name,
      x: x ?? this.x,
      y: y ?? this.y,
      color: color,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Annotation tool mode
enum AnnotationToolMode {
  pointer,
  pen,
}

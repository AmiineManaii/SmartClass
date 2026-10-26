import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/live_room_controller.dart';
import '../../domain/entities/live_participant.dart';
import '../../domain/entities/screen_annotation.dart';

/// Overlay layered directly on top of the shared screen video stream.
/// Supports real-time collaborative laser pointer, live drawing co-annotation,
/// and teacher "Donner la main" permission controls.
class ScreenAnnotationOverlay extends ConsumerStatefulWidget {
  final LiveParticipant presenter;
  final BoxConstraints constraints;

  const ScreenAnnotationOverlay({
    super.key,
    required this.presenter,
    required this.constraints,
  });

  @override
  ConsumerState<ScreenAnnotationOverlay> createState() =>
      _ScreenAnnotationOverlayState();
}

class _ScreenAnnotationOverlayState extends ConsumerState<ScreenAnnotationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _pointerThrottleTimer;
  Offset? _pendingPointerOffset;
  List<AnnotationPoint> _currentStrokePoints = [];
  bool _isToolbarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pointerThrottleTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPointerMove(Offset localPos, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final normX = (localPos.dx / size.width).clamp(0.0, 1.0);
    final normY = (localPos.dy / size.height).clamp(0.0, 1.0);

    _pendingPointerOffset = Offset(normX, normY);
    if (_pointerThrottleTimer == null || !_pointerThrottleTimer!.isActive) {
      _pointerThrottleTimer = Timer(const Duration(milliseconds: 40), () {
        if (_pendingPointerOffset != null && mounted) {
          ref
              .read(liveRoomControllerProvider.notifier)
              .sendPointerMove(_pendingPointerOffset!.dx, _pendingPointerOffset!.dy);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(liveRoomControllerProvider);
    final controller = ref.read(liveRoomControllerProvider.notifier);
    final canAnnotate = roomState.canAnnotate;
    final isAnnotationActive = roomState.isAnnotationActive;
    final isHost = roomState.isHost;

    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);

        return Stack(
          children: [
            // Gesture Detector layer when annotation is enabled
            if (isAnnotationActive && canAnnotate)
              Positioned.fill(
                child: MouseRegion(
                  cursor: roomState.currentToolMode == AnnotationToolMode.pointer
                      ? SystemMouseCursors.precise
                      : SystemMouseCursors.basic,
                  onHover: (event) {
                    if (roomState.currentToolMode == AnnotationToolMode.pointer) {
                      _onPointerMove(event.localPosition, size);
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: (details) {
                      if (roomState.currentToolMode == AnnotationToolMode.pen) {
                        final normX = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
                        final normY = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
                        setState(() {
                          _currentStrokePoints = [AnnotationPoint(normX, normY)];
                        });
                      } else {
                        _onPointerMove(details.localPosition, size);
                      }
                    },
                    onPanUpdate: (details) {
                      if (roomState.currentToolMode == AnnotationToolMode.pen) {
                        final normX = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
                        final normY = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
                        setState(() {
                          _currentStrokePoints.add(AnnotationPoint(normX, normY));
                        });
                      } else {
                        _onPointerMove(details.localPosition, size);
                      }
                    },
                    onPanEnd: (_) {
                      if (roomState.currentToolMode == AnnotationToolMode.pen &&
                          _currentStrokePoints.length > 1) {
                        final stroke = AnnotationStroke(
                          id: UniqueKey().toString(),
                          authorIdentity: roomState.localParticipant?.identity ?? 'local',
                          authorName: roomState.localParticipant?.name ?? 'Vous',
                          colorValue: roomState.currentAnnotationColor,
                          strokeWidth: 3.5,
                          points: List.from(_currentStrokePoints),
                        );
                        controller.addAnnotationStroke(stroke);
                        setState(() {
                          _currentStrokePoints = [];
                        });
                      }
                    },
                  ),
                ),
              ),

            // Completed drawings & in-progress drawing
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _AnnotationPainter(
                    strokes: roomState.annotationStrokes,
                    currentPoints: _currentStrokePoints,
                    currentColor: Color(roomState.currentAnnotationColor),
                  ),
                ),
              ),
            ),

            // Live Laser Pointers
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _LaserPointerPainter(
                        pointers: roomState.livePointers.values.toList(),
                        pulseValue: _pulseController.value,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Floating Annotation Control Dock
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Center(
                child: _buildAnnotationToolbar(
                  context,
                  roomState,
                  controller,
                  isHost,
                  canAnnotate,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnnotationToolbar(
    BuildContext context,
    LiveRoomState roomState,
    LiveRoomController controller,
    bool isHost,
    bool canAnnotate,
  ) {
    if (_isToolbarCollapsed) {
      return InkWell(
        onTap: () => setState(() => _isToolbarCollapsed = false),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF38BDF8)),
              SizedBox(width: 6),
              Text(
                'Outils d\'annotation',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode Indicator Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: canAnnotate
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : const Color(0xFF64748B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: canAnnotate ? const Color(0xFF10B981) : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  canAnnotate
                      ? (isHost ? 'Professeur' : 'Contrôle actif')
                      : 'Spectateur',
                  style: TextStyle(
                    color: canAnnotate ? const Color(0xFF34D399) : Colors.white60,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          if (canAnnotate) ...[
            // Laser Pointer Tool
            _buildToolIcon(
              icon: Icons.adjust_rounded,
              isSelected: roomState.currentToolMode == AnnotationToolMode.pointer,
              tooltip: 'Pointeur laser direct',
              onTap: () {
                if (!roomState.isAnnotationActive) controller.toggleAnnotationMode();
                controller.setAnnotationToolMode(AnnotationToolMode.pointer);
              },
            ),
            const SizedBox(width: 4),

            // Pen Tool
            _buildToolIcon(
              icon: Icons.draw_rounded,
              isSelected: roomState.currentToolMode == AnnotationToolMode.pen,
              tooltip: 'Crayon d\'annotation',
              onTap: () {
                if (!roomState.isAnnotationActive) controller.toggleAnnotationMode();
                controller.setAnnotationToolMode(AnnotationToolMode.pen);
              },
            ),
            const SizedBox(width: 8),

            // Color dots
            _buildColorDot(const Color(0xFFEF4444), roomState.currentAnnotationColor, controller),
            const SizedBox(width: 4),
            _buildColorDot(const Color(0xFF06B6D4), roomState.currentAnnotationColor, controller),
            const SizedBox(width: 4),
            _buildColorDot(const Color(0xFFFACC15), roomState.currentAnnotationColor, controller),
            const SizedBox(width: 8),

            // Clear strokes
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.white70),
              tooltip: 'Effacer les annotations',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: controller.clearAnnotations,
            ),
            const SizedBox(width: 6),
          ],

          // Host "Donner la main" Control Action
          if (isHost) ...[
            PopupMenuButton<String>(
              tooltip: 'Donner la main à un participant',
              color: const Color(0xFF1E2638),
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roomState.activeControllerIdentity != null
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                      : const Color(0xFF2563EB).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: roomState.activeControllerIdentity != null
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF38BDF8),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      roomState.activeControllerIdentity != null
                          ? Icons.front_hand_rounded
                          : Icons.handshake_rounded,
                      size: 14,
                      color: roomState.activeControllerIdentity != null
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      roomState.activeControllerName != null
                          ? roomState.activeControllerName!
                          : 'Donner la main',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              onSelected: (val) {
                if (val == '__revoke__') {
                  controller.giveAnnotationControl(null);
                } else if (val == '__all__') {
                  controller.giveAnnotationControl('all', targetName: 'Tous les élèves');
                } else {
                  final p = roomState.remoteParticipants[val];
                  controller.giveAnnotationControl(val, targetName: p?.name ?? val);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: '__revoke__',
                  child: Row(
                    children: [
                      Icon(Icons.block_rounded, size: 16, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Reprendre la main (Professeur seul)', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: '__all__',
                  child: Row(
                    children: [
                      Icon(Icons.groups_rounded, size: 16, color: Color(0xFF38BDF8)),
                      SizedBox(width: 8),
                      Text('Autoriser toute la classe', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                for (final p in roomState.remoteParticipants.values)
                  PopupMenuItem(
                    value: p.identity,
                    child: Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 16, color: Colors.white70),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Donner à ${p.name}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
          ],

          // Collapse Button
          InkWell(
            onTap: () => setState(() => _isToolbarCollapsed = true),
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_fullscreen_rounded, size: 15, color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolIcon({
    required IconData icon,
    required bool isSelected,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color, int selectedValue, LiveRoomController controller) {
    final isSelected = color.toARGB32() == selectedValue;
    return InkWell(
      onTap: () => controller.setAnnotationColor(color.toARGB32()),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  final List<AnnotationStroke> strokes;
  final List<AnnotationPoint> currentPoints;
  final Color currentColor;

  _AnnotationPainter({
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
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}

class _LaserPointerPainter extends CustomPainter {
  final List<LivePointerState> pointers;
  final double pulseValue;

  _LaserPointerPainter({
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
        ..color = p.color.withValues(alpha: (0.35 * (1.0 - pulseValue * 0.4)).clamp(0.0, 1.0))
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
      canvas.drawRRect(RRect.fromRectAndRadius(labelRect, const Radius.circular(8)), labelBg);
      textPainter.paint(canvas, Offset(px - textPainter.width / 2, py - 23));
    }
  }

  @override
  bool shouldRepaint(covariant _LaserPointerPainter oldDelegate) => true;
}

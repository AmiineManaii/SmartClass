import 'package:flutter/material.dart';

/// Display-only OTP boxes driven by an external value (e.g. custom keypad).
/// States per box: filled (digit + underline), active next (pulsing cursor),
/// empty (dot). Follows DESIGN.md radius 12 and surface tones.
class OtpDisplayBoxes extends StatelessWidget {
  final List<String> digits;
  final int length;

  const OtpDisplayBoxes({required this.digits, this.length = 6, super.key})
      : assert(digits.length <= 6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final values = List<String>.generate(
      length,
      (i) => i < digits.length ? digits[i] : '',
    );
    final activeIndex = values.indexWhere((d) => d.isEmpty);

    return Row(
      children: List.generate(length, (i) {
        final digit = values[i];
        final isFilled = digit.isNotEmpty;
        final isActive = i == activeIndex;

        late final Color background;
        late final Widget content;
        if (isFilled) {
          background = colorScheme.surfaceContainerLow ?? colorScheme.surfaceContainer;
          content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                digit,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ],
          );
        } else if (isActive) {
          background = colorScheme.surfaceContainerHigh;
          content = _PulsingCursor(color: colorScheme.primary);
        } else {
          background = colorScheme.surfaceContainerLowest ?? colorScheme.surface;
          content = Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colorScheme.surfaceDim,
              shape: BoxShape.circle,
            ),
          );
        }

        return Expanded(
          child: Container(
            height: 56,
            margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.04),
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: content,
          ),
        );
      }),
    );
  }
}

class _PulsingCursor extends StatefulWidget {
  final Color color;

  const _PulsingCursor({required this.color});

  @override
  State<_PulsingCursor> createState() => _PulsingCursorState();
}

class _PulsingCursorState extends State<_PulsingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(9999),
        ),
      ),
    );
  }
}

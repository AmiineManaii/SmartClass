import 'package:flutter/material.dart';

/// iOS-style numeric keypad matching the email-verification mockup.
/// Sub-labels follow the standard telephone layout (identical in FR/EN).
class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const NumericKeypad({
    required this.onDigit,
    required this.onBackspace,
    super.key,
  });

  static const _keys = [
    ('1', ''),
    ('2', 'ABC'),
    ('3', 'DEF'),
    ('4', 'GHI'),
    ('5', 'JKL'),
    ('6', 'MNO'),
    ('7', 'PQRS'),
    ('8', 'TUV'),
    ('9', 'WXYZ'),
    ('', ''),
    ('0', '+'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget digitKey(String digit, String sub) {
      if (digit.isEmpty) return const SizedBox(height: 48);
      return _KeyButton(
        onTap: () => onDigit(digit),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              digit,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                sub,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.08,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.6,
      children: [
        ..._keys.map((k) => digitKey(k.$1, k.$2)),
        _KeyButton(
          onTap: onBackspace,
          background: colorScheme.surfaceContainer,
          child: Icon(
            Icons.backspace_outlined,
            size: 22,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? background;

  const _KeyButton({
    required this.child,
    required this.onTap,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: background ?? colorScheme.surfaceContainerLowest ?? colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
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
          child: child,
        ),
      ),
    );
  }
}

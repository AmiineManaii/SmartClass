import 'package:flutter/material.dart';

/// Avatar with optional online dot, or initials fallback circle.
class AdminPersonAvatar extends StatelessWidget {
  final String? initials;
  final bool showOnlineDot;
  final double size;

  const AdminPersonAvatar({
    this.initials,
    this.showOnlineDot = false,
    this.size = 48,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.secondaryFixed,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: initials == null
              ? Icon(Icons.person_rounded, size: size * 0.55, color: colorScheme.onSecondaryFixed)
              : Text(
                  initials!,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSecondaryFixed,
                        fontWeight: FontWeight.w700,
                      ),
                ),
        ),
        if (showOnlineDot)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: colorScheme.tertiaryFixed,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surfaceContainerLowest,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

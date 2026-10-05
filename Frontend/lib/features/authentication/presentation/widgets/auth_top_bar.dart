import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth_logo.dart';
import 'stepper_dots.dart';

class AuthTopBar extends StatelessWidget {
  final int? step;
  final Widget? trailing;
  final VoidCallback? onBack;

  const AuthTopBar({this.step, this.trailing, this.onBack, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow ?? colorScheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: colorScheme.primary,
              onPressed: onBack ?? () => context.pop(),
            ),
          ),
          const SmartClassPill(),
          if (step != null)
            StepperDots(step: step!)
          else if (trailing != null)
            trailing!
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

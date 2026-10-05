import 'package:flutter/material.dart';

class StepperDots extends StatelessWidget {
  final int step;
  final int total;

  const StepperDots({required this.step, this.total = 3, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (index) {
          final isActive = index == step - 1;
          return Container(
            width: isActive ? 16 : 6,
            height: 6,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 6),
            decoration: BoxDecoration(
              color: isActive ? colorScheme.primaryContainer : colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(9999),
            ),
          );
        }),
      ),
    );
  }
}

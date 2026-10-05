import 'package:flutter/material.dart';

class AuthScreenScaffold extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AuthScreenScaffold({required this.child, this.maxWidth = 480, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth >= 600 ? 32 : 20,
                vertical: 8,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

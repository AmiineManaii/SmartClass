import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({this.size = 20, super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF4285F4), Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        'G',
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

class MicrosoftLogo extends StatelessWidget {
  final double size;

  const MicrosoftLogo({this.size = 20, super.key});

  static const _red = Color(0xFFF25022);
  static const _green = Color(0xFF7FBA00);
  static const _blue = Color(0xFF00A4EF);
  static const _yellow = Color(0xFFFFB900);

  @override
  Widget build(BuildContext context) {
    final cell = (size - 2) / 2;
    Widget square(Color color) => Container(width: cell, height: cell, color: color);

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        children: [
          Row(
            children: [square(_red), const SizedBox(width: 2), square(_green)],
          ),
          const SizedBox(height: 2),
          Row(
            children: [square(_blue), const SizedBox(width: 2), square(_yellow)],
          ),
        ],
      ),
    );
  }
}

class SocialAuthButton extends StatelessWidget {
  final Widget logo;
  final String label;
  final VoidCallback? onPressed;

  const SocialAuthButton({
    required this.logo,
    required this.label,
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Material(
        color: colorScheme.surfaceContainerLowest ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 50,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                logo,
                const SizedBox(width: 10),
                Text(label, style: theme.textTheme.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SocialAuthRow extends StatelessWidget {
  final VoidCallback? onGoogle;
  final VoidCallback? onMicrosoft;

  const SocialAuthRow({this.onGoogle, this.onMicrosoft, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SocialAuthButton(logo: const GoogleLogo(), label: 'Google', onPressed: onGoogle),
        const SizedBox(width: 12),
        SocialAuthButton(logo: const MicrosoftLogo(), label: 'Microsoft', onPressed: onMicrosoft),
      ],
    );
  }
}

class AuthDivider extends StatelessWidget {
  final String labelKey;

  const AuthDivider({required this.labelKey, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(child: Container(height: 1, color: colorScheme.surfaceContainerHighest)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.tr(labelKey),
            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(child: Container(height: 1, color: colorScheme.surfaceContainerHighest)),
      ],
    );
  }
}

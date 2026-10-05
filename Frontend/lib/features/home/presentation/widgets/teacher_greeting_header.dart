import 'package:flutter/material.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/localization/app_localizations.dart';

class TeacherAvatar extends StatelessWidget {
  final double size;

  const TeacherAvatar({this.size = 56, super.key});

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
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerHigh,
            border: Border.all(
              color: colorScheme.surfaceContainerLowest,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/teacher_avatar.png',
              fit: BoxFit.cover,
              errorBuilder: (context, _, _) => Icon(
                Icons.person,
                size: size * 0.55,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
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
            child: Center(
              child: Container(
                width: size * 0.13,
                height: size * 0.13,
                decoration: BoxDecoration(
                  color: colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TeacherGreetingHeader extends StatelessWidget {
  final AuthState? user;

  const TeacherGreetingHeader({this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = user?.displayName;
    final displayName = (name == null || name.isEmpty) ? 'Prof. Amine' : 'Prof. $name';

    return Row(
      children: [
        const TeacherAvatar(size: 56),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('greeting_hello'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: theme.textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      context.tr('teacher_badge'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _SquareIconButton(
          icon: Icons.calendar_today_outlined,
          tooltip: context.tr('calendar'),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        _SquareIconButton(
          icon: Icons.notifications_outlined,
          tooltip: context.tr('notifications'),
          showDot: true,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool showDot;
  final VoidCallback? onPressed;

  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    this.showDot = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                offset: const Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: 20),
            color: colorScheme.onSurfaceVariant,
            tooltip: tooltip,
            onPressed: onPressed,
          ),
        ),
        if (showDot)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colorScheme.error,
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

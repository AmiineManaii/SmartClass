import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/localization/app_localizations.dart';

/// Shown when the session has no persisted role (legacy accounts created
/// before `PATCH /users/me/role` was wired). Forces the user through
/// role-selection instead of defaulting to the student dashboard.
class MissingRoleView extends ConsumerWidget {
  final AsyncValue<AuthState> authState;

  const MissingRoleView({super.key, required this.authState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('home'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                context.tr('who_are_you'),
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/role-selection'),
                child: Text(context.tr('continue_action')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/course_study_provider.dart';
import '../../domain/entities/course_study.dart';

/// Localized message for a study action failure (API error → FR/EN map).
String courseStudyErrorMessage(BuildContext context, Object error) {
  final Failure? failure = error is ApiException
      ? apiExceptionToFailure(error)
      : error is Failure
      ? error
      : null;
  if (failure == null) {
    return context.tr('course_study_generate_failed');
  }
  final l10n = failureL10n(failure);
  return context.tr(l10n.key, args: l10n.args);
}

/// Loads the study workspace once for the three study tabs.
///
/// Keeps loading/error handling identical across summary, flashcards and
/// tutor tabs instead of duplicating the async branches.
class CourseStudyAsyncGate extends ConsumerWidget {
  const CourseStudyAsyncGate({
    super.key,
    required this.courseId,
    required this.builder,
  });

  final String courseId;
  final Widget Function(BuildContext, CourseStudyWorkspace) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(courseStudyWorkspaceProvider(courseId));
    return workspace.when(
      loading: () => Center(
        child: SmartLoader.medium(message: context.tr('course_study_loading')),
      ),
      error: (error, _) => _StudyError(
        message: context.tr('course_study_workspace_error'),
        onRetry: () => ref.invalidate(courseStudyWorkspaceProvider(courseId)),
      ),
      data: (data) => builder(context, data),
    );
  }
}

class _StudyError extends StatelessWidget {
  const _StudyError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill shown when the local model was offline and the backend
/// returned a deterministic extractive artifact instead.
class CourseStudyFallbackBadge extends StatelessWidget {
  const CourseStudyFallbackBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.offline_bolt_outlined,
            size: 14,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              context.tr('course_study_fallback_notice'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/course_generation_job_provider.dart';
import '../../application/providers/course_plan_job_provider.dart';

/// Floating global banner / pill shown across all app screens when an AI plan
/// or course is generating in the background. Displays live elapsed seconds
/// (1s, 2s, 3s...) and allows one-tap return to the course creator / editor.
class GlobalAiPlanProgressBar extends ConsumerWidget {
  const GlobalAiPlanProgressBar({super.key});

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    if (m > 0) {
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${s}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planJob = ref.watch(coursePlanJobProvider);
    final genJob = ref.watch(courseGenerationJobProvider);

    // Determine current route to avoid covering the creator page when already open
    final router = ref.watch(routerProvider);
    final location =
        router.routeInformationProvider.value.uri.path;
    final onCreatorPage = location == '/courses/ai-create';

    final hasActivePlanJob =
        planJob.status == CoursePlanJobStatus.running ||
        (planJob.status == CoursePlanJobStatus.completed &&
            !planJob.dismissed &&
            !onCreatorPage);

    final hasActiveGenJob =
        genJob.status == GenerationJobStatus.running ||
        (genJob.status == GenerationJobStatus.done && !onCreatorPage);

    if (!hasActivePlanJob && !hasActiveGenJob) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 768;

    // Detect if we are on a shell route with bottom navigation bar (needs bottom offset on mobile)
    final isShellRoute = [
      '/home',
      '/courses',
      '/groups',
      '/exams',
      '/videoconference',
      '/collaboration',
      '/settings',
      '/admin'
    ].any((prefix) => location.startsWith(prefix));

    final bottomPadding = isDesktop ? 24.0 : (isShellRoute ? 76.0 : 16.0);

    // Priority 1: Plan job
    if (hasActivePlanJob) {
      final isRunning = planJob.status == CoursePlanJobStatus.running;
      final isCompleted = planJob.status == CoursePlanJobStatus.completed;

      return Positioned(
        left: isDesktop ? null : 16,
        right: isDesktop ? 24 : 16,
        bottom: bottomPadding,
        width: isDesktop ? 440 : null,
        child: Material(
          color: Colors.transparent,
          elevation: 8,
          shadowColor: colorScheme.primary.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () {
              ref.read(routerProvider).push('/courses/ai-create');
            },
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCompleted
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCompleted
                      ? Colors.green.shade600
                      : colorScheme.primary.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.15)
                        : colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Animated Icon / Badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.shade50
                          : colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isRunning
                          ? const SmartLoader.small(customSize: 18)
                          : Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green.shade700,
                              size: 22,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Texts & Live Timer
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isRunning
                                    ? context.tr('ai_plan_generating_title')
                                    : context.tr('ai_plan_ready_title'),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isCompleted
                                      ? Colors.green.shade800
                                      : colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.green.shade100
                                    : colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 11,
                                    color: isCompleted
                                        ? Colors.green.shade800
                                        : colorScheme.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    _formatDuration(planJob.elapsedSec),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isCompleted
                                          ? Colors.green.shade800
                                          : colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCompleted
                              ? (planJob.outline?.title.isNotEmpty == true
                                  ? planJob.outline!.title
                                  : context.tr('ai_plan_ready_subtitle'))
                              : (planJob.subject.isNotEmpty
                                  ? planJob.subject
                                  : 'Création du plan en cours...'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Action Buttons
                  if (isCompleted) ...[
                    FilledButton(
                      onPressed: () {
                        ref.read(routerProvider).push('/courses/ai-create');
                      },
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        backgroundColor: Colors.green.shade700,
                      ),
                      child: Text(
                        context.tr('ai_plan_open'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        ref.read(coursePlanJobProvider.notifier).dismiss();
                      },
                    ),
                  ] else ...[
                    FilledButton.tonal(
                      onPressed: () {
                        ref.read(routerProvider).push('/courses/ai-create');
                      },
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('ai_plan_open'),
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_rounded, size: 12),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Priority 2: Full Course Generation job
    final isGenRunning = genJob.status == GenerationJobStatus.running;
    return Positioned(
      left: isDesktop ? null : 16,
      right: isDesktop ? 24 : 16,
      bottom: bottomPadding,
      width: isDesktop ? 440 : null,
      child: Material(
        color: Colors.transparent,
        elevation: 8,
        shadowColor: colorScheme.primary.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            ref.read(routerProvider).push('/courses/ai-create');
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isGenRunning
                        ? const SmartLoader.small(customSize: 18)
                        : const Icon(Icons.check_circle_rounded, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isGenRunning
                                ? 'Rédaction IA en cours'
                                : 'Cours IA rédigé !',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatDuration(genJob.elapsedSec),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isGenRunning
                            ? '${genJob.chars} caractères rédigés'
                            : 'Appuyez pour voir le cours',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    ref.read(routerProvider).push('/courses/ai-create');
                  },
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  child: const Text('Ouvrir', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

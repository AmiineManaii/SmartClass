import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/course_generation_job_provider.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../../../core/localization/app_localizations.dart';

/// Bannière fine affichée dans "Mes cours" pendant qu'une génération
/// d'IA tourne en arrière-plan (lancée depuis la page de création).
class RunningJobBanner extends ConsumerWidget {
  final GenerationJobState job;

  const RunningJobBanner({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final minutes = job.elapsedSec ~/ 60;
    final seconds = (job.elapsedSec % 60).toString().padLeft(2, '0');
    final tokens = job.chars ~/ 4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SmartLoader.small(
            customSize: 18,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${context.tr('generation_running')} $tokens tokens • $minutes:$seconds',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(courseGenerationJobProvider.notifier).cancel(),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Text(context.tr('cancel')),
          ),
        ],
      ),
    );
  }
}

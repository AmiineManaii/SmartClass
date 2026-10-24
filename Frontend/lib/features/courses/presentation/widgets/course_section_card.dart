import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../courses/domain/entities/course_section.dart';

/// Carte d'une section de cours dans le panneau de construction.
///
/// Affiche : numéro, titre, statut (À générer / À valider / Validée),
/// description, points clés, et les actions :
/// - Générer (si PENDING)
/// - Régénérer (si GENERATED ou VALIDATED avec confirmation)
/// - Valider (si GENERATED)
/// - Chercher des images (toujours disponible)
class CourseSectionCard extends ConsumerWidget {
  final int sectionNumber;
  final CourseSectionEntry section;
  final VoidCallback onGenerate;
  final VoidCallback onRegenerate;
  final VoidCallback onValidate;
  final VoidCallback onImageSearch;

  const CourseSectionCard({
    super.key,
    required this.sectionNumber,
    required this.section,
    required this.onGenerate,
    required this.onRegenerate,
    required this.onValidate,
    required this.onImageSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusColor = switch (section.status) {
      CourseSectionStatus.pending => colorScheme.onSurfaceVariant,
      CourseSectionStatus.generated => colorScheme.primary,
      CourseSectionStatus.validated => colorScheme.tertiary,
    };

    final statusLabel = switch (section.status) {
      CourseSectionStatus.pending => context.tr('ai_build_status_pending'),
      CourseSectionStatus.generated => context.tr('ai_build_status_generated'),
      CourseSectionStatus.validated => context.tr('ai_build_status_validated'),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: section.status == CourseSectionStatus.validated
              ? colorScheme.tertiary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête : numéro + titre + statut
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr('ai_build_section_num', args: {'n': sectionNumber.toString()}),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        section.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                if (section.description.isNotEmpty) ...[
                  Text(
                    section.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // Points clés
                if (section.keyTopics.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: section.keyTopics
                        .take(4)
                        .map((topic) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                topic,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 10.5,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Actions
                Row(
                  children: [
                    // Générer (PENDING) ou Régénérer (GENERATED/VALIDATED)
                    if (section.status == CourseSectionStatus.pending)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onGenerate,
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: Text(context.tr('ai_build_generate')),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onRegenerate,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text(context.tr('ai_build_regenerate')),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (section.status == CourseSectionStatus.generated)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onValidate,
                            icon: const Icon(Icons.verified_outlined, size: 16),
                            label: Text(context.tr('ai_build_validate')),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(width: 8),
                    // Images
                    IconButton.outlined(
                      onPressed: onImageSearch,
                      icon: const Icon(Icons.image_search_rounded, size: 18),
                      tooltip: 'Chercher des images',
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

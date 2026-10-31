import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/course_section.dart';

/// Dialogue de recherche d'images web pour une section.
///
/// Affiche jusqu'à 5 candidats retournés par `POST /ai/courses/sections/image/search`.
/// Si aucun résultat, propose de régénérer ou de préciser la requête.
class CourseImageSearchDialog extends ConsumerWidget {
  final List<SectionImageCandidate> candidates;
  final Future<void> Function(String imageUrl, String? caption) onInsert;

  const CourseImageSearchDialog({
    super.key,
    required this.candidates,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(context.tr('ai_image_choose_title')),
      content: SizedBox(
        width: 400,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (candidates.isEmpty) ...[
                  Text(
                    context.tr('ai_image_search_empty'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.tr('ai_image_retry_regenerate')),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '${context.tr('ai_image_search_title')} (${candidates.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...candidates.map((candidate) => _ImageCandidateTile(
                    candidate: candidate,
                    onInsert: () => onInsert(candidate.url, candidate.caption),
                  )),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
      ],
    );
  }
}

/// Tuile d'un candidat d'image avec aperçu au-dessus, titre/description en dessous, puis bouton d'insertion.
class _ImageCandidateTile extends StatelessWidget {
  final SectionImageCandidate candidate;
  final VoidCallback onInsert;

  const _ImageCandidateTile({
    required this.candidate,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image en haut
          Image.network(
            candidate.url,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 140,
              color: colorScheme.surfaceContainerLow,
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image,
                color: colorScheme.onSurfaceVariant,
                size: 32,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Text(
                  candidate.title.isNotEmpty ? candidate.title : 'Image',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Description / Caption
                if (candidate.caption.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    candidate.caption,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (candidate.source.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    candidate.source,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 9.5,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Bouton Insérer en dessous
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onInsert,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: const Text('Insérer'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

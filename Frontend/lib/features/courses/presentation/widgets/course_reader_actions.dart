import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/generated_course.dart';

/// Barre d'actions pour l'enseignant/admin (Valider, Dépublier, Supprimer, Raffiner IA).
///
/// Affichée uniquement si l'utilisateur est l'auteur du cours ou admin.
class CourseReaderActions extends ConsumerWidget {
  final GeneratedCourse course;
  final VoidCallback onRefine;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final VoidCallback onDelete;

  const CourseReaderActions({
    super.key,
    required this.course,
    required this.onRefine,
    required this.onPublish,
    required this.onUnpublish,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          // Bouton raffinage IA (toujours disponible)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRefine,
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: Text(context.tr('ai_refine_btn')),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (course.isDraft) ...[
            const SizedBox(height: 8),
            // Publier (si brouillon)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPublish,
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: Text(context.tr('validate_course')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            // Dépublier (si publié)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUnpublish,
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                label: Text(context.tr('unpublish_course')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Supprimer
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
              label: Text(
                context.tr('delete'),
                style: TextStyle(color: colorScheme.error),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

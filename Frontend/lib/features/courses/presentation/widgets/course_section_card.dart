import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../courses/domain/entities/course_section.dart';
import 'markdown_course_view.dart';

/// Carte d'une section de cours dans le panneau de construction.
///
/// Affiche : numéro, titre, statut (À générer / À valider / Validée),
/// description, points clés, bannière shimmer streaming, accordéon du contenu,
/// et les actions (Générer, Régénérer, Valider, Images).
class CourseSectionCard extends ConsumerWidget {
  final int sectionNumber;
  final CourseSectionEntry section;
  final VoidCallback onGenerate;
  final VoidCallback onRegenerate;
  final VoidCallback onValidate;
  final VoidCallback onImageSearch;
  final bool isStreaming;
  final String? streamingPhase;
  final String? streamingText;
  final VoidCallback? onCancelStream;

  const CourseSectionCard({
    super.key,
    required this.sectionNumber,
    required this.section,
    required this.onGenerate,
    required this.onRegenerate,
    required this.onValidate,
    required this.onImageSearch,
    this.isStreaming = false,
    this.streamingPhase,
    this.streamingText,
    this.onCancelStream,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusColor = isStreaming
        ? colorScheme.primary
        : switch (section.status) {
            CourseSectionStatus.pending => colorScheme.onSurfaceVariant,
            CourseSectionStatus.generated => colorScheme.primary,
            CourseSectionStatus.validated => colorScheme.tertiary,
          };

    final statusLabel = isStreaming
        ? 'EN COURS...'
        : switch (section.status) {
            CourseSectionStatus.pending => context.tr('ai_build_status_pending'),
            CourseSectionStatus.generated => context.tr('ai_build_status_generated'),
            CourseSectionStatus.validated => context.tr('ai_build_status_validated'),
          };

    final hasContent = section.content != null && section.content!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isStreaming
            ? colorScheme.primaryContainer.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStreaming
              ? colorScheme.primary
              : (section.status == CourseSectionStatus.validated
                  ? colorScheme.tertiary.withValues(alpha: 0.4)
                  : colorScheme.outlineVariant.withValues(alpha: 0.3)),
          width: isStreaming ? 2.0 : 1.0,
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

                // Bannière de génération en streaming avec Shimmer animé
                if (isStreaming) ...[
                  _ShimmerStreamingBanner(
                    phase: streamingPhase,
                    text: streamingText,
                    onCancel: onCancelStream,
                  ),
                  const SizedBox(height: 12),
                ],

                // Contenu généré (Accordéon dépliable)
                if (hasContent && !isStreaming) ...[
                  Material(
                    color: Colors.transparent,
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
                        leading: Icon(
                          Icons.description_outlined,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        title: Text(
                          'Voir le contenu généré',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: MarkdownCourseView(data: section.content!),
                          ),
                        ],
                      ),
                    ),
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
                          onPressed: isStreaming ? null : onGenerate,
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
                          onPressed: isStreaming ? null : onRegenerate,
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
                            onPressed: isStreaming ? null : onValidate,
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
                      onPressed: isStreaming ? null : onImageSearch,
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

/// Shimmer élégant animé pour l'état de génération
class _ShimmerStreamingBanner extends StatefulWidget {
  final String? phase;
  final String? text;
  final VoidCallback? onCancel;

  const _ShimmerStreamingBanner({
    this.phase,
    this.text,
    this.onCancel,
  });

  @override
  State<_ShimmerStreamingBanner> createState() => _ShimmerStreamingBannerState();
}

class _ShimmerStreamingBannerState extends State<_ShimmerStreamingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String phaseText;
    if (widget.phase == 'web_search') {
      phaseText = "🔍 Recherche d'informations sur le web...";
    } else if (widget.phase == 'memory') {
      phaseText = context.tr('ai_build_phase_memory');
    } else {
      phaseText = '✍️ Rédaction du cours en cours...';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  phaseText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              if (widget.onCancel != null)
                TextButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(context.tr('cancel')),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Barre Shimmer animée
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                height: 5,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    begin: Alignment(-2.0 + (_controller.value * 3.0), 0),
                    end: Alignment(-0.5 + (_controller.value * 3.0), 0),
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.2),
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              );
            },
          ),
          if (widget.text != null && widget.text!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Text(
                  widget.text!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

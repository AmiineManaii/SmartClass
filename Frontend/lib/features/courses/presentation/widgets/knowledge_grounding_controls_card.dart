import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/ai_course_options_provider.dart';
import '../../domain/entities/knowledge_grounding.dart';

/// Teacher-side RAG configuration card in the AI Course Creator settings pane:
/// toggles grounding on/off, filters source types, allows explicit opt-in
/// for unvalidated `DRAFT_AI` documents, and lets teachers pin specific docs.
class KnowledgeGroundingControlsCard extends ConsumerStatefulWidget {
  final KnowledgeGroundingConfig config;
  final ValueChanged<KnowledgeGroundingConfig> onChanged;

  const KnowledgeGroundingControlsCard({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  ConsumerState<KnowledgeGroundingControlsCard> createState() =>
      _KnowledgeGroundingControlsCardState();
}

class _KnowledgeGroundingControlsCardState
    extends ConsumerState<KnowledgeGroundingControlsCard> {
  bool _pickerExpanded = false;

  static const _sourceTypeOptions = <({String key, String label, IconData icon})>[
    (key: 'COURSE', label: 'Cours', icon: Icons.menu_book_rounded),
    (key: 'COURSE_SECTION', label: 'Sections', icon: Icons.segment_rounded),
    (key: 'LECTURE_TRANSCRIPT', label: 'Séances vidéo', icon: Icons.videocam_rounded),
    (key: 'LECTURE_SLIDE', label: 'Diapositives', icon: Icons.slideshow_rounded),
    (key: 'LECTURE_PACKAGE', label: 'Synthèses', icon: Icons.auto_awesome_rounded),
  ];

  void _toggleSourceType(String key) {
    final current = List<String>.from(widget.config.sourceTypes);
    if (current.contains(key)) {
      current.remove(key);
    } else {
      current.add(key);
    }
    widget.onChanged(widget.config.copyWith(sourceTypes: current));
  }

  void _toggleDocumentId(String id) {
    final current = List<String>.from(widget.config.documentIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    widget.onChanged(widget.config.copyWith(documentIds: current));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final docsAsync = ref.watch(myKnowledgeDocumentsProvider);
    final availableDocs = docsAsync.maybeWhen(
      data: (items) => items
          .where(
            (doc) =>
                doc.indexStatus == 'INDEXED' ||
                doc.indexStatus == 'PENDING_EMBEDDING',
          )
          .toList(),
      orElse: () => const <KnowledgeDocumentSummary>[],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.45)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.config.enabled
              ? colorScheme.primary.withValues(alpha: 0.35)
              : colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.hub_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Base de connaissances (RAG)',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (availableDocs.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${availableDocs.length} indexées',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Réutiliser vos cours validés et séances vidéo enregistrées',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.config.enabled,
                onChanged: (val) =>
                    widget.onChanged(widget.config.copyWith(enabled: val)),
              ),
            ],
          ),
          if (widget.config.enabled) ...[
            const SizedBox(height: 12),
            Text(
              'Types de sources autorisés (tous si aucun filtre)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _sourceTypeOptions.map((opt) {
                final selected = widget.config.sourceTypes.contains(opt.key);
                return FilterChip(
                  selected: selected,
                  showCheckmark: false,
                  avatar: Icon(opt.icon, size: 14),
                  label: Text(
                    opt.label,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => _toggleSourceType(opt.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => widget.onChanged(
                widget.config.copyWith(
                  includeDrafts: !widget.config.includeDrafts,
                ),
              ),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: widget.config.includeDrafts,
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) => widget.onChanged(
                        widget.config.copyWith(includeDrafts: v ?? false),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inclure les brouillons IA non validés',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Par défaut, seules vos ressources vérifiées sont utilisées.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _pickerExpanded = !_pickerExpanded),
                  icon: Icon(
                    _pickerExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                  ),
                  label: Text(
                    widget.config.documentIds.isEmpty
                        ? 'Choisir des sources précises'
                        : '${widget.config.documentIds.length} source(s) ciblée(s)',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const Spacer(),
                if (widget.config.documentIds.isNotEmpty)
                  TextButton(
                    onPressed: () =>
                        widget.onChanged(widget.config.copyWith(documentIds: [])),
                    child: const Text('Auto', style: TextStyle(fontSize: 11.5)),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  tooltip: 'Actualiser mes sources indexées',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ref.invalidate(myKnowledgeDocumentsProvider),
                ),
              ],
            ),
            if (_pickerExpanded) ...[
              const SizedBox(height: 6),
              docsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(10),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, _) => Text(
                  'Impossible de charger vos documents indexés pour le moment.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                data: (_) {
                  if (availableDocs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Aucune ressource indexée disponible. Validez un cours ou traitez une séance vidéo pour alimenter votre base.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 190),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: availableDocs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final doc = availableDocs[idx];
                        final checked =
                            widget.config.documentIds.contains(doc.id);
                        final isDraft = doc.trustTier == 'DRAFT_AI';
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: checked,
                          onChanged: (_) => _toggleDocumentId(doc.id),
                          title: Text(
                            doc.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium,
                          ),
                          subtitle: Text(
                            '${doc.sourceType} • ${doc.chunkCount} blocs • ${isDraft ? 'Brouillon IA' : 'Vérifié'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10.5,
                              color: isDraft
                                  ? colorScheme.secondary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}

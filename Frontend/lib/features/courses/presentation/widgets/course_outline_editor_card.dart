import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/course_outline.dart';

class CourseOutlineEditorCard extends StatefulWidget {
  final CourseOutline outline;
  final bool generating;
  final ValueChanged<CourseOutline> onOutlineChanged;
  final VoidCallback onGenerateFullCourse;
  final VoidCallback onRegenerateOutline;
  final VoidCallback onCancel;

  /// Opens the section-by-section builder (saves the draft with this plan
  /// first). Null → button hidden.
  final VoidCallback? onBuildSections;

  /// Draft-save spinner of [onBuildSections].
  final bool building;

  const CourseOutlineEditorCard({
    super.key,
    required this.outline,
    required this.generating,
    required this.onOutlineChanged,
    required this.onGenerateFullCourse,
    required this.onRegenerateOutline,
    required this.onCancel,
    this.onBuildSections,
    this.building = false,
  });

  @override
  State<CourseOutlineEditorCard> createState() =>
      _CourseOutlineEditorCardState();
}

class _CourseOutlineEditorCardState extends State<CourseOutlineEditorCard> {
  late CourseOutline _currentOutline;

  @override
  void initState() {
    super.initState();
    _currentOutline = widget.outline;
  }

  @override
  void didUpdateWidget(covariant CourseOutlineEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.outline != oldWidget.outline) {
      _currentOutline = widget.outline;
    }
  }

  void _updateOutline(CourseOutline newOutline) {
    setState(() {
      _currentOutline = newOutline;
    });
    widget.onOutlineChanged(newOutline);
  }

  void _moveSection(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final sections = List<CourseOutlineSection>.from(_currentOutline.sections);
    final item = sections.removeAt(oldIndex);
    sections.insert(newIndex, item);
    _updateOutline(_currentOutline.copyWith(sections: sections));
  }

  void _deleteSection(int index) {
    final sections = List<CourseOutlineSection>.from(_currentOutline.sections);
    sections.removeAt(index);
    _updateOutline(_currentOutline.copyWith(sections: sections));
  }

  int get _totalEstimatedMinutes {
    return _currentOutline.sections.fold<int>(
      0,
      (sum, s) => sum + (s.estimatedMinutes ?? 15),
    );
  }

  String _formatTotalDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h${remainingMinutes.toString().padLeft(2, '0')}';
  }

  Future<void> _editSection(int index) async {
    final section = _currentOutline.sections[index];
    final titleCtrl = TextEditingController(text: section.title);
    final descCtrl = TextEditingController(text: section.description);
    final subtopicsCtrl = TextEditingController(
      text: section.subtopics.join(', '),
    );
    final durationCtrl = TextEditingController(
      text: section.estimatedMinutes != null
          ? '${section.estimatedMinutes}'
          : '15',
    );

    final updated = await showDialog<CourseOutlineSection>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Modifier le chapitre ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titre du chapitre',
                    hintText: 'Ex: Fondamentaux du Web et Client-Serveur',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description / Objectifs pédagogiques',
                    hintText:
                        'Notions et concepts abordés dans cette partie...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: subtopicsCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText:
                        'Notions clés & mots-clés (séparés par des virgules)',
                    hintText:
                        'Modèle Client-Serveur, Protocole HTTP, Codes 2xx/4xx/5xx',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durée estimée (minutes)',
                    prefixIcon: Icon(Icons.schedule_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr('cancel')),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.check_rounded, size: 18),
              onPressed: () {
                final subtopics = subtopicsCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                final mins = int.tryParse(durationCtrl.text.trim()) ?? 15;
                Navigator.of(context).pop(
                  section.copyWith(
                    title: titleCtrl.text.trim().isNotEmpty
                        ? titleCtrl.text.trim()
                        : section.title,
                    description: descCtrl.text.trim(),
                    subtopics: subtopics,
                    estimatedMinutes: mins,
                  ),
                );
              },
              label: Text(context.tr('save')),
            ),
          ],
        );
      },
    );

    if (updated != null) {
      final sections = List<CourseOutlineSection>.from(
        _currentOutline.sections,
      );
      sections[index] = updated;
      _updateOutline(_currentOutline.copyWith(sections: sections));
    }
  }

  Future<void> _addSection() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final subtopicsCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '15');

    final created = await showDialog<CourseOutlineSection>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ajouter un chapitre',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Titre du nouveau chapitre',
                    hintText: 'Ex: Travaux Pratiques & Cas Réel',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description / Objectifs pédagogiques',
                    hintText: 'Résumé des notions qui seront enseignées...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: subtopicsCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notions clés (séparées par des virgules)',
                    hintText: 'Exercice 1, Mise en production, Débogage',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durée estimée (minutes)',
                    prefixIcon: Icon(Icons.schedule_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr('cancel')),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final subtopics = subtopicsCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                final mins = int.tryParse(durationCtrl.text.trim()) ?? 15;
                Navigator.of(context).pop(
                  CourseOutlineSection(
                    id: 'sec-${DateTime.now().microsecondsSinceEpoch}',
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    subtopics: subtopics,
                    estimatedMinutes: mins,
                  ),
                );
              },
              label: Text(context.tr('create')),
            ),
          ],
        );
      },
    );

    if (created != null) {
      final sections = List<CourseOutlineSection>.from(_currentOutline.sections)
        ..add(created);
      _updateOutline(_currentOutline.copyWith(sections: sections));
    }
  }

  Future<void> _editTitleAndDesc() async {
    final titleCtrl = TextEditingController(text: _currentOutline.title);
    final audienceCtrl = TextEditingController(
      text: _currentOutline.targetAudience,
    );
    final prereqCtrl = TextEditingController(
      text: _currentOutline.prerequisites.join(', '),
    );

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cadrage & Titre du cours'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Titre principal du cours',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: audienceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Public visé',
                  hintText: 'Ex: Licence 2 Informatique, Master...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: prereqCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Prérequis (séparés par des virgules)',
                  hintText: 'Bases programmation, Réseau...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );

    if (updated == true) {
      final prereqs = prereqCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      _updateOutline(
        _currentOutline.copyWith(
          title: titleCtrl.text.trim().isNotEmpty
              ? titleCtrl.text.trim()
              : _currentOutline.title,
          targetAudience: audienceCtrl.text.trim(),
          prerequisites: prereqs,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sections = _currentOutline.sections;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Elegant Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.7),
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag & Badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PLAN PROPOSÉ PAR L\'IA',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatTotalDuration(_totalEstimatedMinutes),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Editable Course Title
                InkWell(
                  onTap: _editTitleAndDesc,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _currentOutline.title.isNotEmpty
                                ? _currentOutline.title
                                : 'Titre du cours',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: colorScheme.onSurface,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Target Audience & Prerequisites Pills
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (_currentOutline.targetAudience.isNotEmpty)
                      _PillBadge(
                        icon: Icons.school_outlined,
                        label: _currentOutline.targetAudience,
                        colorScheme: colorScheme,
                      ),
                    ..._currentOutline.prerequisites.map(
                      (p) => _PillBadge(
                        icon: Icons.check_circle_outline,
                        label: p,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Body: Chapters List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Chapters Header Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Structure du cours',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${sections.length} chapitres',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Glissez pour réordonner',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Reorderable Chapters List
                if (sections.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Aucun chapitre. Cliquez ci-dessous pour en ajouter.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: sections.length,
                    onReorderItem: (oldIndex, newIndex) {
                      _moveSection(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final item = sections[index];

                      return _ChapterCard(
                        key: ValueKey(item.id),
                        index: index,
                        item: item,
                        isFirst: index == 0,
                        isLast: index == sections.length - 1,
                        onMoveUp: () => _moveSection(index, index - 1),
                        onMoveDown: () => _moveSection(index, index + 1),
                        onEdit: () => _editSection(index),
                        onDelete: () => _deleteSection(index),
                      );
                    },
                  ),

                const SizedBox(height: 14),

                // Add Chapter Outline Button
                OutlinedButton.icon(
                  onPressed: widget.generating ? null : _addSection,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Ajouter un chapitre personnalisé'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.5),
                      style: BorderStyle.solid,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),

                // Primary CTA: section-by-section (one chapter at a time,
                // each validated before the draft can be published, RG27).
                if (widget.onBuildSections != null) ...[
                  FilledButton.icon(
                    onPressed:
                        widget.generating || widget.building || sections.isEmpty
                        ? null
                        : widget.onBuildSections,
                    icon: widget.building
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.auto_awesome_motion_rounded,
                            size: 22,
                          ),
                    label: Text(
                      widget.building
                          ? context.tr('ai_build_save_building')
                          : context.tr('ai_build_save_outline'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: widget.generating || sections.isEmpty
                        ? null
                        : widget.onGenerateFullCourse,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(
                      widget.generating
                          ? 'Rédaction complète en cours...'
                          : context.tr('ai_outline_generate_all'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else
                  FilledButton.icon(
                    onPressed: widget.generating || sections.isEmpty
                        ? null
                        : widget.onGenerateFullCourse,
                    icon: widget.generating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome, size: 22),
                    label: Text(
                      widget.generating
                          ? 'Rédaction complète en cours...'
                          : '✨ Rédiger le cours complet selon ce plan',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                // Secondary Actions Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.generating
                            ? null
                            : widget.onRegenerateOutline,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Régénérer le plan'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: widget.generating ? null : widget.onCancel,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(context.tr('cancel')),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
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

class _ChapterCard extends StatelessWidget {
  final int index;
  final CourseOutlineSection item;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChapterCard({
    super.key,
    required this.index,
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter Header: Badge, Duration, and Action Buttons
            Row(
              children: [
                Flexible(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CHAPITRE ${(index + 1).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      if (item.estimatedMinutes != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.estimatedMinutes} min',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Action Buttons: Edit, Delete, Drag Handle
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onEdit,
                  tooltip: 'Modifier ce chapitre',
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Supprimer ce chapitre',
                ),
                // Drag handle for smooth tactile reordering
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Chapter Title (Full Width, clear hierarchy)
            Text(
              item.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                height: 1.35,
                color: colorScheme.onSurface,
              ),
            ),

            // Chapter Description
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],

            // Subtopics & Key Topics Pills
            if (item.subtopics.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.subtopics.map((st) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Icon(
                                Icons.circle,
                                size: 5,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: st,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _PillBadge({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

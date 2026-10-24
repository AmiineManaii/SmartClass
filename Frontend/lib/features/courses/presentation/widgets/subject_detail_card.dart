import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

/// Carte détaillée d'une matière pour l'enseignant.
/// Inclut un effet de survol, badge de comptage et classes associées.
class SubjectDetailCard extends StatefulWidget {
  final int index;
  final String subject;
  final int courseCount;
  final List<String> classNames;
  final bool isSelected;
  final double width;
  final VoidCallback onTap;

  const SubjectDetailCard({
    super.key,
    required this.index,
    required this.subject,
    required this.courseCount,
    required this.classNames,
    required this.isSelected,
    required this.width,
    required this.onTap,
  });

  @override
  State<SubjectDetailCard> createState() => _SubjectDetailCardState();
}

class _SubjectDetailCardState extends State<SubjectDetailCard>
    with SingleTickerProviderStateMixin {
  static const _accents = <Color>[
    Color(0xFF122675),
    Color(0xFF4056B9),
    Color(0xFF003627),
    Color(0xFF0F9D78),
    Color(0xFFF5A623),
  ];

  late final AnimationController _entry;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _hovered = false;

  Color get _accent => _accents[widget.index % _accents.length];

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
    Future<void>.delayed(Duration(milliseconds: 130 * widget.index), () {
      if (mounted) _entry.forward();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = widget.isSelected;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: widget.width,
              transformAlignment: Alignment.center,
              transform: Matrix4.identity()
                ..scaleByDouble(
                  _hovered ? 1.03 : 1.0,
                  _hovered ? 1.03 : 1.0,
                  1.0,
                  1.0,
                ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? _accent
                      : _hovered
                          ? _accent.withValues(alpha: 0.4)
                          : colorScheme.outlineVariant.withValues(alpha: 0.35),
                  width: selected ? 2.0 : 1.0,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                          spreadRadius: 1,
                        ),
                      ]
                    : _hovered
                        ? [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.16),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _accent,
                              _accent.withValues(alpha: 0.75),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.subject,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selected)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: _accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 13,
                              color: _accent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${widget.courseCount} ${context.tr('generated_courses').toLowerCase()}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.classNames.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.class_rounded,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.classNames.join(', '),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

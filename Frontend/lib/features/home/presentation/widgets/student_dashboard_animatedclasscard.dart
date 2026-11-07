part of '../widgets/student_dashboard_view.dart';
class _AnimatedClassCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _AnimatedClassCard({
    required this.index,
    required this.data,
    required this.onTap,
  });

  @override
  State<_AnimatedClassCard> createState() => _AnimatedClassCardState();
}

class _AnimatedClassCardState extends State<_AnimatedClassCard>
    with SingleTickerProviderStateMixin {
  Offset _tilt = Offset.zero;
  bool _hovered = false;
  late final AnimationController _entry;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    Future<void>.delayed(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) _entry.forward();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _onHover(Offset localPosition, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final dx = ((localPosition.dx / size.width) - 0.5).clamp(-0.5, 0.5);
    final dy = ((localPosition.dy / size.height) - 0.5).clamp(-0.5, 0.5);
    setState(() => _tilt = Offset(dx, dy));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = (widget.data['name'] as String?)?.trim();
    final title = (name == null || name.isEmpty) ? 'â€”' : name;
    final department = (widget.data['department'] as String?)?.trim();
    final level = (widget.data['level'] as String?)?.trim();
    final status = (widget.data['status'] as String?)?.trim() ?? 'PUBLISHED';
    final memberCount = (widget.data['memberCount'] as num?)?.toInt() ?? 0;
    final teacherCount = (widget.data['teacherCount'] as num?)?.toInt() ?? 0;
    final isPublished = status == 'PUBLISHED';

    final levelKey = switch (level) {
      'LICENCE' => 'level_licence',
      'MASTER' => 'level_master',
      'DOCTORAT' => 'level_doctorat',
      _ => null,
    };
    final levelLabel = levelKey != null ? context.tr(levelKey) : (level ?? '');

    final tags = <Widget>[
      if (department != null && department.isNotEmpty)
        _ClassTag(
          label: department,
          icon: Icons.account_balance_rounded,
          colorScheme: colorScheme,
        ),
      if (levelLabel.isNotEmpty)
        _ClassTag(
          label: levelLabel,
          icon: Icons.school_rounded,
          colorScheme: colorScheme,
        ),
      _ClassTag(
        label: context.tr(isPublished ? 'in_progress' : 'drafts'),
        icon: isPublished
            ? Icons.play_circle_outline_rounded
            : Icons.edit_note_rounded,
        colorScheme: colorScheme,
        accent: isPublished ? colorScheme.primary : colorScheme.tertiary,
      ),
      _ClassTag(
        label: context.tr(
          'courses_students_count',
          args: {'count': '$memberCount'},
        ),
        icon: Icons.people_alt_outlined,
        colorScheme: colorScheme,
      ),
      _ClassTag(
        label: context.tr(
          'courses_teachers_count',
          args: {'count': '$teacherCount'},
        ),
        icon: Icons.co_present_rounded,
        colorScheme: colorScheme,
      ),
    ];

    final tiltX = (_tilt.dy * -0.14);
    final tiltY = (_tilt.dx * 0.14);

    return FadeTransition(
      opacity: CurvedAnimation(parent: _entry, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic)),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _tilt = Offset.zero;
          }),
          onHover: (event) {
            final size = context.size;
            if (size != null) _onHover(event.localPosition, size);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            transformAlignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateX(tiltX)
              ..rotateY(tiltY)
              ..scaleByDouble(
                _hovered ? 1.012 : 1.0,
                _hovered ? 1.012 : 1.0,
                1.0,
                1.0,
              ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surfaceContainerLowest,
                        colorScheme.surfaceContainerLow,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _hovered
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(
                          alpha: _hovered ? 0.16 : 0.05,
                        ),
                        blurRadius: _hovered ? 24 : 10,
                        offset: Offset(0, _hovered ? 12 : 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: colorScheme.onPrimary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(spacing: 8, runSpacing: 8, children: tags),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


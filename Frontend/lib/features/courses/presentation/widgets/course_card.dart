import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/course_entry.dart';
import 'class_tag.dart';

/// Carte d'un cours de la classe de l'enseignant (onglet "Mes cours" étudiants).
///
/// - Affiche l'icône, le nom, les tags (niveau, département, statut, rôle,
///   nombre d'élèves, nombre d'enseignants) et une flèche de navigation.
/// - Effet de survol avec inclinaison (tilt) et scale.
/// - Le tap ouvre le détail de la classe à `/groups/:courseId`.
class CourseCard extends StatefulWidget {
  final CourseEntry course;
  final int index;

  const CourseCard({super.key, required this.course, this.index = 0});

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _hovered = false;
  Offset _tilt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(_fade);
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

  String _levelLabel(BuildContext context) {
    final key = switch (widget.course.level) {
      'LICENCE' => 'level_licence',
      'MASTER' => 'level_master',
      'DOCTORAT' => 'level_doctorat',
      _ => '',
    };
    return key.isEmpty ? widget.course.level : context.tr(key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final course = widget.course;
    final tiltX = -_tilt.dy * 0.10;
    final tiltY = _tilt.dx * 0.10;

    final tags = <Widget>[
      ClassTag(
        icon: Icons.school_rounded,
        label: _levelLabel(context),
        color: colorScheme.primary,
      ),
      if (course.department != null && course.department!.isNotEmpty)
        ClassTag(
          icon: Icons.account_balance_rounded,
          label: course.department!,
          color: colorScheme.secondary,
        ),
      ClassTag(
        icon: course.isPublished
            ? Icons.play_circle_outline_rounded
            : Icons.edit_note_rounded,
        label: context.tr(course.isPublished ? 'in_progress' : 'drafts'),
        color: course.isPublished ? colorScheme.primary : colorScheme.tertiary,
      ),
      if (course.myRole != 'STUDENT')
        ClassTag(
          icon: Icons.badge_outlined,
          label: context.tr(
            course.myRole == 'REFERENT' ? 'role_referent' : 'role_teacher',
          ),
          color: colorScheme.secondary,
        ),
      ClassTag(
        icon: Icons.people_alt_rounded,
        label: context.tr(
          'courses_students_count',
          args: {'count': '${course.memberCount}'},
        ),
        color: colorScheme.onSurfaceVariant,
      ),
      ClassTag(
        icon: Icons.co_present_rounded,
        label: context.tr(
          'courses_teachers_count',
          args: {'count': '${course.teacherCount}'},
        ),
        color: colorScheme.onSurfaceVariant,
      ),
    ];

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _tilt = Offset.zero;
          }),
          onHover: (event) {
            _onHover(event.localPosition, MediaQuery.of(context).size);
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
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hovered
                    ? colorScheme.primary.withValues(alpha: 0.35)
                    : colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(
                    alpha: _hovered ? 0.12 : 0.04,
                  ),
                  offset: Offset(0, _hovered ? 10 : 2),
                  blurRadius: _hovered ? 22 : 6,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/groups/${course.id}'),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: colorScheme.onPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              course.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 160),
                            offset: Offset(_hovered ? 0.15 : 0, 0),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: _hovered
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(spacing: 6, runSpacing: 6, children: tags),
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

part of '../widgets/teacher_dashboard_view.dart';
class _TeacherClassCard extends StatefulWidget {
  final TeacherDashboardClass teacherClass;

  const _TeacherClassCard({required this.teacherClass});

  @override
  State<_TeacherClassCard> createState() => _TeacherClassCardState();
}

class _TeacherClassCardState extends State<_TeacherClassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final teacherClass = widget.teacherClass;

    // Theme adaptive colors
    final cardBg = isDark
        ? (_isHovered ? const Color(0xFF161F36) : const Color(0xFF111728))
        : (_isHovered ? Colors.white : const Color(0xFFFCFDFF));

    final cardBorder = isDark
        ? (_isHovered
            ? colorScheme.primary.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.08))
        : (_isHovered
            ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
            : const Color(0xFFE2E8F0));

    final promoBg = isDark
        ? const Color(0xFF1E284A)
        : const Color(0xFFEEF2FF);
    final promoBorder = isDark
        ? const Color(0xFF3B82F6).withValues(alpha: 0.28)
        : const Color(0xFFC7D2FE);
    final promoTextColor = isDark
        ? const Color(0xFF93C5FD)
        : const Color(0xFF4338CA);

    final statusBg = isDark
        ? const Color(0xFF064E3B).withValues(alpha: 0.55)
        : const Color(0xFFECFDF5);
    final statusBorder = isDark
        ? const Color(0xFF059669).withValues(alpha: 0.35)
        : const Color(0xFFA7F3D0);
    final statusText = isDark
        ? const Color(0xFF34D399)
        : const Color(0xFF047857);

    final titleColor = colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurfaceVariant;

    final studentChipBg = isDark
        ? const Color(0xFF192238)
        : const Color(0xFFF8FAFC);
    final studentChipBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);
    final studentTextColor = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF334155);

    final subjectChipBg = isDark
        ? const Color(0xFF231C38)
        : const Color(0xFFF5F3FF);
    final subjectChipBorder = isDark
        ? const Color(0xFF8B5CF6).withValues(alpha: 0.28)
        : const Color(0xFFDDD6FE);
    final subjectTextColor = isDark
        ? const Color(0xFFDDD6FE)
        : const Color(0xFF5B21B6);

    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFF1F5F9);

    final inviteBg = isDark
        ? const Color(0xFF1C2442)
        : const Color(0xFFEEF2FF);
    final inviteBorder = isDark
        ? const Color(0xFF4F46E5).withValues(alpha: 0.4)
        : const Color(0xFFC7D2FE);
    final inviteText = isDark
        ? const Color(0xFFA5B4FC)
        : const Color(0xFF4338CA);

    final openActionColor = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF122675);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cardBorder,
            width: 1.2,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isHovered ? 0.45 : 0.3),
                    blurRadius: _isHovered ? 24 : 16,
                    offset: Offset(0, _isHovered ? 8 : 4),
                  ),
                  if (_isHovered)
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 4),
                    ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: _isHovered ? 0.09 : 0.05),
                    blurRadius: _isHovered ? 22 : 14,
                    offset: Offset(0, _isHovered ? 6 : 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/groups/${teacherClass.id}', extra: teacherClass.name),
            borderRadius: BorderRadius.circular(20),
            splashColor: colorScheme.primary.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Promo badge + Status chip + Arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Promo Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: promoBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: promoBorder, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_rounded,
                              size: 13,
                              color: promoTextColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              teacherClass.promoTag,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: promoTextColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status & Chevron
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusBorder, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Actif',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: statusText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 30,
                            height: 30,
                            transform: Matrix4.translationValues(_isHovered ? 2 : 0, 0, 0),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? (_isHovered
                                      ? colorScheme.primary.withValues(alpha: 0.25)
                                      : Colors.white.withValues(alpha: 0.06))
                                  : (_isHovered
                                      ? const Color(0xFFEEF2FF)
                                      : const Color(0xFFF1F5F9)),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: isDark
                                  ? (_isHovered ? colorScheme.primary : const Color(0xFF94A3B8))
                                  : (_isHovered ? const Color(0xFF122675) : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 2: Class Avatar + Title & Subtitle
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.35 : 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.class_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacherClass.name,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Gérer les cours & étudiants',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 3: Meta chips (Students, Subjects, Next session)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: studentChipBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: studentChipBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_alt_rounded,
                              size: 13,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${teacherClass.memberCount} ${context.tr('stat_students')}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: studentTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final subject in teacherClass.subjects)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: subjectChipBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: subjectChipBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 13,
                                color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                subject,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: subjectTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (teacherClass.nextSessionLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2D2315) : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.3) : const Color(0xFFFDE68A),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 13,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                teacherClass.nextSessionLabel!,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Hairline Divider
                  Divider(height: 1, thickness: 0.8, color: dividerColor),
                  const SizedBox(height: 12),

                  // Row 4: Action Footer
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 8,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => ClassInvitationSheet.show(
                            context,
                            classGroupId: teacherClass.id,
                            className: teacherClass.name,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: inviteBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: inviteBorder, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.key_rounded,
                                  size: 14,
                                  color: inviteText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Code d'invitation",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: inviteText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ouvrir la classe',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: openActionColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            transform: Matrix4.translationValues(_isHovered ? 3 : 0, 0, 0),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: openActionColor,
                            ),
                          ),
                        ],
                      ),
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


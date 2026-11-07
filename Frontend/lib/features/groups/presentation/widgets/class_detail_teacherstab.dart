part of '../pages/class_detail_page.dart';
class _TeachersTab extends StatelessWidget {
  final List<Map<String, dynamic>> teachers;
  final String? referentId;
  final List<String> mySubjects;
  final bool canAddSubject;
  final VoidCallback onAddSubject;

  const _TeachersTab({
    required this.teachers,
    this.referentId,
    this.mySubjects = const [],
    this.canAddSubject = false,
    required this.onAddSubject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final grouped = <String, _TeacherEntry>{};
    for (final teacher in teachers) {
      final teacherId = teacher['teacherId'] as String? ?? '';
      if (teacherId.isEmpty) continue;
      final entry = grouped.putIfAbsent(
        teacherId,
        () => _TeacherEntry(
          teacherId: teacherId,
          firstName: teacher['firstName'] as String? ?? '',
          lastName: teacher['lastName'] as String? ?? '',
          email: teacher['email'] as String? ?? '',
        ),
      );
      final subject = (teacher['subject'] as String?)?.trim() ?? '';
      if (subject.isNotEmpty &&
          !entry.subjects.any((item) => item.subject == subject)) {
        entry.subjects.add(
          _TaughtSubject(subject, teacher['weeklyHours'] as String?),
        );
      }
    }
    final entries = grouped.values.toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (canAddSubject) ...[
          _MySubjectsCard(mySubjects: mySubjects, onAddSubject: onAddSubject),
          const SizedBox(height: 14),
        ],
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 10),
                Text(
                  'Aucun enseignant assigné pour l\'instant.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TeacherCard(
                entry: entry,
                isReferent: referentId != null && referentId == entry.teacherId,
              ),
            ),
          ),
      ],
    );
  }
}


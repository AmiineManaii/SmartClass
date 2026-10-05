enum TeacherStatTone { success, secondary, error }

class TeacherStat {
  final String id;
  final String icon;
  final String value;
  final String labelKey;
  final String badgeKey;
  final TeacherStatTone tone;

  const TeacherStat({
    required this.id,
    required this.icon,
    required this.value,
    required this.labelKey,
    required this.badgeKey,
    required this.tone,
  });
}

class TeacherLiveSession {
  final String time;
  final String title;

  const TeacherLiveSession({required this.time, required this.title});
}

class TeacherClass {
  final String id;
  final String tag;
  final String title;
  final String icon;
  final int students;
  final String schedule;
  final double completion;
  final int homeworkCount;
  final bool primaryProgress;

  const TeacherClass({
    required this.id,
    required this.tag,
    required this.title,
    required this.icon,
    required this.students,
    required this.schedule,
    required this.completion,
    required this.homeworkCount,
    this.primaryProgress = true,
  });
}

class MockTeacherDashboardDataSource {
  const MockTeacherDashboardDataSource();

  TeacherLiveSession liveSession() => const TeacherLiveSession(
        time: '14h00',
        title: 'Architecture des ordinateurs (Amphi B)',
      );

  List<TeacherStat> stats() => const [
        TeacherStat(
          id: 'students',
          icon: 'school',
          value: '120',
          labelKey: 'stat_students',
          badgeKey: 'stat_this_week',
          tone: TeacherStatTone.success,
        ),
        TeacherStat(
          id: 'courses',
          icon: 'auto_stories',
          value: '4',
          labelKey: 'stat_active_courses',
          badgeKey: 'stat_semester_2',
          tone: TeacherStatTone.secondary,
        ),
        TeacherStat(
          id: 'grading',
          icon: 'assignment_turned_in',
          value: '2',
          labelKey: 'stat_to_grade',
          badgeKey: 'stat_urgent',
          tone: TeacherStatTone.error,
        ),
      ];

  List<TeacherClass> classes() => const [
        TeacherClass(
          id: '3a-info',
          tag: 'Licence 3 · Promo 2024-2025',
          title: 'Classe 3A - Informatique',
          icon: 'laptop_chromebook',
          students: 48,
          schedule: 'Demain 09h00',
          completion: 0.84,
          homeworkCount: 12,
          primaryProgress: true,
        ),
        TeacherClass(
          id: '2b-algo',
          tag: 'Licence 2 · Groupe A',
          title: 'Classe 2B - Algorithmes',
          icon: 'account_tree',
          students: 36,
          schedule: 'Jeudi 11h00',
          completion: 0.72,
          homeworkCount: 8,
          primaryProgress: false,
        ),
      ];
}

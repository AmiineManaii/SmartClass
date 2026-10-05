class StudentMotivationStats {
  final int streakDays;
  final int weeklyGoalPercent;

  const StudentMotivationStats({
    required this.streakDays,
    required this.weeklyGoalPercent,
  });
}

class StudentLiveSession {
  final String subject;
  final String instructor;
  final String chapter;
  final String time;
  final int minutesRemaining;
  final List<String> attendeesInitials;
  final int extraAttendeesCount;

  const StudentLiveSession({
    required this.subject,
    required this.instructor,
    required this.chapter,
    required this.time,
    required this.minutesRemaining,
    required this.attendeesInitials,
    required this.extraAttendeesCount,
  });
}

class StudentCourseProgress {
  final String id;
  final String title;
  final String lastLesson;
  final int progressPercent;
  final String badgeText;
  final String badgeTone; // 'tertiary' (green), 'neutral' (surface-container)
  final String iconName; // 'terminal', 'database', 'memory'
  final String progressColorTone; // 'primary', 'secondary', 'surfaceTint'

  const StudentCourseProgress({
    required this.id,
    required this.title,
    required this.lastLesson,
    required this.progressPercent,
    required this.badgeText,
    required this.badgeTone,
    required this.iconName,
    required this.progressColorTone,
  });
}

class StudentAssignment {
  final String id;
  final String title;
  final int? questionsCount;
  final int? estDurationMinutes;
  final String deadlineText;
  final bool isUrgent;
  final String? weightNote;
  final String actionType; // 'start', 'deposit', 'none'
  final String iconName; // 'assignment_late', 'code_blocks', 'functions'
  final bool hasAutoAiValidation;
  final String? submissionType;
  final String? extraDetails;

  const StudentAssignment({
    required this.id,
    required this.title,
    this.questionsCount,
    this.estDurationMinutes,
    required this.deadlineText,
    this.isUrgent = false,
    this.weightNote,
    required this.actionType,
    required this.iconName,
    this.hasAutoAiValidation = false,
    this.submissionType,
    this.extraDetails,
  });
}

class MockStudentDashboardDataSource {
  const MockStudentDashboardDataSource();

  StudentMotivationStats motivationStats() => const StudentMotivationStats(
        streakDays: 5,
        weeklyGoalPercent: 85,
      );

  StudentLiveSession imminentLive() => const StudentLiveSession(
        subject: 'Mathématiques · Algèbre linéaire',
        instructor: 'Prof. Amine',
        chapter: 'Chapitre 3 : Espaces vectoriels et applications',
        time: '14h00',
        minutesRemaining: 15,
        attendeesInitials: ['YM', 'TL', 'KB'],
        extraAttendeesCount: 18,
      );

  List<StudentCourseProgress> coursesProgress() => const [
        StudentCourseProgress(
          id: 'python-algo',
          title: 'Python & Algorithmique Avancée',
          lastLesson: 'Dernière leçon : Structures linéaires',
          progressPercent: 75,
          badgeText: 'À jour',
          badgeTone: 'tertiary',
          iconName: 'terminal',
          progressColorTone: 'primary',
        ),
        StudentCourseProgress(
          id: 'db-sql',
          title: 'Bases de Données & SQL',
          lastLesson: 'Dernière leçon : Jointures complexes',
          progressPercent: 60,
          badgeText: 'En cours',
          badgeTone: 'neutral',
          iconName: 'database',
          progressColorTone: 'secondary',
        ),
        StudentCourseProgress(
          id: 'sys-arch',
          title: 'Architecture des Systèmes',
          lastLesson: 'Prochaine étape : Mémoire cache',
          progressPercent: 40,
          badgeText: 'Module 4',
          badgeTone: 'neutral',
          iconName: 'memory',
          progressColorTone: 'surfaceTint',
        ),
      ];

  List<StudentAssignment> upcomingAssignments() => const [
        StudentAssignment(
          id: 'qcm-ch2',
          title: 'QCM Chapitre 2 : Arbres & Graphes',
          questionsCount: 10,
          estDurationMinutes: 20,
          deadlineText: 'Aujourd\'hui, 23h59',
          isUrgent: true,
          weightNote: 'Comptant pour 15% de la note CC',
          actionType: 'start',
          iconName: 'assignment_late',
        ),
        StudentAssignment(
          id: 'proj-python',
          title: 'Projet Python : Implémentation Liste Chaînée',
          deadlineText: 'Demain, 18h00',
          hasAutoAiValidation: true,
          submissionType: 'Dépôt Git ou fichier .py',
          actionType: 'deposit',
          iconName: 'code_blocks',
        ),
        StudentAssignment(
          id: 'test-math',
          title: 'Test de Mathématiques Discrètes',
          questionsCount: 15,
          extraDetails: '15 questions · Prévu en ligne',
          deadlineText: 'Vendredi 27 Oct',
          actionType: 'none',
          iconName: 'functions',
        ),
      ];
}

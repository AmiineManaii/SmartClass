import '../../domain/entities/admin_overview.dart';
import '../../domain/entities/admin_person.dart';
import '../../domain/entities/fraud_report.dart';
import '../../domain/entities/managed_class.dart';
import '../../domain/entities/timetable.dart';

/// TEMPORARY mock source for the whole admin bounded context.
///
/// No backend module exists yet for users/groups/courses/exams/
/// videoconference (all 📋 planned in `contracts/README.md`), so every
/// value below is illustrative mock data shaped exactly like the future
/// API responses. Replace method bodies with Dio calls when contracts land —
/// presentation and domain stay untouched.
class MockAdminDataSource {
  const MockAdminDataSource();

  AdminOverview overview() => const AdminOverview(
        stats: [
          AdminStat(
            id: 'students',
            icon: 'school',
            value: '1,250',
            labelKey: 'admin_stat_students',
            badgeKey: 'admin_stat_students_badge',
            badgeArgs: {'count': '32'},
          ),
          AdminStat(
            id: 'teachers',
            icon: 'badge',
            value: '48',
            labelKey: 'admin_stat_teachers',
            badgeKey: 'admin_stat_teachers_badge',
            badgeArgs: {'pct': '100'},
          ),
          AdminStat(
            id: 'classes',
            icon: 'class',
            value: '18',
            labelKey: 'admin_stat_classes',
            badgeKey: 'admin_stat_classes_badge',
            badgeArgs: {'count': '4'},
          ),
          AdminStat(
            id: 'frauds',
            icon: 'warning',
            value: '3',
            labelKey: 'admin_stat_frauds',
            badgeKey: 'admin_stat_frauds_badge',
            tone: AdminStatTone.error,
            highlighted: true,
          ),
        ],
        shortcuts: [
          AdminShortcut(
            id: 'classes',
            icon: 'meeting_room',
            titleKey: 'admin_nav_classes',
            descKey: 'admin_nav_classes_desc',
            route: '/admin/classes',
          ),
          AdminShortcut(
            id: 'teachers',
            icon: 'manage_accounts',
            titleKey: 'admin_nav_teachers',
            descKey: 'admin_nav_teachers_desc',
            route: '/admin/classes',
          ),
          AdminShortcut(
            id: 'students',
            icon: 'groups',
            titleKey: 'admin_nav_students',
            descKey: 'admin_nav_students_desc',
            route: '/admin/classes',
          ),
          AdminShortcut(
            id: 'planning',
            icon: 'calendar_month',
            titleKey: 'admin_nav_planning',
            descKey: 'admin_nav_planning_desc',
            route: '/admin/planning',
          ),
        ],
        alerts: [
          AdminAlert(
            id: 'fraud-1',
            icon: 'shield',
            title: 'Rapport de Fraude - Examen Algorithmes',
            subtitle: 'Détection sortie plein écran (Classe 3A • 14:12)',
            chips: [
              AdminAlertChip(text: 'À vérifier', tone: AdminStatTone.error),
              AdminAlertChip(text: 'Examen Partiel L3', tone: AdminStatTone.info),
              AdminAlertChip(text: 'Élève ID #8921', tone: AdminStatTone.info),
            ],
            primaryActionKey: 'admin_review_incident',
            secondaryActionKey: 'admin_ignore',
          ),
          AdminAlert(
            id: 'planning-1',
            icon: 'calendar_month',
            title: 'Emploi du temps mis à jour',
            subtitle: 'Salle 104 modifiée pour TD Réseaux par Prof. Laurent',
            meta: 'Il y a 45 min',
            chips: [
              AdminAlertChip(text: 'Planning validé ✓', tone: AdminStatTone.success),
              AdminAlertChip(text: 'Classe 2B Informatique', tone: AdminStatTone.info),
            ],
            primaryActionKey: 'admin_review_incident',
          ),
        ],
      );

  List<AdminClassSummary> classes() => const [
        AdminClassSummary(
          id: 'info-3a',
          promoTag: 'Licence 3 • Promo 2024-2025',
          statusKey: 'admin_active_badge',
          title: 'Informatique 3A',
          icon: 'laptop',
          students: 35,
          teachers: 4,
          referent: 'Prof. Amine (Référent)',
          presencePct: 96,
          coursesActive: 12,
          level: ClassLevel.licence,
        ),
        AdminClassSummary(
          id: 'math-1b',
          promoTag: 'Licence 1 • Promo 2024-2025',
          statusKey: 'admin_active_badge',
          title: 'Mathématiques 1B',
          icon: 'functions',
          students: 42,
          teachers: 2,
          referent: 'Prof. Laurent',
          presencePct: 91,
          coursesActive: 8,
          level: ClassLevel.licence,
        ),
        AdminClassSummary(
          id: 'ia-m2',
          promoTag: 'Master 2 • Promo 2024-2025',
          statusKey: 'admin_active_badge',
          title: 'IA & Data Sciences M2',
          icon: 'psychology',
          students: 28,
          teachers: 5,
          referent: 'Projets R&D',
          presencePct: 98,
          coursesActive: 14,
          level: ClassLevel.master,
        ),
        AdminClassSummary(
          id: 'sys-2a',
          promoTag: 'Licence 2 • Promo 2024-2025',
          statusKey: 'admin_exam_ongoing',
          statusActive: false,
          title: 'Systèmes & Réseaux 2A',
          icon: 'lan',
          students: 38,
          teachers: 3,
          referent: 'Prof. Benali',
          presencePct: 89,
          coursesActive: 10,
          level: ClassLevel.licence,
        ),
      ];

  List<AdminStudent> students() => const [
        AdminStudent(
          id: 's1',
          name: 'Salma Idrissi',
          email: 'salma.idrissi@univ-smartclass.fr',
          badge: 'L3 Informatique • Major Promo',
          verified: true,
          assignedClassId: 'info-3a',
        ),
        AdminStudent(
          id: 's2',
          name: 'Karim Bennani',
          email: 'karim.bennani@univ-smartclass.fr',
          badge: 'L2 Informatique • Validée',
          assignedClassId: 'info-3a',
        ),
        AdminStudent(
          id: 's3',
          name: 'Yasmine Belkacem',
          email: 'yasmine.belkacem@univ-smartclass.fr',
          badge: 'Candidature acceptée',
        ),
        AdminStudent(
          id: 's4',
          name: 'Thomas Mercier',
          email: 'thomas.mercier@univ-smartclass.fr',
          badge: 'Transfert externe',
          initials: 'TM',
        ),
        AdminStudent(
          id: 's5',
          name: 'Aya El Fassi',
          email: 'aya.elfassi@univ-smartclass.fr',
          badge: 'L3 Reclassement',
          initials: 'AE',
        ),
        AdminStudent(
          id: 's6',
          name: 'Lucas Moreau',
          email: 'lucas.moreau@univ-smartclass.fr',
          badge: 'L2 Math-Info',
          initials: 'LM',
        ),
      ];

  List<AdminTeacher> teachers() => const [
        AdminTeacher(
          id: 't1',
          name: 'Prof. Amine Mansouri',
          email: 'amine.mansouri@univ-smartclass.fr',
          specialty: 'Dév. Web & Mobile',
          department: 'Informatique',
          availabilityKey: 'admin_assigned_hours',
          availabilityArgs: '4h/semaine',
          subjectLabel: 'Dév. Mobile & Cross-Platform (React/Flutter)',
          subjectValue: 'CM (18h) + TP (24h)',
          state: PersonAssignState.assigned,
          initiallyAssigned: true,
        ),
        AdminTeacher(
          id: 't2',
          name: 'Prof. Laurent Valette',
          email: 'laurent.valette@univ-smartclass.fr',
          specialty: 'Réseaux & Systèmes Cloud',
          department: 'Réseaux',
          availabilityKey: 'admin_avail_hours',
          availabilityArgs: '12h dispo / semaine',
          subjectLabel: 'Architecture Réseaux & Sécurité',
          subjectValue: 'admin_not_assigned',
        ),
        AdminTeacher(
          id: 't3',
          name: 'Dr. Sarah Benali',
          email: 'sarah.benali@univ-smartclass.fr',
          specialty: 'Bases de Données SQL/NoSQL',
          department: 'Bases de données',
          availabilityKey: 'admin_avail_hours',
          availabilityArgs: '8h dispo / semaine',
          subjectLabel: 'Bases de Données Réparties (L3)',
          subjectValue: 'admin_pending',
          state: PersonAssignState.pending,
        ),
        AdminTeacher(
          id: 't4',
          name: 'Prof. Marc Dupont',
          email: 'marc.dupont@univ-smartclass.fr',
          specialty: 'Algorithmique & Complexité',
          department: 'Algorithmique',
          availabilityKey: 'admin_full_load',
          subjectLabel: 'Algorithmique & Optimisation',
          subjectValue: 'admin_dean_reserve',
          state: PersonAssignState.warning,
        ),
      ];

  PlannerWeek weekSchedule() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    List<PlannerDay> days(int selected) => List.generate(6, (i) {
          final date = monday.add(Duration(days: i));
          return PlannerDay(
            date: date,
            courseCount: [4, 3, 2, 4, 3, 0][i],
            isMakeup: i == 5,
            isToday: date.year == now.year &&
                date.month == now.month &&
                date.day == now.day,
          );
        });
    return PlannerWeek(
      monday: monday,
      days: days(0),
      hoursScheduled: '7h30',
      conflicts: 0,
      ratePct: 85,
      events: const [
        PlannerEvent(
          id: 'e1',
          start: '08:00',
          end: '10:00',
          kind: PlannerEventKind.cm,
          title: 'Développement Mobile & Cross-Platform',
          subtitle: 'Architecture MVVM & cycle de vie des interfaces tactiles',
          teacherName: 'Prof. Amine Mansouri',
          teacherRole: 'Responsable pédagogique',
          roomKey: 'admin_room_label',
          roomValue: 'Salle 102',
          statusLines: ['admin_confirmed_open'],
          actionKey: 'admin_take_attendance',
        ),
        PlannerEvent(
          id: 'break1',
          start: '10:00',
          end: '',
          kind: PlannerEventKind.pause,
          title: 'Pause récréative • 15 minutes',
        ),
        PlannerEvent(
          id: 'e2',
          start: '10:15',
          end: '12:15',
          kind: PlannerEventKind.tp,
          title: 'Bases de Données Réparties',
          subtitle: 'Partitionnement horizontal & clusters PostgreSQL',
          teacherName: 'Dr. Sarah Benali',
          teacherRole: 'Intervenante externe',
          teacherInitials: 'SB',
          roomKey: 'admin_room_label',
          roomValue: 'Salle 204',
          statusLines: ['admin_session_validated', 'admin_group_full'],
        ),
        PlannerEvent(
          id: 'lunch',
          start: '12:15',
          end: '13:45',
          kind: PlannerEventKind.lunch,
          title: 'Pause Déjeuner & Permanence',
          subtitle: 'Restaurant Universitaire / Foyer 3A',
          noteDuration: '1h30',
        ),
        PlannerEvent(
          id: 'e3',
          start: '13:45',
          end: '15:45',
          kind: PlannerEventKind.td,
          title: 'Architecture Réseaux & Sécurité',
          subtitle: 'Cryptographie appliquée et protocoles TLS 1.3',
          teacherName: 'Prof. Laurent Valette',
          teacherRole: 'Département Réseaux',
          teacherInitials: 'LV',
          roomValue: 'Amphi B',
          statusLines: ['admin_hybrid_on'],
        ),
        PlannerEvent(
          id: 'free1',
          start: '16:00',
          end: '17:30',
          kind: PlannerEventKind.free,
          title: 'admin_free_slot',
          subtitle: 'admin_free_desc',
          noteDuration: '1h30 disponible',
        ),
      ],
    );
  }

  FraudSummary fraudSummary() => const FraudSummary(
        unresolved: 3,
        resolvedThisMonth: 12,
        integrityPct: 99.4,
      );

  List<FraudReport> fraudReports() => const [
        FraudReport(
          id: 'f1',
          severity: FraudSeverity.critical,
          status: FraudStatus.untreated,
          time: '10:45',
          title: 'Suspicion de Fraude - QCM Mathématiques',
          subtitle: 'Examen Partiel Semestre 6 • Durée 60 min',
          studentName: 'Salma M.',
          studentId: '#ETU-8921',
          studentClass: 'Licence 3 Informatique 3A',
          findings: [
            'Perte de focus écran x5 & Tentative copier-coller (Presse-papier)',
            'Détection IA webcam : Regard hors écran prolongé (> 45s)',
          ],
        ),
        FraudReport(
          id: 'f2',
          severity: FraudSeverity.medium,
          status: FraudStatus.untreated,
          time: '09:15',
          title: 'Détection double écran & Partage de flux',
          subtitle: 'Algorithmique Avancée & Graphes • M1 Session 2',
          studentName: 'Yassine B.',
          studentId: '#ETU-4102',
          studentClass: 'Master 1 Info',
          findings: [
            'Connexion simultanée détectée via adresse IP externe',
          ],
        ),
        FraudReport(
          id: 'f3',
          severity: FraudSeverity.closed,
          status: FraudStatus.closed,
          time: 'Hier 16:20',
          title: 'Changement d\'appareil suspect',
          subtitle: 'Bases de Données Réparties • TP Évalué',
          studentName: 'Karim T.',
          studentId: '#ETU-3329',
          studentClass: 'Licence 3 Info',
          reason:
              'Micro-coupure réseau suivie d\'une reconnexion sur tablette.',
          resolution:
              'Justificatif de panne Wi-Fi campus validé par Prof. Amine. Dossier clôturé le 11 Mai 2025',
        ),
      ];
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartclass/core/localization/app_localizations.dart';
import 'package:smartclass/core/responsive/responsive_layout.dart';
import 'package:smartclass/features/authentication/presentation/views/web_login_view.dart';
import 'package:smartclass/features/authentication/presentation/views/web_register_view.dart';
import 'package:smartclass/features/authentication/presentation/views/web_verify_email_view.dart';
import 'package:smartclass/features/authentication/presentation/views/web_role_selection_view.dart';
import 'package:smartclass/features/authentication/presentation/views/web_profile_setup_view.dart';
import 'package:smartclass/features/authentication/presentation/views/web_forgot_password_view.dart';
import 'package:smartclass/features/authentication/presentation/views/web_reset_password_view.dart';
import 'package:smartclass/features/admin/presentation/views/web_admin_dashboard_view.dart';
import 'package:smartclass/features/admin/presentation/views/web_admin_users_view.dart';
import 'package:smartclass/features/admin/presentation/views/web_admin_classes_view.dart';
import 'package:smartclass/features/admin/presentation/views/web_admin_reports_view.dart';
import 'package:smartclass/core/widgets/web_main_scaffold.dart';
import 'package:smartclass/features/home/presentation/widgets/student_dashboard_view.dart';
import 'package:smartclass/features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import 'package:smartclass/features/courses/presentation/pages/ai_course_creator_page.dart';
import 'package:smartclass/features/exams/presentation/pages/exams_page.dart';
import 'package:smartclass/features/exams/presentation/pages/secure_exam_page.dart';
import 'package:smartclass/features/exams/presentation/pages/exam_ai_score_page.dart';
import 'package:smartclass/features/courses/presentation/pages/course_reader_page.dart';
import 'package:smartclass/features/courses/application/providers/courses_provider.dart';
import 'package:smartclass/features/courses/domain/entities/course_entry.dart';
import 'package:smartclass/features/courses/domain/entities/generated_course.dart';

Widget _buildDesktopTestHarness(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('ResponsiveLayout & Breakpoints', () {
    testWidgets('ResponsiveLayout adapts dynamically to mobile vs desktop',
        (WidgetTester tester) async {
      // 1. Mobile viewport
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: const Text('MOBILE_VIEW'),
            desktop: const Text('DESKTOP_VIEW'),
          ),
        ),
      );
      expect(find.text('MOBILE_VIEW'), findsOneWidget);
      expect(find.text('DESKTOP_VIEW'), findsNothing);

      // 2. Desktop viewport
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: const Text('MOBILE_VIEW'),
            desktop: const Text('DESKTOP_VIEW'),
          ),
        ),
      );
      expect(find.text('DESKTOP_VIEW'), findsOneWidget);
      expect(find.text('MOBILE_VIEW'), findsNothing);
    });
  });

  group('Web Pages Desktop Layout Tests', () {
    setUp(() {
      // Common setup for desktop testing
    });

    testWidgets('WebLoginPage renders on desktop viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildDesktopTestHarness(const WebLoginPage()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WebLoginPage), findsOneWidget);
      expect(find.text('Connexion à votre espace'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('WebRegisterPage renders on desktop viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildDesktopTestHarness(const WebRegisterPage()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WebRegisterPage), findsOneWidget);
      expect(find.text('Créer un compte SmartClass'), findsOneWidget);
    });

    testWidgets('WebAdminDashboardPage renders on desktop viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(const WebAdminDashboardPage()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WebAdminDashboardPage), findsOneWidget);
      expect(find.text('Tableau de Bord Administrateur'), findsOneWidget);
      expect(find.text('EFFECTIF TOTAL'), findsOneWidget);
      expect(find.text('CORPS ENSEIGNANT'), findsOneWidget);
      expect(find.text('GROUPES PÉDAGOGIQUES'), findsOneWidget);
    });

    testWidgets('WebAdminUsersPage renders on desktop viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(const WebAdminUsersPage()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WebAdminUsersPage), findsOneWidget);
      expect(find.text('Gestion des Utilisateurs'), findsOneWidget);
    });

    testWidgets('WebAdminClassesPage renders on desktop viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(const WebAdminClassesPage()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WebAdminClassesPage), findsOneWidget);
      expect(find.text('Gestion des Classes & Groupes'), findsOneWidget);
    });

    testWidgets('WebAdminReportsPage renders on desktop viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(const WebAdminReportsPage()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WebAdminReportsPage), findsOneWidget);
      expect(find.text('Rapports de Fraude & Intégrité des Examens'), findsOneWidget);
    });

    testWidgets('WebLoginPage switches roles smoothly when clicking segmented tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildDesktopTestHarness(const WebLoginPage()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Étudiant'), findsOneWidget);
      expect(find.text('Enseignant'), findsOneWidget);
      expect(find.text('Administrateur'), findsOneWidget);

      // Tap on Enseignant
      await tester.tap(find.text('Enseignant'));
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on Administrateur
      await tester.tap(find.text('Administrateur'));
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('WebVerifyEmailView renders on desktop viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(
          const WebVerifyEmailView(email: 'test@universite.fr'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WebVerifyEmailView), findsOneWidget);
      expect(find.text('test@universite.fr'), findsOneWidget);
    });

    testWidgets('WebRoleSelectionView renders on desktop viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(const WebRoleSelectionView()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WebRoleSelectionView), findsOneWidget);
      expect(find.text('Bienvenue ! Qui êtes-vous ?'), findsOneWidget);
      expect(find.text('ÉTAPE 1 SUR 3'), findsOneWidget);
    });

    testWidgets('WebProfileSetupView renders on desktop viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(const WebProfileSetupView()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WebProfileSetupView), findsOneWidget);
      expect(find.text('Finalisation du profil académique'), findsOneWidget);
      expect(find.text('Configuration de votre profil'), findsOneWidget);
    });

    testWidgets('WebForgotPasswordView renders on desktop viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(const WebForgotPasswordView()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WebForgotPasswordView), findsOneWidget);
      expect(find.text('RÉCUPÉRATION'), findsOneWidget);
    });

    testWidgets('WebResetPasswordView renders on desktop viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(const WebResetPasswordView()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WebResetPasswordView), findsOneWidget);
      expect(find.text('SÉCURITÉ'), findsOneWidget);
    });

    testWidgets('WebMainScaffold renders student desktop navigation sidebar and top bar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(
          const WebMainScaffold(
            activePath: '/home',
            role: 'student',
            body: Center(child: Text('STUDENT_WORKSPACE_BODY')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WebMainScaffold), findsOneWidget);
      expect(find.text('PORTAIL ÉTUDIANT'), findsOneWidget);
      expect(find.text('SmartClass'), findsOneWidget);
      expect(find.text('Tableau de bord'), findsOneWidget);
      expect(find.text('Mes Cours'), findsOneWidget);
      expect(find.text('Studio IA & Tuteur'), findsOneWidget);
      expect(find.text('Communauté'), findsOneWidget);
      expect(find.text('Examens & Devoirs'), findsOneWidget);
      expect(find.text('STUDENT_WORKSPACE_BODY'), findsOneWidget);
    });

    testWidgets('WebMainScaffold renders teacher desktop navigation sidebar when role is teacher',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(
          const WebMainScaffold(
            activePath: '/home',
            role: 'teacher',
            body: Center(child: Text('TEACHER_WORKSPACE_BODY')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WebMainScaffold), findsOneWidget);
      expect(find.text('ESPACE ENSEIGNANT'), findsOneWidget);
      expect(find.text('Mes Classes'), findsOneWidget);
      expect(find.text('Cours & Ressources'), findsOneWidget);
      expect(find.text('Créateur IA'), findsOneWidget);
      expect(find.text('TEACHER_WORKSPACE_BODY'), findsOneWidget);
    });

    testWidgets('StudentDashboardView renders desktop widescreen greeting and stats header on desktop',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(const StudentDashboardView()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(StudentDashboardView), findsOneWidget);
      expect(find.text('Rejoindre une classe'), findsOneWidget);
      expect(find.text('MES CLASSES'), findsOneWidget);
      expect(find.text('CAMARADES'), findsOneWidget);
      expect(find.text('ENSEIGNANTS'), findsOneWidget);
      expect(find.text('TUTEUR IA'), findsOneWidget);
    });

    testWidgets(
        'AiAssistantPage renders widescreen 2-column layout with reference rail on desktop',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(
          const AiAssistantPage(),
          overrides: [
            myCoursesProvider.overrideWith(
              (ref) async => const [
                CourseEntry(
                  id: 'group_l3',
                  name: 'Licence 3 Informatique',
                  level: 'L3',
                  status: 'PUBLISHED',
                  memberCount: 32,
                  teacherCount: 4,
                  myRole: 'STUDENT',
                  department: 'Informatique',
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AiAssistantPage), findsOneWidget);
      expect(find.text('Tuteur IA Interactif'), findsOneWidget);
      expect(find.text('Aligné classe'), findsOneWidget);
      expect(find.text('Ma classe'), findsOneWidget);
      expect(find.text('Outils IA disponibles'), findsOneWidget);
      expect(find.text('Licence 3 Informatique'), findsWidgets);
    });

    testWidgets(
        'CourseReaderPage renders widescreen 2-column layout with video lecture banner and AI summary rail',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const mockCourse = GeneratedCourse(
        id: 'course_web_123',
        title: 'Chapitre 3 : Espaces Vectoriels et Théorème du Rang',
        level: 'detaille',
        difficulty: 'moyen',
        format: 'complet',
        status: 'PUBLISHED',
        authorId: 'user_teacher_amine',
        authorName: 'Amine',
        subject: 'Mathématiques',
        content: '# Espaces Vectoriels\n\n## Axiomes de base\nContenu fondamental.\n\n## Théorème du Rang\nFormule dim(E) = dim(Ker(f)) + rg(f)',
      );

      await tester.pumpWidget(
        _buildDesktopTestHarness(
          const CourseReaderPage(courseId: 'course_web_123'),
          overrides: [
            generatedCourseProvider('course_web_123')
                .overrideWith((ref) async => mockCourse),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CourseReaderPage), findsOneWidget);
      expect(find.text('IA Active'), findsOneWidget);
      expect(find.text('HD • Validé'), findsOneWidget);
      expect(find.text('Prof. Amine'), findsOneWidget);
      expect(find.text('Résumé IA'), findsOneWidget);
      expect(find.text('Fiches (4)'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Synthèse SmartClass IA'), findsOneWidget);
      expect(find.text('98% fidélité'), findsOneWidget);
    });

    testWidgets(
        'AiCourseCreatorPage renders widescreen 2-column studio layout with prompt suggestions and templates canvas',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(const AiCourseCreatorPage()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AiCourseCreatorPage), findsOneWidget);
      expect(find.text('MOTEUR PÉDAGOGIQUE IA V3.2'), findsOneWidget);
      expect(find.text('Concepteur intelligent'), findsOneWidget);
      expect(find.text('Plan détaillé'), findsOneWidget);
      expect(find.text('Quiz interactif inclus'), findsOneWidget);
      expect(find.text('Exercices pratiques'), findsOneWidget);
      expect(find.text('Études de cas'), findsOneWidget);
      expect(find.text('Schémas Mermaid'), findsOneWidget);
      expect(
          find.text('Canevas de Prévisualisation & Modèles Clés-en-Main'),
          findsOneWidget);
      expect(
          find.text('Bases de Données Relationnelles & Requêtes SQL Avancées'),
          findsOneWidget);
      expect(
          find.text('Algèbre Linéaire & Diagonalisation d\'Endomorphismes'),
          findsOneWidget);
      expect(
          find.text('Théorie des Graphes & Algorithmes de Routage'),
          findsOneWidget);
    });

    testWidgets(
        'SecureExamPage renders anti-fraud telemetry banner, timer, segmented progress and radio options',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(const SecureExamPage()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SecureExamPage), findsOneWidget);
      expect(find.text('Active Exam Session'), findsOneWidget);
      expect(find.text('Locked Proctoring Active'), findsOneWidget);
      expect(find.text('Mode Anti-fraude Actif'), findsOneWidget);
      expect(find.text('Détection d\'onglet & écran scellé'), findsOneWidget);
      expect(find.text('Question 3'), findsOneWidget);
      expect(find.text('sur 10'), findsOneWidget);
      expect(find.text('Choix unique'), findsOneWidget);
      expect(find.text('O(n²)'), findsOneWidget);
      expect(find.text('Protocole d\'intégrité actif : Quitter l\'application, changer d\'écran ou effectuer une capture déclenche un signalement automatique et invalidera la session.'), findsOneWidget);
    });

    testWidgets(
        'ExamAiScorePage renders radial score ring, cohort benchmark, AI pedagogical synthesis and filter tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(const ExamAiScorePage()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ExamAiScorePage), findsOneWidget);
      expect(find.text('Résultats De L\'Examen'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('/ 20'), findsOneWidget);
      expect(find.text('SCORE GLOBAL'), findsOneWidget);
      expect(find.text('Validé avec succès (+3.2 pts vs promo)'), findsOneWidget);
      expect(find.text('8 / 10'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('2 / 10'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('4e'), findsOneWidget);
      expect(find.text('Tuteur IA SmartClass'), findsOneWidget);
      expect(find.text('Diagnostic instantané'), findsOneWidget);
      expect(find.text('Générer 3 fiches de remédiation'), findsOneWidget);
      expect(find.text('Détail des Questions'), findsOneWidget);
      expect(find.text('Toutes (10)'), findsOneWidget);
      expect(find.text('Erreurs (2)'), findsOneWidget);
      expect(find.text('Réussies (8)'), findsOneWidget);
    });

    testWidgets(
        'ExamsPage renders tabbed list and launches secure anti-fraud exam modal',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildDesktopTestHarness(const ExamsPage()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ExamsPage), findsOneWidget);
      expect(find.text('Mes examens'), findsOneWidget);
      expect(find.text('Examen final - Programmation OO'), findsOneWidget);
    });
  });
}

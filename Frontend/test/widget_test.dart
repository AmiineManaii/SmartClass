// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartclass/app/app.dart';
import 'package:smartclass/core/localization/app_localizations.dart';
import 'package:smartclass/features/home/presentation/widgets/student_dashboard_view.dart';
import 'package:smartclass/features/ai_assistant/presentation/pages/ai_revision_page.dart';
import 'package:smartclass/features/ai_assistant/presentation/pages/ai_quiz_page.dart';
import 'package:smartclass/features/splash/presentation/pages/splash_page.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SmartClassApp()));

    // Verify that the app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('StudentDashboardView renders with proper constraints and no BoxConstraints error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: Scaffold(
            body: StudentDashboardView(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(StudentDashboardView), findsOneWidget);
  });

  testWidgets('StudentDashboardView renders without overflow on narrow 320px viewport', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: Scaffold(
            body: StudentDashboardView(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(StudentDashboardView), findsOneWidget);
  });

  testWidgets('StudentDashboardView renders top bar, logo, and sections cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: Scaffold(
            body: StudentDashboardView(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(StudentDashboardView), findsOneWidget);
    expect(find.text('Accueil'), findsWidgets);
    expect(find.text('SMARTCLASS'), findsWidgets);
  });

  testWidgets('StudentDashboardView renders cleanly in English (en)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(
            body: StudentDashboardView(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(StudentDashboardView), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('SMARTCLASS'), findsWidgets);
  });

  testWidgets('AppLocalizations provides correct translations for both locales', (WidgetTester tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(capturedContext.tr('home'), 'Accueil');
    expect(capturedContext.tr('my_courses'), 'Mes cours');
    expect(capturedContext.tr('ai_revision_title'), 'Générer Mes Révisions');
    expect(capturedContext.tr('ai_quiz_title'), 'S\'Entraîner Avec L\'IA');

    // Test English
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(capturedContext.tr('home'), 'Home');
    expect(capturedContext.tr('my_courses'), 'My courses');
    expect(capturedContext.tr('ai_revision_title'), 'Generate My Revisions');
    expect(capturedContext.tr('ai_quiz_title'), 'Practice with AI');
  });

  testWidgets('AiRevisionPage renders cleanly with no overflow on mobile viewport', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: AiRevisionPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AiRevisionPage), findsOneWidget);
    expect(find.text('Générer Mes Révisions'), findsOneWidget);
    expect(find.text('Assistant de Révision IA'), findsOneWidget);
  });

  testWidgets('AiQuizPage renders cleanly with no overflow on mobile viewport', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: AiQuizPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AiQuizPage), findsOneWidget);
    expect(find.text("S'Entraîner Avec L'IA ✨"), findsOneWidget);
  });

  testWidgets('AiRevisionPage renders cleanly on ultra-narrow 320px viewport', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: AiRevisionPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AiRevisionPage), findsOneWidget);
    expect(find.text('Générer Mes Révisions'), findsOneWidget);
  });

  testWidgets('AiQuizPage renders cleanly on ultra-narrow 320px viewport', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: AiQuizPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AiQuizPage), findsOneWidget);
    expect(find.text("S'Entraîner Avec L'IA ✨"), findsOneWidget);
  });

  testWidgets('SplashPage renders with full animated emblem and branding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: SplashPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('Smart'), findsOneWidget);
    expect(find.text('Class'), findsOneWidget);
    expect(find.text('Ignorer'), findsOneWidget);
  });

  testWidgets('SplashPage renders cleanly on ultra-narrow 320px viewport with no overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: SplashPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('Smart'), findsOneWidget);
    expect(find.text('Class'), findsOneWidget);
  });
}
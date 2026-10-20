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

Widget _buildDesktopTestHarness(Widget child) {
  return ProviderScope(
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
      expect(find.text('PERSONNALISATION DU RÔLE'), findsOneWidget);
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
      expect(find.text('FINALISATION DU PROFIL'), findsOneWidget);
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
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartclass/core/widgets/smart_loader.dart';

void main() {
  group('SmartLoader Tests', () {
    testWidgets('SmartLoader.small renders with compact size and custom color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SmartLoader.small(
                color: Colors.red,
                customSize: 24,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SmartLoader), findsOneWidget);
      // Pump a frame to verify animation tick
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('SmartLoader.medium renders with message and bouncing dots',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SmartLoader.medium(
                message: 'Chargement en cours',
                subMessage: 'Veuillez patienter',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SmartLoader), findsOneWidget);
      expect(find.text('Chargement en cours'), findsOneWidget);
      expect(find.text('Veuillez patienter'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('SmartLoader.large renders with orbital animation and emblem fallback',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SmartLoader.large(
                message: 'Préparation du cours',
                showEmblem: false,
                icon: Icons.auto_awesome,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SmartLoader), findsOneWidget);
      expect(find.text('Préparation du cours'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('SmartPageLoader renders centered card presentation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartPageLoader(
              message: 'Chargement de la page',
              subMessage: 'Initialisation des modules...',
            ),
          ),
        ),
      );

      expect(find.byType(SmartPageLoader), findsOneWidget);
      expect(find.text('Chargement de la page'), findsOneWidget);
      expect(find.text('Initialisation des modules...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}

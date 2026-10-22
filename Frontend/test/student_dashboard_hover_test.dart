import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartclass/core/localization/app_localizations.dart';
import 'package:smartclass/features/home/application/providers/student_dashboard_provider.dart';
import 'package:smartclass/features/home/presentation/widgets/student_dashboard_view.dart';

void main() {
  testWidgets('class card hover keeps transforms finite', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myGroupsProvider.overrideWith(
            (ref) async => const [
              {
                'id': 'g1',
                'name': 'Licence 3 Informatique',
                'level': 'L3',
                'department': 'Informatique',
                'status': 'PUBLISHED',
                'memberCount': 32,
                'teacherCount': 4,
                'myRole': 'STUDENT',
                'mySubjects': <String>[],
              },
            ],
          ),
          studentDayTimetableProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: const Scaffold(body: StudentDashboardView()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    final title = find.text('Licence 3 Informatique');
    expect(title, findsWidgets);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(10, 10));
    await tester.pump();

    final center = tester.getCenter(title.first);
    for (var i = 0; i < 20; i++) {
      await gesture.moveTo(center + Offset(i.toDouble(), i.toDouble()));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull, reason: 'hover tick $i');
    }

    await gesture.removePointer();
  });
}

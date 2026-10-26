import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartclass/app/app_providers.dart';
import 'package:smartclass/core/localization/app_localizations.dart';
import 'package:smartclass/features/videoconference/application/videoconference_providers.dart';
import 'package:smartclass/features/videoconference/domain/entities/session_event.dart';
import 'package:smartclass/features/videoconference/domain/entities/video_session.dart';
import 'package:smartclass/features/videoconference/domain/repositories/videoconference_repository.dart';
import 'package:smartclass/features/videoconference/presentation/pages/videoconference_page.dart';

class _FakeAuthNotifier extends StateNotifier<AsyncValue<AuthState>>
    implements AuthNotifier {
  _FakeAuthNotifier(String role)
      : super(AsyncValue.data(AuthState(
          isAuthenticated: true,
          role: role,
        )));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeVideoconferenceRepository implements VideoconferenceRepository {
  final List<VideoSession> sessions;

  _FakeVideoconferenceRepository({this.sessions = const []});

  @override
  Future<PaginatedSessions> listSessions({
    String? status,
    String? classGroupId,
    String? scope,
    int page = 1,
    int limit = 20,
  }) async {
    return PaginatedSessions(
      items: sessions,
      total: sessions.length,
      page: page,
      limit: limit,
    );
  }

  @override
  Stream<SessionEvent> streamEvents() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('VideoconferencePage displays 3 tabs and empty states for teacher',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier('TEACHER')),
          videoconferenceRepositoryProvider
              .overrideWithValue(_FakeVideoconferenceRepository()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: VideoconferencePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 3 tabs exist (icon-only segmented pill tabs)
    expect(find.byIcon(Icons.sensors_rounded), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    expect(find.byIcon(Icons.history_rounded), findsOneWidget);

    // Verify teacher action button is present
    expect(find.text('Lancer un direct'), findsAtLeastNWidgets(1));

    // Verify empty state on active tab
    expect(find.text('Aucun direct en cours'), findsOneWidget);
  });

  testWidgets('VideoconferencePage hides schedule button for students',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier('STUDENT')),
          videoconferenceRepositoryProvider
              .overrideWithValue(_FakeVideoconferenceRepository()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: VideoconferencePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify student cannot see schedule session button
    expect(find.text('Programmer une session'), findsNothing);
  });

  testWidgets('VideoconferencePage displays session cards when items exist',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockSession = VideoSession(
      id: 's-101',
      classGroupId: 'cg-1',
      className: 'L3 Informatique',
      subject: 'Mathématiques',
      title: 'Algèbre Linéaire',
      startsAt: DateTime.now().subtract(const Duration(minutes: 10)),
      endsAt: DateTime.now().add(const Duration(minutes: 50)),
      status: VideoSessionStatus.inProgress,
      hostName: 'Prof. Turing',
      participantCount: 15,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier('STUDENT')),
          videoconferenceRepositoryProvider.overrideWithValue(
            _FakeVideoconferenceRepository(sessions: [mockSession]),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: VideoconferencePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Algèbre Linéaire'), findsOneWidget);
    expect(find.text('L3 Informatique'), findsOneWidget);
    expect(find.text('Prof. Turing'), findsOneWidget);
  });
}

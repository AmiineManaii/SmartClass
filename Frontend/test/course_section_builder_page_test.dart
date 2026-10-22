import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartclass/core/localization/app_localizations.dart';
import 'package:smartclass/core/network/api_client.dart';
import 'package:smartclass/core/network/api_exception.dart';
import 'package:smartclass/core/network/token_storage.dart';
import 'package:smartclass/features/courses/application/providers/ai_course_options_provider.dart';
import 'package:smartclass/features/courses/application/providers/course_section_build_provider.dart';
import 'package:smartclass/features/courses/domain/entities/course_section.dart';
import 'package:smartclass/features/courses/infrastructure/datasources/ai_course_remote_datasource.dart';
import 'package:smartclass/features/courses/infrastructure/datasources/course_section_remote_datasource.dart';
import 'package:smartclass/features/courses/presentation/pages/course_section_builder_page.dart';

class _FakeTokens extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'test';

  @override
  Future<String?> readRefreshToken() async => 'test';
}

ApiClient _api() => ApiClient(tokens: _FakeTokens());

Map<String, dynamic> _sectionJson({
  String key = 'sec-1',
  String status = 'PENDING',
  String? content,
  int order = 0,
}) {
  return {
    'id': 'id-$key',
    'courseId': 'c1',
    'sectionKey': key,
    'title': 'Chapitre $key',
    'description': 'Objectifs de $key',
    'keyTopics': ['notion-a'],
    'content': content,
    'order': order,
    'estimatedMinutes': 15,
    'status': status,
  };
}

class _FakeSections extends CourseSectionRemoteDataSource {
  _FakeSections({this.fail = false}) : super(_api());

  bool fail;
  bool imageUnavailable = false;

  @override
  Future<CourseBuildData> getBuild(String courseId) async {
    if (fail) {
      throw const ApiException(message: 'load boom');
    }
    return CourseBuildData(
      course: const CourseBuildCourse(
        id: 'c1',
        title: 'Cours test',
        subject: 'Maths',
        level: 'equilibre',
        difficulty: 'moyen',
        format: 'resume',
      ),
      sections: [
        CourseSectionEntry.fromJson(_sectionJson(key: 'sec-1', order: 0)),
        CourseSectionEntry.fromJson(_sectionJson(key: 'sec-2', order: 1)),
      ],
      initializedFromOutline: true,
    );
  }

  @override
  Future<CourseSectionEntry> validateSection({
    required String courseId,
    required String sectionKey,
  }) async {
    return CourseSectionEntry.fromJson(
      _sectionJson(
        key: sectionKey,
        status: 'VALIDATED',
        content: '# Généré\n\nContenu streaming.',
      ),
    );
  }

  @override
  Future<SectionImageJob> startSectionImageJob({
    required String courseId,
    required String sectionKey,
    String kind = 'FIGURE',
  }) async {
    if (imageUnavailable) {
      throw const ApiException(
        code: 'IMAGE_SERVICE_UNAVAILABLE',
        message: 'ComfyUI is not wired yet',
      );
    }
    return const SectionImageJob(
      id: 'job-1',
      status: SectionImageJobStatus.succeeded,
      imageUrl: 'http://localhost:8188/img.png',
      prompt: 'prompt',
      provider: 'comfyui',
    );
  }
}

class _StreamAi extends AiCourseRemoteDataSource {
  _StreamAi() : super(_api());

  @override
  Future<void> streamCourse({
    required String path,
    required Map<String, dynamic> fields,
    MultipartFile? file,
    required void Function(String delta) onDelta,
    void Function(String phase)? onPhase,
    required void Function(Map<String, dynamic> meta) onDone,
    required void Function(ApiException error) onError,
    CancelToken? cancelToken,
  }) async {
    final sectionKey = fields['sectionKey']?.toString() ?? '';
    onPhase?.call('memory');
    onDelta('# Généré\n');
    onPhase?.call('generating');
    onDelta('Contenu streaming.');
    onDone({
      'section': _sectionJson(
        key: sectionKey,
        status: 'GENERATED',
        content: '# Généré\n\nContenu streaming.',
      ),
      'model': 'fake-model',
    });
  }
}

Future<void> _pumpBuilder(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CourseSectionBuilderPage(courseId: 'c1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _container({_FakeSections? sections}) {
  final container = ProviderContainer(
    overrides: [
      courseSectionRemoteDataSourceProvider.overrideWithValue(
        sections ?? _FakeSections(),
      ),
      aiCourseRemoteDataSourceProvider.overrideWithValue(_StreamAi()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  testWidgets('renders the sections with status chips and the gate banner', (
    tester,
  ) async {
    await _pumpBuilder(tester, _container());

    expect(find.text('SECTION 01'), findsOneWidget);
    expect(find.text('SECTION 02'), findsOneWidget);
    expect(find.text('À générer'), findsNWidgets(2));
    expect(find.textContaining('2 section(s) restante(s)'), findsOneWidget);
    expect(find.text('Chapitre sec-1'), findsOneWidget);
    expect(find.text('notion-a'), findsNWidgets(2));
  });

  testWidgets('generate then validate flips chips and shows the snack', (
    tester,
  ) async {
    await _pumpBuilder(tester, _container());

    await tester.tap(find.text('Générer').first);
    await tester.pumpAndSettle();

    // Chapter 1 moved to review, chapter 2 untouched.
    expect(find.text('À valider'), findsOneWidget);
    expect(find.text('À générer'), findsOneWidget);
    expect(find.text('Aperçu du contenu'), findsOneWidget);

    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('Validée'), findsOneWidget);
    expect(find.textContaining('Plus que 1'), findsOneWidget);
    expect(find.textContaining('1 section(s) restante(s)'), findsOneWidget);
  });

  testWidgets('load failure shows the retry view which recovers', (
    tester,
  ) async {
    final sections = _FakeSections(fail: true);
    await _pumpBuilder(tester, _container(sections: sections));

    expect(
      find.text('Impossible de charger les sections du cours.'),
      findsOneWidget,
    );

    sections.fail = false;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('SECTION 01'), findsOneWidget);
    expect(
      find.text('Impossible de charger les sections du cours.'),
      findsNothing,
    );
  });

  testWidgets('the image action offers ComfyUI and web search', (tester) async {
    await _pumpBuilder(tester, _container());

    await tester.tap(find.byTooltip('Illustration de la section').first);
    await tester.pumpAndSettle();

    expect(find.text('Illustration de la section'), findsOneWidget);
    expect(find.textContaining('ComfyUI'), findsOneWidget);
    expect(find.text('Chercher 5 images sur le web'), findsOneWidget);
  });

  testWidgets('the ComfyUI 503 points the teacher to web search', (
    tester,
  ) async {
    final sections = _FakeSections()..imageUnavailable = true;
    await _pumpBuilder(tester, _container(sections: sections));

    await tester.tap(find.byTooltip('Illustration de la section').first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ComfyUI'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ComfyUI est indisponible'), findsOneWidget);
  });

  testWidgets('a generated illustration shows the image explanation caption', (
    tester,
  ) async {
    final sections = _FakeSections();
    await _pumpBuilder(tester, _container(sections: sections));

    await tester.tap(find.byTooltip('Illustration de la section').first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ComfyUI'));
    await tester.pumpAndSettle();

    expect(find.text('Illustration IA'), findsOneWidget);
    expect(find.text('Explication de l\u2019image'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Objectifs de sec-1'),
      ),
      findsOneWidget,
    );
    expect(find.text('prompt'), findsOneWidget);
    expect(find.text('comfyui'), findsOneWidget);
    expect(find.text('Insérer dans la section'), findsOneWidget);
  });
}

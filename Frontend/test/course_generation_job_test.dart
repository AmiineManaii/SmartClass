import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartclass/core/network/api_client.dart';
import 'package:smartclass/core/network/api_exception.dart';
import 'package:smartclass/core/network/token_storage.dart';
import 'package:smartclass/features/courses/application/providers/ai_course_options_provider.dart';
import 'package:smartclass/features/courses/application/providers/course_generation_job_provider.dart';
import 'package:smartclass/features/courses/application/providers/courses_provider.dart';
import 'package:smartclass/features/courses/domain/entities/course_outline.dart';
import 'package:smartclass/features/courses/domain/entities/generated_course.dart';
import 'package:smartclass/features/courses/infrastructure/datasources/ai_course_remote_datasource.dart';
import 'package:smartclass/features/courses/infrastructure/datasources/generated_courses_remote_datasource.dart';

class _FakeTokens extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'test';

  @override
  Future<String?> readRefreshToken() async => 'test';
}

ApiClient _api() => ApiClient(tokens: _FakeTokens());

class _FakeAi extends AiCourseRemoteDataSource {
  _FakeAi({this.fail = false}) : super(_api());

  final bool fail;

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
    if (fail) {
      onError(const ApiException(message: 'boom'));
      return;
    }
    onPhase?.call('extracting');
    onDelta('# Titre\n');
    onPhase?.call('generating');
    onDelta('Contenu.');
    onDone({'model': 'test-model'});
  }

  @override
  Future<Map<String, dynamic>> status() async =>
      {'available': true, 'model': 'test-model'};
}

class _FakeGen extends GeneratedCoursesRemoteDataSource {
  _FakeGen() : super(_api());

  int saves = 0;
  final deleted = <String>[];
  CourseOutline? lastOutline;

  @override
  Future<GeneratedCourse> saveDraft({
    required String title,
    String? subject,
    required String content,
    required String level,
    required String difficulty,
    required String format,
    CourseOutline? outline,
  }) async {
    saves += 1;
    lastOutline = outline;
    return GeneratedCourse(
      id: 'c$saves',
      title: title,
      subject: subject,
      level: level,
      difficulty: difficulty,
      format: format,
      status: 'DRAFT',
      authorId: 't1',
      authorName: 'Prof',
      content: content,
    );
  }

  @override
  Future<void> deleteCourse(String id) async {
    deleted.add(id);
  }
}

const _params = GenerationJobParams(
  mode: 'topic',
  subject: 'un sujet de test assez long',
  level: 'concis',
  difficulty: 'moyen',
  format: 'resume',
  examples: true,
  mermaid: true,
  webImages: false,
  webSearch: false,
  thinking: false,
);

ProviderContainer _container({bool fail = false, _FakeGen? gen}) {
  final container = ProviderContainer(
    overrides: [
      aiCourseRemoteDataSourceProvider.overrideWithValue(_FakeAi(fail: fail)),
      generatedCoursesDataSourceProvider.overrideWithValue(gen ?? _FakeGen()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts idle and cancel is a no-op', () {
    final container = _container();
    expect(
      container.read(courseGenerationJobProvider).status,
      GenerationJobStatus.idle,
    );
    container.read(courseGenerationJobProvider.notifier).cancel();
    expect(
      container.read(courseGenerationJobProvider).status,
      GenerationJobStatus.idle,
    );
  });

  test('streams in background and auto-saves the draft', () async {
    final container = _container();
    await container
        .read(courseGenerationJobProvider.notifier)
        .start(_params);
    // Auto-save continues after the stream future resolves.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final state = container.read(courseGenerationJobProvider);
    expect(state.status, GenerationJobStatus.done);
    expect(state.content, '# Titre\nContenu.');
    expect(state.phase, 'generating');
    expect(state.courseId, 'c1');
    expect(state.savedContent, state.content);
  });

  test('edited text re-saves and drops the replaced auto-draft', () async {
    final gen = _FakeGen();
    final container = _container(gen: gen);
    final notifier = container.read(courseGenerationJobProvider.notifier);
    await notifier.start(_params);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await notifier.saveCurrentEdits('# Titre\nContenu édité.');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final state = container.read(courseGenerationJobProvider);
    expect(state.courseId, 'c2');
    expect(state.savedContent, '# Titre\nContenu édité.');
    expect(gen.deleted, ['c1']);
  });

  test('stream failure lands in error state (no fake offline)', () async {
    final container = _container(fail: true);
    await container
        .read(courseGenerationJobProvider.notifier)
        .start(_params);
    final state = container.read(courseGenerationJobProvider);
    expect(state.status, GenerationJobStatus.error);
    expect(state.error, isA<ApiException>());
    expect(state.courseId, isNull);
  });
}

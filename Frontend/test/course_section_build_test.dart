import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartclass/core/network/api_client.dart';
import 'package:smartclass/core/network/api_exception.dart';
import 'package:smartclass/core/network/token_storage.dart';
import 'package:smartclass/features/courses/application/providers/ai_course_options_provider.dart';
import 'package:smartclass/features/courses/application/providers/course_section_build_provider.dart';
import 'package:smartclass/features/courses/domain/entities/course_section.dart';
import 'package:smartclass/features/courses/infrastructure/datasources/ai_course_remote_datasource.dart';
import 'package:smartclass/features/courses/infrastructure/datasources/course_section_remote_datasource.dart';

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
  final validations = <String>[];
  final imageSearches = <String>[];
  final imageApplies = <String>[];
  final imageJobStarts = <String>[];
  int imageJobPolls = 0;
  bool imageUnavailable = false;
  bool imageJobFailure = false;

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
    validations.add(sectionKey);
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
    imageJobStarts.add(sectionKey);
    return const SectionImageJob(
      id: 'job-1',
      status: SectionImageJobStatus.running,
    );
  }

  @override
  Future<SectionImageJob> getSectionImageJob(String jobId) async {
    imageJobPolls++;
    if (imageJobFailure) {
      return const SectionImageJob(
        id: 'job-1',
        status: SectionImageJobStatus.failed,
        errorCode: 'IMAGE_SERVICE_UNAVAILABLE',
        errorMessage: 'ComfyUI is down',
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

  @override
  Future<List<SectionImageCandidate>> searchSectionImages({
    required String courseId,
    required String sectionKey,
    String? query,
  }) async {
    imageSearches.add(sectionKey);
    return [
      const SectionImageCandidate(
        title: 'Sorting',
        url: 'https://example.com/sorting.png',
        caption: 'Tri rapide',
        source: 'wikimedia',
      ),
    ];
  }

  @override
  Future<CourseSectionEntry> applySectionImage({
    required String courseId,
    required String sectionKey,
    required String imageUrl,
    String? caption,
  }) async {
    imageApplies.add('$sectionKey:$imageUrl:$caption');
    return CourseSectionEntry.fromJson(
      _sectionJson(
        key: sectionKey,
        status: 'GENERATED',
        content: '# Généré\n\nContenu streaming.\n\n![$caption]($imageUrl)',
      ),
    );
  }
}

/// SSE fake: emits phase + deltas, then (optionally) waits on [hold] before
/// finishing — lets a test inspect mid-flight state or cancel.
class _StreamAi extends AiCourseRemoteDataSource {
  _StreamAi({this.hold, this.fail = false}) : super(_api());

  final Completer<void>? hold;
  final bool fail;
  final calls = <String>[];

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
    calls.add(sectionKey);
    onPhase?.call('memory');
    onDelta('# Généré\n');
    onPhase?.call('generating');
    onDelta('Contenu streaming.');

    final held = hold;
    if (held != null) {
      if (cancelToken != null) {
        await Future.any<void>([
          held.future.then((_) {}),
          cancelToken.whenCancel.then((_) {}),
        ]);
      } else {
        await held.future;
      }
    }
    if (cancelToken?.isCancelled ?? false) {
      onError(
        const ApiException(code: 'REQUEST_CANCELLED', message: 'cancelled'),
      );
      return;
    }
    if (fail) {
      onError(
        const ApiException(code: 'AI_MODEL_UNAVAILABLE', message: 'boom'),
      );
      return;
    }
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

ProviderContainer _container({_FakeSections? sections, _StreamAi? ai}) {
  final container = ProviderContainer(
    overrides: [
      courseSectionRemoteDataSourceProvider.overrideWithValue(
        sections ?? _FakeSections(),
      ),
      aiCourseRemoteDataSourceProvider.overrideWithValue(ai ?? _StreamAi()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

const _buildId = 'c1';

void main() {
  test('load maps the build payload into state', () async {
    final container = _container();
    final notifier = container.read(
      courseSectionBuildProvider(_buildId).notifier,
    );

    await notifier.load();
    final state = container.read(courseSectionBuildProvider(_buildId));

    expect(state.loading, isFalse);
    expect(state.error, isNull);
    expect(state.course?.title, 'Cours test');
    expect(state.sections.map((section) => section.sectionKey), [
      'sec-1',
      'sec-2',
    ]);
    expect(state.validatedCount, 0);
    expect(state.remainingToValidate, 2);
  });

  test('load failure lands in error state with no sections', () async {
    final container = _container(sections: _FakeSections(fail: true));
    final notifier = container.read(
      courseSectionBuildProvider(_buildId).notifier,
    );

    await notifier.load();
    final state = container.read(courseSectionBuildProvider(_buildId));

    expect(state.error, isA<ApiException>());
    expect(state.sections, isEmpty);
    expect(state.loading, isFalse);
  });

  test('generate streams then swaps the row with the saved section', () async {
    final ai = _StreamAi();
    final container = _container(ai: ai);
    final notifier = container.read(
      courseSectionBuildProvider(_buildId).notifier,
    );
    await notifier.load();

    await notifier.generate(sectionKey: 'sec-1', regenerate: false);
    final state = container.read(courseSectionBuildProvider(_buildId));

    expect(ai.calls, ['sec-1']);
    expect(state.streamingKey, isNull);
    expect(state.streamingText, isEmpty);
    expect(state.streamError, isNull);
    final section = state.section('sec-1');
    expect(section?.status, CourseSectionStatus.generated);
    expect(section?.content, contains('Contenu streaming.'));
    // The untouched chapter stays PENDING.
    expect(state.section('sec-2')?.status, CourseSectionStatus.pending);
  });

  test('mid-flight state exposes phase and accumulated text', () async {
    final hold = Completer<void>();
    final container = _container(ai: _StreamAi(hold: hold));
    final notifier = container.read(
      courseSectionBuildProvider(_buildId).notifier,
    );
    await notifier.load();

    final running = notifier.generate(sectionKey: 'sec-1', regenerate: false);
    await Future<void>.delayed(Duration.zero);
    var state = container.read(courseSectionBuildProvider(_buildId));

    expect(state.streamingKey, 'sec-1');
    expect(state.streamingPhase, 'generating');
    expect(state.streamingText, contains('Contenu streaming.'));
    expect(state.section('sec-1')?.status, CourseSectionStatus.pending);

    hold.complete();
    await running;
    state = container.read(courseSectionBuildProvider(_buildId));
    expect(state.streamingKey, isNull);
    expect(state.section('sec-1')?.status, CourseSectionStatus.generated);
  });

  test('cancel settles the stream without an error', () async {
    final hold = Completer<void>(); // never completed: stream stays open
    final container = _container(ai: _StreamAi(hold: hold));
    final notifier = container.read(
      courseSectionBuildProvider(_buildId).notifier,
    );
    await notifier.load();

    final running = notifier.generate(sectionKey: 'sec-1', regenerate: false);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(courseSectionBuildProvider(_buildId)).streamingKey,
      'sec-1',
    );

    notifier.cancel();
    await running;
    final state = container.read(courseSectionBuildProvider(_buildId));

    expect(state.streamingKey, isNull);
    expect(state.streamError, isNull);
    expect(state.section('sec-1')?.status, CourseSectionStatus.pending);
  });

  test('stream failure lands in streamError and is acknowledgeable', () async {
    final container = _container(ai: _StreamAi(fail: true));
    final notifier = container.read(
      courseSectionBuildProvider(_buildId).notifier,
    );
    await notifier.load();

    await notifier.generate(sectionKey: 'sec-1', regenerate: false);
    var state = container.read(courseSectionBuildProvider(_buildId));

    expect(state.streamingKey, isNull);
    expect(state.streamError, isA<ApiException>());
    expect(state.section('sec-1')?.status, CourseSectionStatus.pending);

    notifier.acknowledgeStreamError();
    state = container.read(courseSectionBuildProvider(_buildId));
    expect(state.streamError, isNull);
  });

  test('a second generate while streaming is ignored', () async {
    final hold = Completer<void>();
    final ai = _StreamAi(hold: hold);
    final container = _container(ai: ai);
    final notifier = container.read(
      courseSectionBuildProvider(_buildId).notifier,
    );
    await notifier.load();

    final first = notifier.generate(sectionKey: 'sec-1', regenerate: false);
    await Future<void>.delayed(Duration.zero);
    await notifier.generate(sectionKey: 'sec-2', regenerate: false);
    expect(ai.calls, ['sec-1']);

    hold.complete();
    await first;
    final state = container.read(courseSectionBuildProvider(_buildId));
    expect(state.section('sec-1')?.status, CourseSectionStatus.generated);
    expect(state.section('sec-2')?.status, CourseSectionStatus.pending);
  });

  test('a validated section never regenerates silently', () async {
    final ai = _StreamAi();
    final container = _container(ai: ai);
    final notifier = container.read(
      courseSectionBuildProvider(_buildId).notifier,
    );
    await notifier.load();
    await notifier.generate(sectionKey: 'sec-1', regenerate: false);
    await notifier.validate('sec-1');
    expect(
      container
          .read(courseSectionBuildProvider(_buildId))
          .section('sec-1')
          ?.status,
      CourseSectionStatus.validated,
    );

    await notifier.generate(sectionKey: 'sec-1', regenerate: false);
    expect(ai.calls, ['sec-1']); // no second call
  });

  test(
    'validate flips the section and decrements the remaining count',
    () async {
      final sections = _FakeSections();
      final container = _container(sections: sections);
      final notifier = container.read(
        courseSectionBuildProvider(_buildId).notifier,
      );
      await notifier.load();
      await notifier.generate(sectionKey: 'sec-1', regenerate: false);

      await notifier.validate('sec-1');
      var state = container.read(courseSectionBuildProvider(_buildId));
      expect(state.section('sec-1')?.status, CourseSectionStatus.validated);
      expect(state.remainingToValidate, 1);
      expect(sections.validations, ['sec-1']);

      await notifier.validate('sec-2');
      state = container.read(courseSectionBuildProvider(_buildId));
      expect(state.remainingToValidate, 0);
      expect(state.validatedCount, 2);
    },
  );

  test('image generation starts a job and polls it to completion', () async {
    final sections = _FakeSections();
    final container = _container(sections: sections);
    final notifier = container.read(
      courseSectionBuildProvider(_buildId).notifier,
    );
    await notifier.load();

    final result = await notifier.generateSectionImage('sec-1');

    expect(sections.imageJobStarts, ['sec-1']);
    expect(sections.imageJobPolls, 1);
    expect(result['imageUrl'], 'http://localhost:8188/img.png');
    final state = container.read(courseSectionBuildProvider(_buildId));
    expect(state.imageJob('sec-1')?.isSucceeded, isTrue);

    await notifier.generateSectionImage('sec-1');
    expect(sections.imageJobStarts, ['sec-1']);
    expect(sections.imageJobPolls, 1);
  });

  test('a failed job surfaces its error code to the caller', () async {
    final sections = _FakeSections()..imageJobFailure = true;
    final container = _container(sections: sections);
    final notifier = container.read(
      courseSectionBuildProvider(_buildId).notifier,
    );
    await notifier.load();

    await expectLater(
      notifier.generateSectionImage('sec-1'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          'IMAGE_SERVICE_UNAVAILABLE',
        ),
      ),
    );
    final state = container.read(courseSectionBuildProvider(_buildId));
    expect(state.imageJob('sec-1')?.status, SectionImageJobStatus.failed);
  });

  test('image generation surfaces the 503 stub to the caller', () async {
    final sections = _FakeSections()..imageUnavailable = true;
    final container = _container(sections: sections);
    final notifier = container.read(
      courseSectionBuildProvider(_buildId).notifier,
    );
    await notifier.load();

    await expectLater(
      notifier.generateSectionImage('sec-1'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          'IMAGE_SERVICE_UNAVAILABLE',
        ),
      ),
    );
  });

  test('web image search delegates to the datasource', () async {
    final sections = _FakeSections();
    final container = _container(sections: sections);
    final notifier = container.read(
      courseSectionBuildProvider(_buildId).notifier,
    );
    await notifier.load();

    final images = await notifier.searchSectionImages(
      'sec-1',
      query: 'quick sort',
    );

    expect(sections.imageSearches, ['sec-1']);
    expect(images, hasLength(1));
    expect(images.single.url, 'https://example.com/sorting.png');
  });

  test('applying an image swaps the section row in place', () async {
    final sections = _FakeSections();
    final container = _container(sections: sections);
    final notifier = container.read(
      courseSectionBuildProvider(_buildId).notifier,
    );
    await notifier.load();

    final updated = await notifier.applySectionImage(
      sectionKey: 'sec-1',
      imageUrl: 'https://example.com/sorting.png',
      caption: 'Tri rapide',
    );

    final state = container.read(courseSectionBuildProvider(_buildId));
    expect(updated.status, CourseSectionStatus.generated);
    expect(
      state.section('sec-1')?.content,
      contains('![Tri rapide](https://example.com/sorting.png)'),
    );
    expect(sections.imageApplies, [
      'sec-1:https://example.com/sorting.png:Tri rapide',
    ]);
  });
}

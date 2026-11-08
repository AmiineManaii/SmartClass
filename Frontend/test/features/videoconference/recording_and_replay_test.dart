import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartclass/core/localization/app_localizations.dart';
import 'package:smartclass/features/videoconference/application/recording_providers.dart';
import 'package:smartclass/features/videoconference/domain/entities/recording_models.dart';
import 'package:smartclass/features/videoconference/presentation/widgets/interactive_replay_player.dart';
import 'package:smartclass/features/videoconference/presentation/widgets/lesson_ai_tutor_panel.dart';
import 'package:smartclass/features/videoconference/presentation/widgets/synchronized_transcript_panel.dart';

void main() {
  group('Recording & Replay Domain Models', () {
    test('parses TeacherReviewWorkspaceEntity and LessonPackageEntity', () {
      final json = {
        'sessionId': 'sess-101',
        'sessionTitle': 'Architecture Microservices',
        'recording': {
          'id': 'rec-1',
          'sessionId': 'sess-101',
          'status': 'READY',
          'durationSeconds': 900,
          'streamUrl': '/api/v1/videoconference/sess-101/recordings/rec-1/stream',
        },
        'transcript': {
          'id': 'tr-1',
          'language': 'fr',
          'fullText': 'Bonjour et bienvenue dans ce cours.',
          'wordCount': 6,
          'segments': [
            {
              'index': 0,
              'startSec': 0.0,
              'endSec': 30.0,
              'text': 'Bonjour et bienvenue dans ce cours.',
              'speaker': 'Prof. Amine',
            },
            {
              'index': 1,
              'startSec': 30.0,
              'endSec': 95.0,
              'text': 'Nous abordons les patterns de résilience.',
              'speaker': 'Prof. Amine',
            },
          ],
        },
        'lessonPackage': {
          'id': 'pkg-1',
          'sessionId': 'sess-101',
          'status': 'READY_FOR_REVIEW',
          'title': 'Architecture Microservices — Synthèse',
          'shortSummary': 'Introduction aux microservices.',
          'detailedSummary': 'Analyse approfondie des patterns distribués.',
          'keyTakeaways': ['Circuit Breaker', 'Event Sourcing'],
          'structuredMarkdown': '# Chapitre 1\nContenu structuré.',
          'glossary': [
            {'term': 'Idempotence', 'definition': 'Même effet après N appels.'},
          ],
          'chapters': [
            {
              'id': 'ch-1',
              'chapterIndex': 0,
              'title': 'Introduction',
              'summary': 'Bases architecturales',
              'startSec': 0,
              'endSec': 450,
              'keyConcepts': ['Couplage faible'],
            },
          ],
          'quizQuestions': [
            {
              'question': 'Quel pattern évite les pannes en cascade ?',
              'options': ['Singleton', 'Circuit Breaker', 'Factory', 'Adapter'],
              'correctIndex': 1,
              'explanation': 'Le Circuit Breaker isole le service défaillant.',
            },
          ],
          'flashcards': [
            {
              'front': 'Définir Idempotence',
              'back': 'Propriété d\'une opération répétable sans effet de bord.',
            },
          ],
          'qualityScore': 0.94,
          'currentVersion': 2,
        },
      };

      final workspace = TeacherReviewWorkspaceEntity.fromJson(json);
      expect(workspace.sessionId, 'sess-101');
      expect(workspace.recording?.isReady, isTrue);
      expect(workspace.transcript?.segments.length, 2);
      expect(workspace.lessonPackage?.isReadyForReview, isTrue);
      expect(workspace.lessonPackage?.chapters.first.formattedRange, '00:00 - 07:30');
      expect(workspace.lessonPackage?.quizQuestions.first.correctIndex, 1);
    });
  });

  group('Synchronized Replay & Transcript Widgets', () {
    testWidgets('clicking transcript segment seeks replay position provider',
        (tester) async {
      final transcript = RecordingTranscriptEntity(
        id: 'tr-1',
        language: 'fr',
        fullText: 'Segment un. Segment deux.',
        wordCount: 4,
        segments: const [
          TranscriptSegmentEntity(
            index: 0,
            startSec: 0,
            endSec: 15,
            text: 'Premier segment d\'introduction.',
          ),
          TranscriptSegmentEntity(
            index: 1,
            startSec: 42,
            endSec: 75,
            text: 'Deuxième segment sur le théorème.',
          ),
        ],
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: Row(
                children: [
                  SizedBox(
                    width: 320,
                    child: InteractiveReplayPlayer(
                      sessionId: 'sess-sync',
                      sessionTitle: 'Cours Test',
                      transcript: transcript,
                    ),
                  ),
                  Expanded(
                    child: SynchronizedTranscriptPanel(
                      sessionId: 'sess-sync',
                      transcript: transcript,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(replayPositionSecondsProvider('sess-sync')), 0.0);

      await tester.tap(find.text('Deuxième segment sur le théorème.'));
      await tester.pump();

      expect(container.read(replayPositionSecondsProvider('sess-sync')), 42.0);
    });

    testWidgets('clicking AI Tutor citation chip seeks replay position',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const history = [
        LessonTutorMessageEntity(
          id: 'msg-1',
          role: 'assistant',
          content: 'Voici l\'explication du théorème à la minute 2.',
          citations: [
            LessonTutorCitationEntity(
              type: 'transcript',
              label: 'Démonstration du théorème',
              timestampSec: 125.0,
            ),
          ],
          createdAt: '2026-11-07T22:00:00Z',
        ),
      ];

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: Scaffold(
              body: LessonAiTutorPanel(
                sessionId: 'sess-tutor',
                initialHistory: history,
              ),
            ),
          ),
        ),
      );

      expect(find.text('[02:05] Démonstration du théorème'), findsOneWidget);
      await tester.tap(find.text('[02:05] Démonstration du théorème'));
      await tester.pump();

      expect(container.read(replayPositionSecondsProvider('sess-tutor')), 125.0);
    });
  });
}

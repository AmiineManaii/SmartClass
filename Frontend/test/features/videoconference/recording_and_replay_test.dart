import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartclass/core/localization/app_localizations.dart';
import 'package:smartclass/features/videoconference/application/recording_providers.dart';
import 'package:smartclass/features/videoconference/domain/entities/recording_models.dart';
import 'package:smartclass/features/videoconference/presentation/widgets/interactive_replay_player.dart';
import 'package:smartclass/features/videoconference/presentation/widgets/lesson_ai_tutor_panel.dart';
import 'package:smartclass/features/videoconference/presentation/widgets/lesson_text_formatter.dart';
import 'package:smartclass/features/videoconference/presentation/widgets/replay_ai_summary_tab.dart';
import 'package:smartclass/features/videoconference/presentation/widgets/student_study_lab_panel.dart';
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

    test('SlideSegmentEntity.fromJsonList assigns distinct sequential slideIndex and cleaners strip LaTeX/chrome noise', () {
      final slides = SlideSegmentEntity.fromJsonList([
        {
          'id': 's1',
          'timestampSeconds': 0,
          'sourcePage': 1,
          'ocrText': 'LECTURE 1',
          'visualSummary': 'Intro',
        },
        {
          'id': 's2',
          'timestampSeconds': 18,
          'sourcePage': 2,
          'ocrText': 'WHAT IS DATA SCIENCE?',
          'visualSummary': 'Venn Diagram',
        },
        {
          'id': 's3',
          'timestampSeconds': 42,
          'sourcePage': 3,
          'ocrText': 'LEARNING FROM DATA',
          'visualSummary': 'Summary slide',
        },
      ]);

      expect(slides.length, 3);
      expect(slides[0].slideIndex, 0);
      expect(slides[1].slideIndex, 1);
      expect(slides[2].slideIndex, 2);
      expect(slides[0].endTimestampSec, 18.0);
      expect(slides[1].endTimestampSec, 42.0);

      expect(
        sanitizeLessonDisplayText('Collect \$\\rightarrow\$ Clean \$ \$ \$ \$ \$ \$ \$ End'),
        'Collect → Clean End',
      );
      final cleanedSlide = sanitizeSlideDisplayText(
        'LEARNING FROM DATA — Arc SmartClass - Profil 1 http://localhost:8283 Antigravity backend - App - Docker News articles \$ \$ \$ \$ \$',
      );
      expect(cleanedSlide, contains('LEARNING FROM DATA'));
      expect(cleanedSlide.contains('localhost'), isFalse);
      expect(cleanedSlide.contains('Antigravity'), isFalse);
      expect(cleanedSlide.contains('\$ \$ \$'), isFalse);
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

    testWidgets('ReplayAiSummaryTab renders synced executive summary, real fidelity, real rules, slides and Teacher Quiz CTA',
        (tester) async {
      var openQuizCalled = false;
      const pkg = LessonPackageEntity(
        id: 'pkg-sync',
        title: 'Data Science',
        shortSummary: 'Résumé court.',
        detailedSummary: 'Cette séance présente les bases de la **Data Science**.',
        structuredMarkdown: '# Notes\n- Collecte \$\\rightarrow\$ Nettoyage \$\\rightarrow\$ Solution',
        formulasAndRules: ['Vérifier la qualité avant modélisation'],
        qualityScore: 0.91,
        chapters: [
          LessonChapterEntity(
            id: 'ch-1',
            chapterIndex: 0,
            title: '1. Introduction',
            summary: 'Flux Collecte \$\\rightarrow\$ Solution',
            startSec: 0,
            endSec: 30,
          ),
        ],
        quizQuestions: [
          LessonQuizQuestionEntity(
            id: 'q1',
            question: 'Que permet la Data Science ?',
            options: ['Résoudre des problèmes avec des données', 'Rien'],
            correctIndex: 0,
            explanation: 'Voir diapositive 1.',
          ),
        ],
      );
      const workspace = StudentLessonWorkspaceEntity(
        sessionId: 'sess-ui',
        sessionTitle: 'Data Science 3A',
        lessonPackage: pkg,
        slides: [
          SlideSegmentEntity(
            id: 'sl-1',
            slideIndex: 0,
            timestampSec: 0,
            endTimestampSec: 15,
            extractedText: 'WHAT IS DATA SCIENCE?',
            visualExplanation: 'Diagramme de processus',
          ),
          SlideSegmentEntity(
            id: 'sl-2',
            slideIndex: 1,
            timestampSec: 15,
            endTimestampSec: 40,
            extractedText: 'Venn Diagram',
            visualExplanation: 'Compétences clés',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReplayAiSummaryTab(
                workspace: workspace,
                onSeekTo: (_) {},
                onOpenQuiz: () => openQuizCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('91% fidélité'), findsOneWidget);
      expect(find.text('98% fidélité'), findsNothing);
      expect(find.text('SYNTHÈSE GÉNÉRALE DU COURS'), findsOneWidget);
      expect(find.textContaining('Règle d\'or'), findsNothing);
      expect(find.textContaining('Vérifier la qualité avant modélisation'), findsOneWidget);
      expect(find.text('Slide #1'), findsOneWidget);
      expect(find.text('Slide #2'), findsOneWidget);
      expect(find.text('Quiz validé par l\'enseignant (1 questions)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('open_teacher_quiz_cta')));
      await tester.pump();
      expect(openQuizCalled, isTrue);
    });

    testWidgets('StudentStudyLabPanel shows teacher quiz by default, filters backing artifacts, switches to custom AI quiz and renders Markdown',
        (tester) async {
      const pkg = LessonPackageEntity(
        id: 'pkg-lab',
        title: 'Data Science',
        shortSummary: 'Court',
        detailedSummary: 'Compétences : *hacking skills* et **statistiques**.',
        structuredMarkdown: '',
        quizQuestions: [
          LessonQuizQuestionEntity(
            id: 'tq-1',
            question: 'Question enseignant : Qu\'est-ce que la Data Science ?',
            options: ['Résoudre avec des données', 'Option B'],
            correctIndex: 0,
            explanation: 'Collect \$\\rightarrow\$ Clean',
          ),
        ],
      );

      const backingArtifact = StudentStudyArtifactEntity(
        id: 'backing-1',
        artifactType: 'QUIZ',
        title: 'Quiz officiel de la séance',
        config: {'source': 'lesson_package'},
        contentJson: {
          'questions': [
            {
              'id': 'tq-1',
              'question': 'Doublon backing artifact',
              'options': ['A', 'B'],
              'correctIndex': 0,
              'explanation': 'E',
            },
          ],
        },
      );

      const customQuizArtifact = StudentStudyArtifactEntity(
        id: 'custom-1',
        artifactType: 'QUIZ',
        title: 'Quiz IA #1 (MOYEN · 1 Q)',
        config: {'source': 'student_ai'},
        contentJson: {
          'questions': [
            {
              'id': 'sq-1',
              'question': 'Question IA inédite : Quel diagramme illustre les compétences ?',
              'options': ['Diagramme de Venn', 'Diagramme de Gantt'],
              'correctAnswer': 'Diagramme de Venn',
              'explanation': 'Math \$\\rightarrow\$ Stats',
            },
          ],
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: Scaffold(
              body: StudentStudyLabPanel(
                sessionId: 'sess-lab',
                lessonPackage: pkg,
                initialArtifacts: const [backingArtifact, customQuizArtifact],
                initialQuizAttempts: const [],
                onRefreshWorkspace: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Summary tab renders Markdown (no raw *hacking skills* asterisks)
      expect(find.textContaining('*hacking skills*'), findsNothing);
      expect(find.textContaining('hacking skills'), findsOneWidget);

      // Switch to Quiz sub-tab
      expect(find.byIcon(Icons.quiz_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.quiz_outlined));
      await tester.pumpAndSettle();

      // Switch to Quiz tab and verify both official teacher quiz and custom AI quiz appear
      expect(find.byKey(const Key('quiz_selector_teacher')), findsOneWidget);
      expect(find.byKey(const Key('quiz_selector_custom_custom-1')), findsOneWidget);
      expect(find.byKey(const Key('quiz_selector_custom_backing-1')), findsNothing);
      expect(find.textContaining('Question enseignant'), findsOneWidget);

      // Switch to custom AI quiz
      await tester.tap(find.byKey(const Key('quiz_selector_custom_custom-1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Question IA inédite'), findsOneWidget);
      expect(find.textContaining('Question enseignant'), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartclass/core/localization/app_localizations.dart';
import 'package:smartclass/features/exams/domain/entities/exam_definition.dart';
import 'package:smartclass/features/exams/infrastructure/models/exam_models.dart';
import 'package:smartclass/features/exams/presentation/widgets/exam_coverage_attribution_card.dart';

void main() {
  group('Exam RAG Phase 3 models parsing', () {
    test('parses ExamCourseOption with chapters', () {
      final option = examCourseOptionFromJson(<String, dynamic>{
        'id': 'course-1',
        'title': 'Algorithmique avancée',
        'subject': 'Informatique',
        'chapters': <String>['Graphes', 'Plus courts chemins'],
      });
      expect(option.id, 'course-1');
      expect(option.title, 'Algorithmique avancée');
      expect(option.subject, 'Informatique');
      expect(option.chapters, <String>['Graphes', 'Plus courts chemins']);
    });

    test('parses ExamKnowledgeDocumentOption with trustTier', () {
      final doc = examKnowledgeDocumentOptionFromJson(<String, dynamic>{
        'id': 'doc-1',
        'sourceType': 'LECTURE_PACKAGE',
        'title': 'Séance 2 : Arbres équilibrés',
        'trustTier': 'DRAFT_AI',
        'chunkCount': 5,
        'indexStatus': 'INDEXED',
      });
      expect(doc.isDraft, isTrue);
      expect(doc.chunkCount, 5);
    });

    test('parses GeneratedExamPreview with coverage and knowledgeSources', () {
      final preview = generatedPreviewFromJson(<String, dynamic>{
        'title': 'Partiel Data Science',
        'model': 'gemma4:e4b',
        'source': 'AI',
        'knowledgeSearchMode': 'HYBRID',
        'knowledgeDegradedReason': null,
        'questions': <Map<String, dynamic>>[
          <String, dynamic>{
            'prompt': 'Quelle métrique mesure la variance expliquée ?',
            'options': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'A', 'text': 'R²'},
              <String, dynamic>{'id': 'B', 'text': 'MSE'},
            ],
            'correctOptionIds': <String>['A'],
            'points': 2,
          },
        ],
        'coverage': <String, dynamic>{
          'totalSources': 2,
          'coveredSources': 2,
          'totalChapters': 4,
          'coveredChapters': 4,
          'truncated': true,
          'warnings': <String>[
            'Le contenu de « Cours 1 » a été condensé équitablement.',
          ],
          'distribution': <Map<String, dynamic>>[
            <String, dynamic>{
              'sourceId': 'course-1',
              'documentId': null,
              'title': 'Cours 1 : Régression',
              'sourceType': 'COURSE',
              'chapters': <String>['Régression linéaire'],
              'targetQuestions': 5,
              'charsIncluded': 4000,
              'charsOriginal': 9000,
              'trimmed': true,
            },
          ],
        },
        'knowledgeSources': <Map<String, dynamic>>[
          <String, dynamic>{
            'documentId': 'doc-9',
            'sourceId': 'rec-9',
            'sourceType': 'LECTURE_PACKAGE',
            'title': 'Séance Régression',
            'sectionTitle': 'Moindres carrés',
            'trustTier': 'VERIFIED',
            'startSeconds': 185,
            'slideNumber': 4,
            'snippet': 'La méthode des moindres carrés minimise la somme...',
            'allocatedQuestions': 3,
            'retrievalOrigin': 'KNOWLEDGE_ENGINE',
          },
        ],
      });

      expect(preview.knowledgeSearchMode, 'HYBRID');
      expect(preview.coverage, isNotNull);
      expect(preview.coverage!.coveredSources, 2);
      expect(preview.coverage!.truncated, isTrue);
      expect(preview.coverage!.distribution.single.targetQuestions, 5);
      expect(preview.knowledgeSources.single.formattedTimestamp, '03:05');
      expect(preview.knowledgeSources.single.slideNumber, 4);
    });
  });

  group('ExamCoverageAttributionCard widget', () {
    testWidgets(
      'renders coverage metrics, warnings, FTS_ONLY notice, and timestamps',
      (WidgetTester tester) async {
        const coverage = ExamCoverageReport(
          totalSources: 2,
          coveredSources: 2,
          totalChapters: 3,
          coveredChapters: 3,
          truncated: true,
          warnings: <String>['Le cours long a été condensé équitablement.'],
          distribution: <ExamSourceCoverageEntry>[
            ExamSourceCoverageEntry(
              sourceId: 'c1',
              title: 'Cours A',
              sourceType: 'COURSE',
              chapters: <String>['Chapitre 1'],
              targetQuestions: 4,
              charsIncluded: 2500,
              charsOriginal: 8000,
              trimmed: true,
            ),
          ],
        );
        const sources = <ExamKnowledgeSource>[
          ExamKnowledgeSource(
            documentId: 'doc-1',
            sourceId: 'rec-1',
            sourceType: 'LECTURE_PACKAGE',
            title: 'Vidéo Graphes',
            sectionTitle: 'Parcours BFS',
            trustTier: 'VERIFIED',
            startSeconds: 185,
            slideNumber: 3,
            snippet: 'Le parcours en largeur utilise une file FIFO.',
            allocatedQuestions: 2,
            retrievalOrigin: 'KNOWLEDGE_ENGINE',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: ExamCoverageAttributionCard(
                  sources: sources,
                  coverage: coverage,
                  searchMode: 'FTS_ONLY',
                  degradedReason: 'Embedding runtime unavailable',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('FTS_ONLY'), findsOneWidget);
        expect(find.textContaining('2/2 sources couvertes'), findsOneWidget);
        expect(find.textContaining('3/3 chapitres'), findsOneWidget);
        expect(find.textContaining('Contenu condensé'), findsOneWidget);
        expect(
          find.textContaining('Embedding runtime unavailable'),
          findsOneWidget,
        );
        expect(find.text('~4 Q'), findsOneWidget);

        // Expand sources drawer and verify timestamp & slide pill
        await tester.tap(find.textContaining('Extraits utilisés (1)'));
        await tester.pumpAndSettle();
        expect(find.text('03:05'), findsOneWidget);
        expect(find.text('Slide #3'), findsOneWidget);
      },
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartclass/features/courses/application/providers/ai_course_options_provider.dart';
import 'package:smartclass/features/courses/domain/entities/knowledge_grounding.dart';
import 'package:smartclass/features/courses/presentation/widgets/knowledge_grounding_controls_card.dart';
import 'package:smartclass/features/courses/presentation/widgets/knowledge_sources_attribution_card.dart';

void main() {
  group('KnowledgeGroundingConfig & KnowledgeSourceAttribution', () {
    test('toJson defaults include enabled=true, includeDrafts=false and omit empty lists', () {
      const defaults = KnowledgeGroundingConfig();
      expect(defaults.toJson(), {
        'enabled': true,
        'includeDrafts': false,
        'maxChunks': 5,
      });

      final customized = defaults.copyWith(
        sourceTypes: const ['COURSE', 'LECTURE_TRANSCRIPT'],
        documentIds: const ['doc-1'],
        includeDrafts: true,
        maxChunks: 6,
      );
      expect(customized.toJson(), {
        'enabled': true,
        'sourceTypes': ['COURSE', 'LECTURE_TRANSCRIPT'],
        'documentIds': ['doc-1'],
        'includeDrafts': true,
        'maxChunks': 6,
      });
    });

    test('KnowledgeSourceAttribution parses timestamps, slide/page metadata, and relevance', () {
      final attr = KnowledgeSourceAttribution.fromJson({
        'documentId': 'doc-1',
        'chunkId': 'chk-1',
        'sourceType': 'LECTURE_TRANSCRIPT',
        'sourceId': 'rec-1',
        'title': 'Séance Data Science #1',
        'sectionTitle': 'Introduction CRISP-DM',
        'trustTier': 'VERIFIED',
        'score': 0.92,
        'vectorScore': 0.84,
        'ftsScore': 0.75,
        'startSeconds': 75,
        'sourcePage': 3,
        'slideNumber': 2,
        'snippet': 'Cycle itératif de compréhension métier...',
      });

      expect(attr.formattedTimestamp, '01:15');
      expect(attr.slideNumber, 2);
      expect(attr.sourcePage, 3);
      expect(attr.relevancePercent, 84);
      expect(attr.trustTier, 'VERIFIED');
    });
  });

  group('KnowledgeSourcesAttributionCard widget', () {
    testWidgets('renders HYBRID attribution with timestamp, slide, trust pill, and snippet', (
      tester,
    ) async {
      final sources = [
        KnowledgeSourceAttribution.fromJson({
          'documentId': 'doc-1',
          'chunkId': 'chk-1',
          'sourceType': 'LECTURE_TRANSCRIPT',
          'sourceId': 'rec-1',
          'title': 'Cours Data Science',
          'sectionTitle': 'Exploration',
          'trustTier': 'VERIFIED',
          'score': 0.89,
          'vectorScore': 0.86,
          'startSeconds': 75,
          'slideNumber': 4,
          'snippet': 'Analyse exploratoire des variables quantitatives.',
        }),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KnowledgeSourcesAttributionCard(
              sources: sources,
              searchMode: 'HYBRID',
            ),
          ),
        ),
      );

      expect(find.text('Sources de votre base utilisées (1)'), findsOneWidget);
      expect(find.text('HYBRID'), findsOneWidget);
      expect(find.text('Cours Data Science • Exploration'), findsOneWidget);
      expect(find.text('01:15'), findsOneWidget);
      expect(find.text('Slide #4'), findsOneWidget);
      expect(find.text('Vérifié'), findsOneWidget);
      expect(find.text('86%'), findsOneWidget);
    });

    testWidgets('renders honest FTS_ONLY degraded banner when embeddings unavailable', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KnowledgeSourcesAttributionCard(
              sources: [],
              searchMode: 'FTS_ONLY',
              degradedReason: 'EmbeddingGemma offline',
            ),
          ),
        ),
      );

      expect(find.text('FTS_ONLY'), findsOneWidget);
      expect(find.text('Mode dégradé : EmbeddingGemma offline'), findsOneWidget);
    });
  });

  group('KnowledgeGroundingControlsCard widget', () {
    testWidgets('notifies onChanged for RAG toggle, source filter chip, and includeDrafts checkbox', (
      tester,
    ) async {
      KnowledgeGroundingConfig latest = const KnowledgeGroundingConfig();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myKnowledgeDocumentsProvider.overrideWith(
              (ref) async => const [
                KnowledgeDocumentSummary(
                  id: 'doc-1',
                  sourceType: 'COURSE',
                  title: 'Polycopié AVL',
                  trustTier: 'VERIFIED',
                  indexStatus: 'INDEXED',
                  chunkCount: 8,
                ),
              ],
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return KnowledgeGroundingControlsCard(
                    config: latest,
                    onChanged: (next) {
                      setState(() => latest = next);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 indexées'), findsOneWidget);

      await tester.tap(find.text('Cours'));
      await tester.pump();
      expect(latest.sourceTypes, ['COURSE']);

      await tester.tap(find.text('Inclure les brouillons IA non validés'));
      await tester.pump();
      expect(latest.includeDrafts, true);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(latest.enabled, false);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:smartclass/features/courses/domain/entities/course_study.dart';

Map<String, dynamic> _summaryArtifact({String? modelUsed}) => {
  'id': 'a1',
  'courseId': 'c1',
  'userId': 'u1',
  'kind': 'SUMMARY',
  'title': 'Résumé',
  'language': 'fr',
  'modelUsed': modelUsed,
  'createdAt': '2026-11-19T09:00:00.000Z',
  'content': {
    'mode': 'short',
    'markdown': '# Titre\n\nContenu du cours.',
    'keyTakeaways': ['Point 1', 'Point 2'],
    'sections': [
      {'title': 'Chapitre 1', 'excerpt': 'Extrait 1'},
    ],
  },
};

Map<String, dynamic> _flashcardsArtifact() => {
  'id': 'a2',
  'courseId': 'c1',
  'userId': 'u1',
  'kind': 'FLASHCARDS',
  'title': 'Flashcards',
  'language': 'fr',
  'content': {
    'focus': 'all',
    'cards': [
      {
        'id': 'k1',
        'front': 'Question 1',
        'back': 'Réponse 1',
        'sectionTitle': 'Chapitre 1',
      },
      {'id': 'k2', 'front': 'Question 2', 'back': 'Réponse 2'},
    ],
  },
};

void main() {
  group('CourseStudyWorkspace.fromJson', () {
    test('parses chapters, artifacts and conversations', () {
      final workspace = CourseStudyWorkspace.fromJson({
        'courseId': 'c1',
        'courseTitle': 'Algorithmique',
        'chapters': [
          {'id': 'p-1', 'title': 'Introduction'},
          {'id': 'p-2', 'title': 'Tri rapide'},
        ],
        'artifacts': [_summaryArtifact(), _flashcardsArtifact()],
        'conversations': [
          {
            'id': 'conv1',
            'title': 'Fil 1',
            'messages': [
              {
                'id': 'm1',
                'conversationId': 'conv1',
                'role': 'user',
                'content': 'Qu’est-ce qu’un pivot ?',
                'inScope': true,
              },
              {
                'id': 'm2',
                'conversationId': 'conv1',
                'role': 'assistant',
                'content': 'Le pivot est…',
                'inScope': true,
                'citations': [
                  {
                    'passageId': 'p-2',
                    'sectionTitle': 'Tri rapide',
                    'excerpt': 'On choisit un pivot…',
                    'score': 0.82,
                  },
                ],
              },
            ],
          },
        ],
      });

      expect(workspace.courseTitle, 'Algorithmique');
      expect(workspace.chapters.map((c) => c.id), ['p-1', 'p-2']);
      expect(workspace.artifacts, hasLength(2));
      expect(workspace.conversations.single.id, 'conv1');
      expect(workspace.conversations.single.messages, hasLength(2));
      expect(
        workspace.conversations.single.messages.last.citations.single.score,
        0.82,
      );
    });

    test('defaults safely on an empty payload', () {
      final workspace = CourseStudyWorkspace.fromJson(const {});

      expect(workspace.courseId, '');
      expect(workspace.chapters, isEmpty);
      expect(workspace.artifacts, isEmpty);
      expect(workspace.conversations, isEmpty);
      expect(workspace.latestSummary, isNull);
      expect(workspace.latestFlashcards, isNull);
      expect(workspace.latestConversation, isNull);
    });

    test('latest getters pick the first matching artifact', () {
      final workspace = CourseStudyWorkspace.fromJson({
        'courseId': 'c1',
        'courseTitle': 'T',
        'artifacts': [_flashcardsArtifact(), _summaryArtifact()],
      });

      expect(workspace.latestFlashcards?.id, 'a2');
      expect(workspace.latestSummary?.id, 'a1');
    });
  });

  group('CourseStudyArtifact', () {
    test('exposes summary fields and the extractive fallback flag', () {
      final artifact = CourseStudyArtifact.fromJson(
        _summaryArtifact(modelUsed: 'extractive-fallback'),
      );

      expect(artifact.isSummary, isTrue);
      expect(artifact.isFlashcards, isFalse);
      expect(artifact.usedFallback, isTrue);
      expect(artifact.summary.mode, 'short');
      expect(artifact.summary.keyTakeaways, ['Point 1', 'Point 2']);
      expect(artifact.summary.sections.single.title, 'Chapitre 1');
    });

    test('parses flashcards and tolerates the legacy `flashcards` key', () {
      final artifact = CourseStudyArtifact.fromJson({
        'id': 'a3',
        'kind': 'FLASHCARDS',
        'content': {
          'focus': 'chapitre 2',
          'flashcards': [
            {'id': 'k1', 'front': 'F', 'back': 'B'},
          ],
        },
      });

      expect(artifact.isFlashcards, isTrue);
      expect(artifact.flashcards.focus, 'chapitre 2');
      expect(artifact.flashcards.cards.single.front, 'F');
      expect(artifact.flashcards.cards.single.sectionTitle, isNull);
    });

    test('round-trips summary and flashcard payloads through toJson', () {
      final summary = CourseSummaryContent.fromJson(
        _summaryArtifact()['content'] as Map<String, dynamic>,
      );
      expect(
        CourseSummaryContent.fromJson(summary.toJson()).markdown,
        summary.markdown,
      );

      final deck = CourseFlashcardsContent.fromJson(
        _flashcardsArtifact()['content'] as Map<String, dynamic>,
      );
      expect(
        CourseFlashcardsContent.fromJson(deck.toJson()).cards,
        hasLength(2),
      );
    });
  });

  group('CourseTutorExchange', () {
    test('parses the persisted exchange and keeps refusals flagged', () {
      final exchange = CourseTutorExchange.fromJson({
        'conversationId': 'conv1',
        'userMessage': {
          'id': 'm1',
          'conversationId': 'conv1',
          'role': 'user',
          'content': 'Quelle est la capitale du Japon ?',
        },
        'assistantMessage': {
          'id': 'm2',
          'conversationId': 'conv1',
          'role': 'assistant',
          'content':
              'Cette question est hors du cours : je ne peux pas y répondre.',
          'inScope': false,
          'citations': [],
        },
      });

      expect(exchange.conversationId, 'conv1');
      expect(exchange.userMessage.isUser, isTrue);
      expect(exchange.assistantMessage.isUser, isFalse);
      expect(exchange.assistantMessage.inScope, isFalse);
      expect(exchange.assistantMessage.citations, isEmpty);
    });

    test('defaults inScope to true when the field is absent', () {
      final message = CourseTutorMessage.fromJson({
        'id': 'm1',
        'role': 'assistant',
        'content': 'Réponse ancrée dans le cours.',
      });

      expect(message.inScope, isTrue);
    });
  });
}

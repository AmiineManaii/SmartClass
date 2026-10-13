import 'package:flutter_test/flutter_test.dart';

import 'package:smartclass/features/courses/application/derive_course_title.dart'
    show deriveCourseTitle;
import 'package:smartclass/features/courses/domain/entities/generated_course.dart';

void main() {
  group('deriveCourseTitle', () {
    test('uses the first Markdown heading', () {
      const content = 'Intro\n\n# Fonction Récursive en Python\n\n## Objectifs';
      expect(
        deriveCourseTitle(content, fallback: 'sujet'),
        'Fonction Récursive en Python',
      );
    });

    test('falls back to the subject when there is no heading', () {
      expect(
        deriveCourseTitle('plain text', fallback: 'fonctions recursive'),
        'fonctions recursive',
      );
    });

    test('caps long titles at 80 chars', () {
      final long = 'a' * 100;
      expect(deriveCourseTitle('# $long').length, 81);
    });
  });

  group('GeneratedCourse.fromJson', () {
    test('parses summaries and details, defaults safely', () {
      final summary = GeneratedCourse.fromJson({
        'id': 'c1',
        'title': 'T',
        'subject': null,
        'level': 'concis',
        'difficulty': 'moyen',
        'format': 'resume',
        'status': 'DRAFT',
        'authorId': 't1',
        'authorName': 'Prof',
      });
      expect(summary.isDraft, isTrue);
      expect(summary.isPublished, isFalse);
      expect(summary.content, isNull);
      expect(summary.subject, isNull);

      final detail = GeneratedCourse.fromJson({
        'id': 'c2',
        'title': 'T2',
        'level': 'detaille',
        'difficulty': 'difficile',
        'format': 'resume',
        'status': 'PUBLISHED',
        'authorId': 't1',
        'authorName': 'Prof',
        'content': '# T2',
      });
      expect(detail.isPublished, isTrue);
      expect(detail.content, '# T2');
    });
  });
}

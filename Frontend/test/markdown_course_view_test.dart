import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mermaid/flutter_mermaid.dart';

import 'package:smartclass/core/localization/app_localizations.dart';
import 'package:smartclass/features/courses/presentation/widgets/markdown_course_view.dart';

void main() {
  testWidgets('renders mermaid figures natively', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: MarkdownCourseView(
              data: '# Titre\n\nLe graphe :\n\n```mermaid\ngraph TD\n  A[Start] --> B{Decision}\n  B -->|Yes| C[OK]\n```\n',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // The figure renders via flutter_mermaid, no raw code block shown.
    expect(find.byType(InteractiveMermaidDiagram), findsOneWidget);
    expect(find.textContaining('A[Start]'), findsNothing);
  });

  testWidgets('falls back to raw code for unsupported mindmap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: MarkdownCourseView(
              data: '# Titre\n\n```mermaid\nmindmap\n  root((Sujet))\n    Enfant\n```\n',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // mindmap is not supported by flutter_mermaid 0.1.0: raw code shown.
    expect(find.byType(InteractiveMermaidDiagram), findsNothing);
    expect(find.textContaining('root((Sujet))'), findsOneWidget);
  });

  group('formatQuizForDisplay', () {
    test('puts each proposition on its own line', () {
      const input = '**Question 1 :** Que fait X ? A) Rien B) Tout C) Moitié D) Autre *Réponse : B* plus de texte';

      final out = formatQuizForDisplay(input);

      expect(out, contains('Question 1'));
      expect(out, contains('\n- A) Rien'));
      expect(out, contains('\n- B) Tout'));
      expect(out, contains('\n- C) Moitié'));
      expect(out, contains('\n- D) Autre'));
      // The inline answer is removed from the question text.
      expect(out, isNot(contains('Réponse : B')));
    });

    test('collects all answers into a correction block after questions', () {
      const input = '**Question 1 :** ? A) x B) y C) z D) w *Réponse : A*\n'
          '**Question 2 :** ? A) x B) y C) z D) w *Réponse : C*';

      final out = formatQuizForDisplay(input);

      final correctionIndex = out.indexOf(quizCorrectionPlaceholder);
      expect(correctionIndex, greaterThan(-1));
      final correction = out.substring(correctionIndex);
      expect(correction, contains('1. **A**'));
      expect(correction, contains('2. **C**'));
      // Answers come after the questions.
      expect(out.indexOf('Question 2'), lessThan(correctionIndex));
    });

    test('leaves regular content untouched', () {
      const input = '# Titre\n\nUn paragraphe A) très simple.';

      final out = formatQuizForDisplay(input);

      expect(out, contains(input));
      expect(out, isNot(contains(quizCorrectionPlaceholder)));
    });
  });
}

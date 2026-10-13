import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:flutter_mermaid/flutter_mermaid.dart';

import '../../../../core/localization/app_localizations.dart';

/// Display post-processing of an AI-generated course (Markdown):
/// - quiz propositions (`A) B) C) D)` on one line) forced one per line ;
/// - inline `Réponse : X` markers removed and collected into a single
///   correction block rendered AFTER all questions (`### Corrigé du quiz`).
String formatQuizForDisplay(String data) {
  final answers = <String>[];
  // 1. Extract inline answers (italics or plain), wherever they appear.
  var out = data.replaceAllMapped(
    RegExp(
      r'\*?_?\s*[Rr]éponse\s*[:：]\s*_?\*?\s*([A-Da-d])\s*_?\*?',
      multiLine: true,
    ),
    (match) {
      answers.add(match.group(1)!.toUpperCase());
      return '';
    },
  );

  // 2. One proposition per line when several options share a line.
  out = out.split('\n').map((line) {
    final markers = RegExp(r'\b[A-D]\)\s').allMatches(line);
    if (markers.length < 2) return line;
    final parts = line.split(RegExp(r'(?=\b[A-D]\)\s)'));
    final buffer = StringBuffer(parts.first.trimRight());
    for (var i = 1; i < parts.length; i++) {
      buffer.write('\n- ${parts[i].trim()}');
    }
    return buffer.toString();
  }).join('\n');

  // 3. Correction block appended AFTER all questions of the course.
  if (answers.isNotEmpty) {
    out = out.trimRight();
    out = '$out\n\n$quizCorrectionPlaceholder\n\n'
        '${List.generate(answers.length, (i) => '${i + 1}. **${answers[i]}**').join('\n')}';
  }
  return out;
}

/// Placeholder replaced with the localized correction header at render.
const quizCorrectionPlaceholder = '__QUIZ_CORRECTION_BLOCK__';

/// "## Correction du quiz" heading without the `##` prefix.
const quizCorrectionHeading = '### ';

/// Visual rendering of an AI-generated course (Markdown) — titles, bold,
/// lists, tables, code blocks and images, styled like a clean PDF page.
///
/// Mermaid fenced blocks are split out of the Markdown and rendered
/// natively with `flutter_mermaid` (pure Dart, offline, interactive).
class MarkdownCourseView extends StatelessWidget {
  final String data;

  const MarkdownCourseView({super.key, required this.data});

  /// Splits the document on ```mermaid fenced blocks (kept raw elsewhere).
  static final _mermaidBlock = RegExp(
    r'```mermaid\s*\n([\s\S]*?)```',
    multiLine: true,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formatted = formatQuizForDisplay(data).replaceAll(
      quizCorrectionPlaceholder,
      '### ${context.tr('quiz_correction')}',
    );

    final sheet = MarkdownStyleSheet(
      h1: theme.textTheme.headlineLarge?.copyWith(
        color: colorScheme.primary,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      h4: theme.textTheme.labelLarge,
      p: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
      listBullet: theme.textTheme.bodyMedium,
      strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      blockquoteDecoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: colorScheme.primary, width: 3),
        ),
      ),
      blockquote: theme.textTheme.bodyMedium,
      tableHead: theme.textTheme.labelSmall,
      tableBody: theme.textTheme.bodySmall,
      tableBorder: TableBorder.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.all(8),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      h1Padding: const EdgeInsets.only(bottom: 12),
      h2Padding: const EdgeInsets.only(top: 20, bottom: 8),
      h3Padding: const EdgeInsets.only(top: 14, bottom: 6),
      blockSpacing: 10,
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFF101729),
        borderRadius: BorderRadius.circular(12),
      ),
      codeblockAlign: WrapAlignment.start,
      code: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        color: const Color(0xFFDCE1FE),
      ),
    );

    final children = <Widget>[];
    var cursor = 0;
    for (final match in _mermaidBlock.allMatches(formatted)) {
      final before = formatted.substring(cursor, match.start).trim();
      if (before.isNotEmpty) {
        children.add(_MarkdownPart(data: before, styleSheet: sheet));
      }
      children.add(_MermaidFigure(code: match.group(1)!.trim()));
      cursor = match.end;
    }
    final after = formatted.substring(cursor).trim();
    if (after.isNotEmpty) {
      children.add(_MarkdownPart(data: after, styleSheet: sheet));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Widget splitter kept visible for tests/documentation.
  static List<String> splitAroundMermaid(String data) {
    final parts = <String>[];
    var cursor = 0;
    for (final match in _mermaidBlock.allMatches(data)) {
      parts.add(data.substring(cursor, match.start));
      parts.add('```mermaid\n${match.group(1)}```');
      cursor = match.end;
    }
    parts.add(data.substring(cursor));
    return parts;
  }
}

class _MarkdownPart extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet styleSheet;

  const _MarkdownPart({required this.data, required this.styleSheet});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: true,
      fitContent: true,
      shrinkWrap: true,
      styleSheet: styleSheet,
      sizedImageBuilder: (config) => _CourseImage(
        uri: config.uri,
        alt: config.alt ?? '',
      ),
      onTapLink: (text, href, title) {},
    );
  }
}

/// A Mermaid diagram rendered natively with the `flutter_mermaid`
/// package (pure Dart, no webview, works offline).
///
/// `flutter_mermaid: 0.1.0` supports `graph`/`flowchart`,
/// `sequenceDiagram`, `pie`, `gantt` and `timeline` — NOT `mindmap`.
/// Unsupported blocks (e.g. `mindmap`) and parse failures fall back to
/// a readable raw-code card instead of crashing the course view.
class _MermaidFigure extends StatelessWidget {
  final String code;

  const _MermaidFigure({required this.code});

  static bool isSupported(String code) {
    final first = code.trimLeft().split('\n').first.trim().toLowerCase();
    return first.startsWith('graph ') ||
        first.startsWith('flowchart ') ||
        first.startsWith('sequencediagram') ||
        first.startsWith('pie') ||
        first.startsWith('gantt') ||
        first.startsWith('timeline') ||
        first.startsWith('kanban') ||
        first.startsWith('radar-beta') ||
        first.startsWith('xychart-beta');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              context.tr('figure_mermaid'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                letterSpacing: 0.04,
              ),
            ),
          ),
          // InteractiveMermaidDiagram needs bounded constraints (its
          // internal InteractiveViewer cannot lay out in an unbounded
          // height), so supported figures get a fixed viewport.
          // Unsupported types (mindmap) use the raw-code fallback.
          if (isSupported(code))
            SizedBox(
              height: 320,
              width: double.infinity,
              child: InteractiveMermaidDiagram(code: code),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _MermaidFallback(code: code, reason: 'mindmap'),
            ),
        ],
      ),
    );
  }
}

/// Fallback shown when a mermaid block cannot be rendered natively
/// (unsupported `mindmap` type or syntax error from the LLM): the raw
/// code stays readable and copyable instead of a blank card.
class _MermaidFallback extends StatelessWidget {
  final String code;
  final String reason;

  const _MermaidFallback({required this.code, required this.reason});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unsupported = reason == 'mindmap';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101729),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                unsupported
                    ? Icons.account_tree_outlined
                    : Icons.warning_amber_outlined,
                size: 16,
                color: const Color(0xFFF5C86B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  unsupported
                      ? 'Carte hiérarchique (code brut — lecteur mindmap non supporté)'
                      : 'Figure non affichable — code brut',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFF5C86B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            code,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: const Color(0xFFDCE1FE),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseImage extends StatelessWidget {
  final Uri uri;
  final String alt;

  const _CourseImage({required this.uri, required this.alt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        uri.toString(),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: 140,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_not_supported_outlined,
                    color: colorScheme.onSurfaceVariant, size: 28),
                if (alt.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      alt,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../domain/entities/recording_models.dart';
import 'lesson_text_formatter.dart';

class ReplayAiSummaryTab extends StatelessWidget {
  final StudentLessonWorkspaceEntity workspace;
  final ValueChanged<double> onSeekTo;
  final ValueChanged<String>? onAskTutor;
  final VoidCallback? onOpenQuiz;
  final String Function(int slideIndex)? frameUrlBuilder;

  const ReplayAiSummaryTab({
    super.key,
    required this.workspace,
    required this.onSeekTo,
    this.onAskTutor,
    this.onOpenQuiz,
    this.frameUrlBuilder,
  });

  String _formatClock(double totalSec) {
    final s = totalSec.floor();
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pkg = workspace.lessonPackage;
    final chapters = pkg.chapters;
    final fidelityLabel = pkg.qualityScore != null
        ? '${(pkg.qualityScore! * 100).round()}% fidélité'
        : 'Validé par l\'enseignant';
    final rawGeneralSummary = pkg.detailedSummary.isNotEmpty
        ? pkg.detailedSummary
        : pkg.shortSummary;
    final cleanGeneralSummary = sanitizeLessonDisplayText(rawGeneralSummary);
    final cleanStructuredNotes =
        sanitizeLessonDisplayText(pkg.structuredMarkdown);
    final keyRules = pkg.formulasAndRules.isNotEmpty
        ? pkg.formulasAndRules
        : (chapters.isNotEmpty ? pkg.keyTakeaways : const <String>[]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. AI Guarantee & Fidelity Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF334155),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Color(0xFFF5A623),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Synthèse & Notes validées SmartClass AI',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              fidelityLabel,
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Synchronisé avec l\'audio, le tableau et les diapositives officielles.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF94A3B8),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Teacher Executive Summary Card (Synced with Teacher Studio)
          if (cleanGeneralSummary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.38),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF6366F1).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SYNTHÈSE GÉNÉRALE DU COURS',
                          style: TextStyle(
                            color: Color(0xFFA5B4FC),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  MarkdownBody(
                    data: cleanGeneralSummary,
                    selectable: true,
                    styleSheet:
                        MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 12.5,
                        height: 1.48,
                      ),
                      strong: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 3. Teacher Validated Quiz Quick CTA Card
          if (pkg.quizQuestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2922),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.quiz_rounded,
                      color: Color(0xFF34D399),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quiz validé par l\'enseignant (${pkg.quizQuestions.length} questions)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Répondez au quiz officiel ou générez de nouvelles questions IA.',
                          style: TextStyle(
                            color: Color(0xFFA7F3D0),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const Key('open_teacher_quiz_cta'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text(
                      'Ouvrir le Quiz',
                      style:
                          TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    onPressed: onOpenQuiz,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // 4. Section Heading: Points clés & Notions fondamentales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Points clés & Notions fondamentales',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${chapters.isNotEmpty ? chapters.length : pkg.keyTakeaways.length} points indexés',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5. Key Points Stream with Timestamp Seek Pills
          if (chapters.isNotEmpty)
            ...chapters.asMap().entries.map((entry) {
              final idx = entry.key;
              final ch = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1F2937),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => onSeekTo(ch.startSec),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 14,
                                  color: Color(0xFF60A5FA),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _formatClock(ch.startSec),
                                  style: const TextStyle(
                                    color: Color(0xFF93C5FD),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Chapitre ${idx + 1}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sanitizeLessonDisplayText(ch.title),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sanitizeLessonDisplayText(ch.summary),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFFCBD5E1),
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            ...pkg.keyTakeaways.asMap().entries.map((entry) {
              final idx = entry.key;
              final pt = sanitizeLessonDisplayText(entry.value);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1F2937)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pt,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          // 6. Real Rules / Objectives Extracted from This Lesson
          if (keyRules.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        color: Color(0xFFF5A623),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Points essentiels & Règles du cours',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFFDE68A),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...keyRules.take(5).map(
                        (rule) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${sanitizeLessonDisplayText(rule)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFFF8FAFC),
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),

          // 7. Validated Slides Strip
          if (workspace.slides.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Diapositives & Captures clés',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${workspace.slides.length} slides',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: workspace.slides.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, idx) {
                  final s = workspace.slides[idx];
                  final slideNum = s.slideIndex >= 0 ? s.slideIndex + 1 : idx + 1;
                  final frameUrl = frameUrlBuilder?.call(
                        s.slideIndex >= 0 ? s.slideIndex : idx,
                      ) ??
                      '';
                  final caption = sanitizeSlideDisplayText(
                    s.visualExplanation.isNotEmpty
                        ? s.visualExplanation
                        : s.extractedText,
                  );
                  return InkWell(
                    onTap: () => onSeekTo(s.timestampSec),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 215,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1F2937)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Slide #$slideNum',
                                style: const TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                _formatClock(s.timestampSec),
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (frameUrl.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 68,
                                width: double.infinity,
                                child: Image.network(
                                  frameUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const ColoredBox(
                                    color: Color(0xFF1E293B),
                                    child: Center(
                                      child: Icon(
                                        Icons.slideshow_rounded,
                                        color: Colors.white54,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              caption.isNotEmpty
                                  ? caption
                                  : 'Diapositive #$slideNum',
                              maxLines: frameUrl.isNotEmpty ? 3 : 5,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 11,
                                height: 1.32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // 8. Structured Course Notes Markdown Body (Synced with Teacher Studio)
          if (cleanStructuredNotes.isNotEmpty || cleanGeneralSummary.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.article_rounded,
                        size: 16,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Notes de cours structurées',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  MarkdownBody(
                    data: cleanStructuredNotes.isNotEmpty
                        ? cleanStructuredNotes
                        : cleanGeneralSummary,
                    selectable: true,
                  ),
                ],
              ),
            ),

          // 9. Glossary Terms & Concepts (Synced with Teacher Studio)
          if (pkg.glossary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 16,
                        color: Color(0xFF60A5FA),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Glossaire & Notions clés',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...pkg.glossary.take(8).map(
                        (g) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                height: 1.4,
                                color: Color(0xFFCBD5E1),
                              ),
                              children: [
                                TextSpan(
                                  text: '${sanitizeLessonDisplayText(g.term)} : ',
                                  style: const TextStyle(
                                    color: Color(0xFF93C5FD),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: sanitizeLessonDisplayText(g.definition),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],

          // 10. Interactive AI Rebounds / Follow-up Questions
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFFF5A623),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Rebonds et Questions au Tuteur',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Réponse instantanée',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF38BDF8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ReboundButton(
                  text: 'Expliquer plus en détail le chapitre principal',
                  onTap: () => onAskTutor?.call(
                    'Peux-tu m\'expliquer en détail les points fondamentaux de ce cours ?',
                  ),
                ),
                const SizedBox(height: 6),
                _ReboundButton(
                  text:
                      'Quels sont les pièges fréquents à éviter à l\'examen ? 🎯',
                  onTap: () => onAskTutor?.call(
                    'Quels sont les pièges fréquents et erreurs classiques à éviter pour ce cours lors d\'un examen ?',
                  ),
                ),
                const SizedBox(height: 6),
                _ReboundButton(
                  text: 'Générer un exercice d\'application avec corrigé ✍️',
                  onTap: () => onAskTutor?.call(
                    'Génère-moi un exercice d\'application complet basé sur ce cours avec son corrigé étape par étape.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReboundButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ReboundButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF334155),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFFE2E8F0),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: Color(0xFF60A5FA),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/recording_providers.dart';
import '../../domain/entities/recording_models.dart';

class TeacherReviewChaptersSlidesTab extends ConsumerWidget {
  final String sessionId;
  final LessonPackageEntity pkg;
  final List<SlideSegmentEntity> slides;

  const TeacherReviewChaptersSlidesTab({
    super.key,
    required this.sessionId,
    required this.pkg,
    required this.slides,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accessToken = ref.watch(recordingAccessTokenProvider).valueOrNull;
    final recordingDs = ref.watch(recordingRemoteDataSourceProvider);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          context.tr('replay_chapters_title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...pkg.chapters.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: InkWell(
              onTap: () {
                ref.read(replayPositionSecondsProvider(sessionId).notifier).state =
                    c.startSec;
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      c.formattedRange,
                      style: const TextStyle(
                        color: Color(0xFF60A5FA),
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.summary,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '${context.tr('replay_slides_title')} (Frames extraites via FFmpeg)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...slides.map((s) {
          final frameUrl = accessToken != null
              ? recordingDs.buildAuthenticatedFrameUrl(
                  sessionId,
                  s.slideIndex,
                  accessToken,
                )
              : '';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (frameUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 140,
                      height: 80,
                      child: Image.network(
                        frameUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFF1E293B),
                          child: Center(
                            child: Icon(Icons.slideshow_rounded, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Slide #${s.slideIndex + 1} • ${s.extractedText}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.visualExplanation,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class TeacherReviewQuizFlashcardsTab extends StatelessWidget {
  final LessonPackageEntity pkg;
  final bool isBusy;
  final ValueChanged<String> onRegenerateSection;

  const TeacherReviewQuizFlashcardsTab({
    super.key,
    required this.pkg,
    required this.isBusy,
    required this.onRegenerateSection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text('Régénérer Quiz IA'),
              onPressed: isBusy ? null : () => onRegenerateSection('quiz'),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.style_rounded, size: 16),
              label: const Text('Régénérer Flashcards IA'),
              onPressed: isBusy ? null : () => onRegenerateSection('flashcards'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Questions du Quiz (${pkg.quizQuestions.length})',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...pkg.quizQuestions.asMap().entries.map((entry) {
          final idx = entry.key;
          final q = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${idx + 1}. ${q.question}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...q.options.asMap().entries.map((opt) {
                  final isCorrect = opt.key == q.correctIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: isCorrect ? const Color(0xFF10B981) : Colors.white38,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            opt.value,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isCorrect ? FontWeight.w700 : FontWeight.w400,
                              color: isCorrect ? const Color(0xFF6EE7B7) : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 6),
                Text(
                  '💡 Explication : ${q.explanation}',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 28),
        Text(
          'Flashcards de révision (${pkg.flashcards.length})',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...pkg.flashcards.map(
          (f) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.front, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 6),
                Text(f.back, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TeacherReviewMindmapGlossaryTab extends StatelessWidget {
  final TextEditingController mindmapCtrl;
  final LessonPackageEntity pkg;

  const TeacherReviewMindmapGlossaryTab({
    super.key,
    required this.mindmapCtrl,
    required this.pkg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        TextField(
          controller: mindmapCtrl,
          maxLines: 7,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
          decoration: InputDecoration(
            labelText: context.tr('replay_mindmap_title'),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('replay_glossary_title'),
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...pkg.glossary.map(
          (g) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(g.term, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(g.definition),
            ),
          ),
        ),
      ],
    );
  }
}

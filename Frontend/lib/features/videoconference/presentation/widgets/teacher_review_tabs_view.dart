import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/recording_providers.dart';
import '../../domain/entities/recording_models.dart';
import 'synchronized_transcript_panel.dart';

class TeacherReviewTabsView extends ConsumerWidget {
  final String sessionId;
  final TabController tabController;
  final TeacherReviewWorkspaceEntity workspace;
  final TextEditingController titleCtrl;
  final TextEditingController shortSummaryCtrl;
  final TextEditingController detailedSummaryCtrl;
  final TextEditingController markdownCtrl;
  final TextEditingController mindmapCtrl;
  final List<TranscriptSegmentEntity> editedSegments;
  final bool isBusy;
  final ValueChanged<String> onRegenerateSection;
  final void Function(int index, TranscriptSegmentEntity updated)
      onSegmentEdited;

  const TeacherReviewTabsView({
    super.key,
    required this.sessionId,
    required this.tabController,
    required this.workspace,
    required this.titleCtrl,
    required this.shortSummaryCtrl,
    required this.detailedSummaryCtrl,
    required this.markdownCtrl,
    required this.mindmapCtrl,
    required this.editedSegments,
    required this.isBusy,
    required this.onRegenerateSection,
    required this.onSegmentEdited,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pkg = workspace.lessonPackage!;
    final accessToken = ref.watch(recordingAccessTokenProvider).valueOrNull;
    final recordingDs = ref.watch(recordingRemoteDataSourceProvider);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: TabBar(
            controller: tabController,
            isScrollable: true,
            indicatorColor: const Color(0xFF3B82F6),
            indicatorWeight: 3,
            labelColor: const Color(0xFF60A5FA),
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: context.tr('review_tab_overview')),
              Tab(text: context.tr('review_tab_transcript')),
              Tab(text: context.tr('review_tab_chapters')),
              Tab(text: context.tr('review_tab_quiz_flashcards')),
              Tab(text: context.tr('review_tab_mindmap')),
              Tab(text: context.tr('review_tab_versions')),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              // 1. Overview & Structured Course Notes
              _buildOverviewTab(context, theme),

              // 2. Editable Synchronized Transcript
              SynchronizedTranscriptPanel(
                sessionId: sessionId,
                transcript: workspace.transcript != null
                    ? RecordingTranscriptEntity(
                        id: workspace.transcript!.id,
                        language: workspace.transcript!.language,
                        fullText: workspace.transcript!.fullText,
                        segments: editedSegments,
                        vttSubtitles: workspace.transcript!.vttSubtitles,
                        wordCount: workspace.transcript!.wordCount,
                      )
                    : null,
                isEditable: true,
                onSegmentEdited: onSegmentEdited,
              ),

              // 3. Chapters & Extracted Visual Slide Frames
              _buildChaptersAndSlidesTab(
                context,
                theme,
                pkg,
                recordingDs,
                accessToken,
                ref,
              ),

              // 4. Quiz & Flashcards Studio
              _buildQuizAndFlashcardsTab(context, theme, pkg),

              // 5. Mindmap & Glossary
              _buildMindmapAndGlossaryTab(context, theme, pkg),

              // 6. Versions & Pipeline Jobs
              _buildVersionsAndPipelineTab(context, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(BuildContext context, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_stories_rounded,
                  size: 18,
                  color: Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Édition du cours & Synthèse IA',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                  label: Text(context.tr('review_btn_regenerate')),
                  onPressed:
                      isBusy ? null : () => onRegenerateSection('summary'),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.article_outlined, size: 15),
                  label: const Text('Régénérer Notes'),
                  onPressed: isBusy
                      ? null
                      : () => onRegenerateSection('structuredNotes'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: titleCtrl,
          decoration: InputDecoration(
            labelText: 'Titre de la leçon',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: detailedSummaryCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Synthèse générale du cours (Executive Summary)',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: markdownCtrl,
          maxLines: 14,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Notes de cours structurées (Markdown)',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
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
              const Row(
                children: [
                  Icon(
                    Icons.preview_rounded,
                    size: 16,
                    color: Color(0xFF38BDF8),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Aperçu du rendu étudiant',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              MarkdownBody(
                data: markdownCtrl.text.isNotEmpty
                    ? markdownCtrl.text
                    : detailedSummaryCtrl.text,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChaptersAndSlidesTab(
    BuildContext context,
    ThemeData theme,
    LessonPackageEntity pkg,
    dynamic recordingDs,
    String? accessToken,
    WidgetRef ref,
  ) {
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
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
        ...workspace.slides.map((s) {
          final frameUrl = accessToken != null
              ? recordingDs.buildAuthenticatedFrameUrl(
                  sessionId,
                  s.slideIndex,
                  accessToken,
                ) as String
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
                            child: Icon(
                              Icons.slideshow_rounded,
                              color: Colors.white54,
                            ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
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

  Widget _buildQuizAndFlashcardsTab(
    BuildContext context,
    ThemeData theme,
    LessonPackageEntity pkg,
  ) {
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
              onPressed:
                  isBusy ? null : () => onRegenerateSection('flashcards'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Questions du Quiz (${pkg.quizQuestions.length})',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...q.options.asMap().entries.map((opt) {
                  final isCorrect = opt.key == q.correctIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: isCorrect
                              ? const Color(0xFF10B981)
                              : Colors.white38,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            opt.value,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  isCorrect ? FontWeight.w700 : FontWeight.w400,
                              color: isCorrect
                                  ? const Color(0xFF6EE7B7)
                                  : theme.colorScheme.onSurface,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 28),
        Text(
          'Flashcards de révision (${pkg.flashcards.length})',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
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
                Text(
                  f.front,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  f.back,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMindmapAndGlossaryTab(
    BuildContext context,
    ThemeData theme,
    LessonPackageEntity pkg,
  ) {
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
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...pkg.glossary.map(
          (g) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                g.term,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(g.definition),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersionsAndPipelineTab(BuildContext context, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          context.tr('review_pipeline_title'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...workspace.jobs.map(
          (j) => ListTile(
            dense: true,
            leading: Icon(
              j.status == 'COMPLETED' || j.status == 'SUCCEEDED'
                  ? Icons.check_circle_rounded
                  : Icons.pending_outlined,
              color: j.status == 'COMPLETED' || j.status == 'SUCCEEDED'
                  ? const Color(0xFF10B981)
                  : Colors.orange,
            ),
            title: Text('${j.jobType} • ${j.stage}'),
            subtitle: Text('${j.progressPercent}% (${j.status})'),
          ),
        ),
        const Divider(height: 24),
        ...workspace.versions.map(
          (v) => ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              child: Text('v${v.versionNumber}'),
            ),
            title: Text(v.changeSummary ?? 'Version enregistrée'),
            subtitle: Text(v.createdAt),
          ),
        ),
      ],
    );
  }
}


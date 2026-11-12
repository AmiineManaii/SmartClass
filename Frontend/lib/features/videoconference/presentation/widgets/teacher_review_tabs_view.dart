import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/recording_models.dart';
import 'synchronized_transcript_panel.dart';
import 'teacher_review_overview_tab.dart';
import 'teacher_review_study_materials_tab.dart';

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
  final void Function(int index, TranscriptSegmentEntity updated) onSegmentEdited;

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
    final isDark = theme.brightness == Brightness.dark;
    final pkg = workspace.lessonPackage!;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1728) : const Color(0xFFF1F5F9),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.5)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor:
                isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
            dividerColor: Colors.transparent,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            tabs: [
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14),
                    SizedBox(width: 6),
                    Text('Synthèse & Notes IA'),
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.transcribe_rounded, size: 14),
                    SizedBox(width: 6),
                    Text('Transcription'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.slideshow_rounded, size: 14),
                    const SizedBox(width: 6),
                    Text('Chapitres & Slides (${pkg.chapters.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.quiz_rounded, size: 14),
                    const SizedBox(width: 6),
                    Text('Quiz & Flashcards (${pkg.quizQuestions.length})'),
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hub_rounded, size: 14),
                    SizedBox(width: 6),
                    Text('Carte & Glossaire'),
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, size: 14),
                    SizedBox(width: 6),
                    Text('Versions & Pipeline'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              TeacherReviewOverviewTab(
                titleCtrl: titleCtrl,
                shortSummaryCtrl: shortSummaryCtrl,
                detailedSummaryCtrl: detailedSummaryCtrl,
                markdownCtrl: markdownCtrl,
                isBusy: isBusy,
                onRegenerateSection: onRegenerateSection,
              ),
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
              TeacherReviewChaptersSlidesTab(
                sessionId: sessionId,
                pkg: pkg,
                slides: workspace.slides,
              ),
              TeacherReviewQuizFlashcardsTab(
                pkg: pkg,
                isBusy: isBusy,
                onRegenerateSection: onRegenerateSection,
              ),
              TeacherReviewMindmapGlossaryTab(
                mindmapCtrl: mindmapCtrl,
                pkg: pkg,
              ),
              _buildVersionsAndPipelineTab(context, theme),
            ],
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
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
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

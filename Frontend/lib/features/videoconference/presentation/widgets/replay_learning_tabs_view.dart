import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/recording_models.dart';
import 'lesson_ai_tutor_panel.dart';
import 'replay_ai_summary_tab.dart';
import 'student_study_lab_panel.dart';
import 'synchronized_transcript_panel.dart';

class ReplayLearningTabsView extends ConsumerWidget {
  final String sessionId;
  final TabController tabController;
  final StudentLessonWorkspaceEntity workspace;
  final TextEditingController noteCtrl;
  final VoidCallback onAddNote;
  final ValueChanged<double> onSeekTo;
  final VoidCallback onRefreshWorkspace;

  const ReplayLearningTabsView({
    super.key,
    required this.sessionId,
    required this.tabController,
    required this.workspace,
    required this.noteCtrl,
    required this.onAddNote,
    required this.onSeekTo,
    required this.onRefreshWorkspace,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pkg = workspace.lessonPackage;

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
            indicatorColor: const Color(0xFF2563EB),
            indicatorWeight: 3,
            labelColor: const Color(0xFF60A5FA),
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 15, color: Color(0xFFF5A623)),
                    SizedBox(width: 6),
                    Text('Résumé IA'),
                  ],
                ),
              ),
              Tab(text: 'Fiches & Quiz'),
              Tab(text: 'Transcription'),
              Tab(text: 'Notes & Repères'),
              Tab(text: 'Tuteur IA'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              // 1. AI Summary, Key Takeaways & Interactive Rebound (Stitch design)
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  ReplayAiSummaryTab(
                    workspace: workspace,
                    onSeekTo: onSeekTo,
                    onAskTutor: (prompt) {
                      tabController.animateTo(4);
                    },
                  ),
                ],
              ),

              // 2. Student Study Lab (Flashcards & Quizzes)
              StudentStudyLabPanel(
                sessionId: sessionId,
                lessonPackage: pkg,
                initialArtifacts: workspace.studyArtifacts,
                initialQuizAttempts: workspace.quizAttempts,
                onRefreshWorkspace: onRefreshWorkspace,
              ),

              // 3. Synchronized Live Transcript
              SynchronizedTranscriptPanel(
                sessionId: sessionId,
                transcript: workspace.transcript,
              ),

              // 4. Personal Notes & Bookmarks
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: context.tr('replay_note_hint'),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.note_add_outlined, size: 16),
                      label: Text(context.tr('replay_add_note')),
                      onPressed: onAddNote,
                    ),
                  ),
                  const Divider(height: 24),
                  Text(
                    'Mes repères (${workspace.bookmarks.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...workspace.bookmarks.map(
                    (b) => ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.bookmark_rounded,
                        color: Color(0xFF38BDF8),
                      ),
                      title: Text('${b.formattedTime} • ${b.label}'),
                      onTap: () => onSeekTo(b.timestampSec),
                    ),
                  ),
                  const Divider(height: 24),
                  Text(
                    'Mes notes (${workspace.notes.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...workspace.notes.map(
                    (n) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(n.content),
                        subtitle: n.timestampSec != null
                            ? Text('⏱️ ${(n.timestampSec! ~/ 60)}m')
                            : null,
                        onTap: n.timestampSec != null
                            ? () => onSeekTo(n.timestampSec!)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),

              // 5. Contextual Lesson AI Tutor
              LessonAiTutorPanel(
                sessionId: sessionId,
                initialHistory: workspace.tutorHistory,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/entities/recording_models.dart';
import 'interactive_replay_player.dart';
import 'lesson_ai_tutor_panel.dart';
import 'replay_ai_summary_tab.dart';
import 'student_study_lab_panel.dart';
import 'synchronized_transcript_panel.dart';

class ReplayMobileWorkspaceView extends StatelessWidget {
  final String sessionId;
  final StudentLessonWorkspaceEntity workspace;
  final TabController tabController;
  final TextEditingController noteCtrl;
  final VoidCallback onAddNote;
  final ValueChanged<double> onSeekTo;
  final VoidCallback onRefreshWorkspace;

  const ReplayMobileWorkspaceView({
    super.key,
    required this.sessionId,
    required this.workspace,
    required this.tabController,
    required this.noteCtrl,
    required this.onAddNote,
    required this.onSeekTo,
    required this.onRefreshWorkspace,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 1. Dynamic Audio/AI Spark Banner
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    workspace.sessionSubject?.isNotEmpty == true
                        ? workspace.sessionSubject!
                        : 'Cours Interactif',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF60A5FA),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                children: const [
                  Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFF5A623)),
                  SizedBox(width: 3),
                  Text(
                    'IA Active • 98% fidélité',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFFF5A623),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Video Player
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: InteractiveReplayPlayer(
            sessionId: sessionId,
            sessionTitle: workspace.sessionTitle,
            recording: workspace.recording,
            transcript: workspace.transcript,
            chapters: workspace.lessonPackage.chapters,
            slides: workspace.slides,
            bookmarks: workspace.bookmarks,
          ),
        ),

        // 3. Instructor & Title Strip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1E293B),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    workspace.sessionTitle.isNotEmpty
                        ? workspace.sessionTitle[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.sessionTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Enseignant certifié • Validé académique',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF94A3B8),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_rounded,
                          size: 13, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        'Terminé',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. Tab Selector Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: tabController,
            isScrollable: true,
            indicatorColor: const Color(0xFF2563EB),
            indicatorWeight: 3,
            labelColor: const Color(0xFF60A5FA),
            unselectedLabelColor: const Color(0xFF94A3B8),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 14, color: Color(0xFFF5A623)),
                    SizedBox(width: 4),
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

        // 5. Active Tab Body flowing naturally down the scroll
        AnimatedBuilder(
          animation: tabController,
          builder: (_, _) {
            switch (tabController.index) {
              case 0:
                return ReplayAiSummaryTab(
                  workspace: workspace,
                  onSeekTo: onSeekTo,
                  onAskTutor: (prompt) {
                    tabController.animateTo(4);
                  },
                );
              case 1:
                return StudentStudyLabPanel(
                  sessionId: sessionId,
                  lessonPackage: workspace.lessonPackage,
                  initialArtifacts: workspace.studyArtifacts,
                  initialQuizAttempts: workspace.quizAttempts,
                  onRefreshWorkspace: onRefreshWorkspace,
                );
              case 2:
                return SizedBox(
                  height: 520,
                  child: SynchronizedTranscriptPanel(
                    sessionId: sessionId,
                    transcript: workspace.transcript,
                  ),
                );
              case 3:
                return _buildMobileNotes(theme);
              case 4:
                return SizedBox(
                  height: 520,
                  child: LessonAiTutorPanel(
                    sessionId: sessionId,
                    initialHistory: workspace.tutorHistory,
                  ),
                );
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }

  Widget _buildMobileNotes(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ajouter une note personnelle sur ce cours...',
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
              icon: const Icon(Icons.note_add_outlined, size: 16),
              label: const Text('Enregistrer la note'),
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
        ],
      ),
    );
  }
}

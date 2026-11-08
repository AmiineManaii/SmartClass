import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/recording_providers.dart';
import '../../domain/entities/recording_models.dart';
import '../widgets/interactive_replay_player.dart';
import '../widgets/replay_learning_tabs_view.dart';
import '../widgets/replay_mobile_workspace_view.dart';

class LectureReplayWorkspacePage extends ConsumerStatefulWidget {
  final String sessionId;

  const LectureReplayWorkspacePage({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<LectureReplayWorkspacePage> createState() =>
      _LectureReplayWorkspacePageState();
}

class _LectureReplayWorkspacePageState
    extends ConsumerState<LectureReplayWorkspacePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _bookmarkCtrl = TextEditingController();
  List<LessonSearchHitEntity> _searchHits = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteCtrl.dispose();
    _bookmarkCtrl.dispose();
    super.dispose();
  }

  void _seekTo(double seconds) {
    ref.read(replayPositionSecondsProvider(widget.sessionId).notifier).state =
        seconds;
  }

  Future<void> _addBookmark() async {
    final label = _bookmarkCtrl.text.trim();
    final posSec = ref.read(replayPositionSecondsProvider(widget.sessionId));
    try {
      await ref.read(recordingRemoteDataSourceProvider).createBookmark(
            sessionId: widget.sessionId,
            timestampSec: posSec,
            label: label.isNotEmpty ? label : 'Repère temporel',
          );
      _bookmarkCtrl.clear();
      ref.invalidate(studentLessonWorkspaceProvider(widget.sessionId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e')),
        );
      }
    }
  }

  Future<void> _addNote() async {
    final content = _noteCtrl.text.trim();
    if (content.isEmpty) return;
    final posSec = ref.read(replayPositionSecondsProvider(widget.sessionId));
    try {
      await ref.read(recordingRemoteDataSourceProvider).upsertPersonalNote(
            sessionId: widget.sessionId,
            timestampSec: posSec,
            content: content,
          );
      _noteCtrl.clear();
      ref.invalidate(studentLessonWorkspaceProvider(widget.sessionId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e')),
        );
      }
    }
  }

  Future<void> _runSmartSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() => _searchHits = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final hits = await ref
          .read(recordingRemoteDataSourceProvider)
          .searchLessonContent(widget.sessionId, trimmed);
      if (mounted) setState(() => _searchHits = hits);
    } catch (_) {
      if (mounted) setState(() => _searchHits = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncWorkspace =
        ref.watch(studentLessonWorkspaceProvider(widget.sessionId));
    final isWide = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/videoconference');
            }
          },
        ),
        title: Text(
          context.tr('replay_workspace_title'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('retry'),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(
              studentLessonWorkspaceProvider(widget.sessionId),
            ),
          ),
        ],
      ),
      body: asyncWorkspace.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top_rounded, size: 48),
                const SizedBox(height: 12),
                Text(
                  '$err',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('retry')),
                  onPressed: () => ref.invalidate(
                    studentLessonWorkspaceProvider(widget.sessionId),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (workspace) {
          if (!isWide) {
            return ReplayMobileWorkspaceView(
              sessionId: widget.sessionId,
              workspace: workspace,
              tabController: _tabController,
              noteCtrl: _noteCtrl,
              onAddNote: _addNote,
              onSeekTo: _seekTo,
              onRefreshWorkspace: () => ref.invalidate(
                studentLessonWorkspaceProvider(widget.sessionId),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: context.tr('replay_search_hint'),
                    prefixIcon: const Icon(Icons.manage_search_rounded),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_searchHits.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () =>
                                    setState(() => _searchHits = []),
                              )
                            : null),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: _runSmartSearch,
                ),
              ),
              if (_searchHits.isNotEmpty)
                Container(
                  height: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.builder(
                    itemCount: _searchHits.length,
                    itemBuilder: (_, idx) {
                      final hit = _searchHits[idx];
                      return ListTile(
                        dense: true,
                        leading: Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            hit.sourceType,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        title: Text(
                          hit.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          hit.snippet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          if (hit.timestampSec != null) {
                            _seekTo(hit.timestampSec!);
                          }
                        },
                      );
                    },
                  ),
                ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 480,
                      child: _buildVideoAndChaptersColumn(
                        theme,
                        workspace,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: ReplayLearningTabsView(
                        sessionId: widget.sessionId,
                        tabController: _tabController,
                        workspace: workspace,
                        noteCtrl: _noteCtrl,
                        onAddNote: _addNote,
                        onSeekTo: _seekTo,
                        onRefreshWorkspace: () => ref.invalidate(
                          studentLessonWorkspaceProvider(widget.sessionId),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoAndChaptersColumn(
    ThemeData theme,
    StudentLessonWorkspaceEntity workspace,
  ) {
    final chapters = workspace.lessonPackage.chapters;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        InteractiveReplayPlayer(
          sessionId: widget.sessionId,
          sessionTitle: workspace.sessionTitle,
          recording: workspace.recording,
          transcript: workspace.transcript,
          chapters: chapters,
          slides: workspace.slides,
          bookmarks: workspace.bookmarks,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _bookmarkCtrl,
                decoration: InputDecoration(
                  hintText: context.tr('replay_bookmark_hint'),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.bookmark_add_outlined, size: 16),
              label: Text(context.tr('replay_add_bookmark')),
              onPressed: _addBookmark,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          context.tr('replay_chapters_title'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        ...chapters.map(
          (ch) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: Text(
                ch.formattedRange,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
              title: Text(
                ch.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                ch.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _seekTo(ch.startSec),
            ),
          ),
        ),
      ],
    );
  }
}

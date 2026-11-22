import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/smart_toast.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();
  List<LessonSearchHitEntity> _searchHits = [];
  bool _isSearching = false;
  int _studyLabModeIndex = 0;
  int _studyLabModeNonce = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  void _openStudyLabQuiz() {
    setState(() {
      _studyLabModeIndex = 1;
      _studyLabModeNonce += 1;
    });
    _tabController.animateTo(1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteCtrl.dispose();
    _bookmarkCtrl.dispose();
    _searchCtrl.dispose();
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
      if (mounted) {
        SmartToast.success(
          context,
          'Repère temporel ajouté avec succès',
          title: 'Signet',
        );
      }
    } catch (e) {
      if (mounted) {
        SmartToast.error(
          context,
          '${context.tr('error')}: $e',
          title: 'Erreur',
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
      if (mounted) {
        SmartToast.success(
          context,
          'Note personnelle enregistrée',
          title: 'Note',
        );
      }
    } catch (e) {
      if (mounted) {
        SmartToast.error(
          context,
          '${context.tr('error')}: $e',
          title: 'Erreur',
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
    final isDark = theme.brightness == Brightness.dark;
    final asyncWorkspace =
        ref.watch(studentLessonWorkspaceProvider(widget.sessionId));
    final isTheater = ref.watch(replayTheaterModeProvider(widget.sessionId));
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 980;
    final workspaceVal = asyncWorkspace.valueOrNull;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090E1A) : const Color(0xFFF8FAFC),
      appBar: _buildReplayAppBar(
        context: context,
        isDark: isDark,
        title: workspaceVal?.sessionTitle ?? context.tr('replay_workspace_title'),
        isWide: isWide,
        isTheater: isTheater,
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
              onOpenQuiz: _openStudyLabQuiz,
              studyLabModeIndex: _studyLabModeIndex,
              studyLabModeNonce: _studyLabModeNonce,
              onRefreshWorkspace: () => ref.invalidate(
                studentLessonWorkspaceProvider(widget.sessionId),
              ),
            );
          }

          return Column(
            children: [
              // Sleek Smart Search Bar + Results Drawer
              _buildSearchHeader(theme, isDark),
              if (_searchHits.isNotEmpty) _buildSearchResults(theme, isDark),

              // Main Workspace: Theater / Cinema Mode OR Pro Split View
              Expanded(
                child: isTheater
                    ? _buildTheaterLayout(theme, isDark, workspace)
                    : _buildSplitLayout(theme, isDark, workspace, screenWidth),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildReplayAppBar({
    required BuildContext context,
    required bool isDark,
    required String title,
    required bool isWide,
    required bool isTheater,
  }) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? const Color(0xFF0B1120) : Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Retour aux séances',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/videoconference');
          }
        },
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          if (isWide) ...[
            InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/videoconference');
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Visioconférence',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            ),
          ],
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          if (isWide) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_filled_rounded,
                      size: 12, color: Color(0xFF34D399)),
                  SizedBox(width: 5),
                  Text(
                    'Replay Interactif IA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF34D399),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (isWide) ...[
          FilledButton.tonalIcon(
            icon: Icon(
              isTheater
                  ? Icons.view_sidebar_outlined
                  : Icons.crop_16_9_rounded,
              size: 16,
            ),
            label: Text(
              isTheater ? 'Vue partagée' : 'Mode Cinéma',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: isTheater
                  ? const Color(0xFF2563EB)
                  : (isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFEFF6FF)),
              foregroundColor: isTheater
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFF1D4ED8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            onPressed: () {
              ref
                  .read(replayTheaterModeProvider(widget.sessionId).notifier)
                  .state = !isTheater;
            },
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          tooltip: context.tr('retry'),
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: () => ref.invalidate(
            studentLessonWorkspaceProvider(widget.sessionId),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1424) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: context.tr('replay_search_hint'),
          prefixIcon: const Icon(Icons.manage_search_rounded, size: 20),
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
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchHits = []);
                      },
                    )
                  : null),
          isDense: true,
          filled: true,
          fillColor: isDark
              ? const Color(0xFF161F33)
              : const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.6)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.6)
                  : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        onSubmitted: _runSmartSearch,
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme, bool isDark) {
    return Container(
      height: 120,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F33) : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        ),
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
    );
  }

  /// Cinema / Theater Mode: Big widescreen 16:9 video stage across the top +
  /// synchronized chapters sidebar + full learning workspace below!
  Widget _buildTheaterLayout(
    ThemeData theme,
    bool isDark,
    StudentLessonWorkspaceEntity workspace,
  ) {
    final chapters = workspace.lessonPackage.chapters;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Cinematic Stage Band
        Container(
          color: isDark ? const Color(0xFF060A14) : const Color(0xFF0F172A),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: InteractiveReplayPlayer(
                sessionId: widget.sessionId,
                sessionTitle: workspace.sessionTitle,
                recording: workspace.recording,
                transcript: workspace.transcript,
                chapters: chapters,
                slides: workspace.slides,
                bookmarks: workspace.bookmarks,
                enableTheaterToggle: true,
              ),
            ),
          ),
        ),

        // Quick Bookmark Strip below cinema video
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: _buildBookmarkBar(isDark),
            ),
          ),
        ),

        // Full-width Learning Tabs below
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: SizedBox(
              height: 640,
              child: ReplayLearningTabsView(
                sessionId: widget.sessionId,
                tabController: _tabController,
                workspace: workspace,
                noteCtrl: _noteCtrl,
                onAddNote: _addNote,
                onSeekTo: _seekTo,
                onOpenQuiz: _openStudyLabQuiz,
                studyLabModeIndex: _studyLabModeIndex,
                studyLabModeNonce: _studyLabModeNonce,
                onRefreshWorkspace: () => ref.invalidate(
                  studentLessonWorkspaceProvider(widget.sessionId),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Pro Split View: Wider responsive video stage column (up to 560px) + tabs
  Widget _buildSplitLayout(
    ThemeData theme,
    bool isDark,
    StudentLessonWorkspaceEntity workspace,
    double screenWidth,
  ) {
    final videoColumnWidth = (screenWidth * 0.44).clamp(480.0, 620.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: videoColumnWidth,
          child: _buildVideoAndChaptersColumn(theme, isDark, workspace),
        ),
        VerticalDivider(
          width: 1,
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        Expanded(
          child: ReplayLearningTabsView(
            sessionId: widget.sessionId,
            tabController: _tabController,
            workspace: workspace,
            noteCtrl: _noteCtrl,
            onAddNote: _addNote,
            onSeekTo: _seekTo,
            onOpenQuiz: _openStudyLabQuiz,
            studyLabModeIndex: _studyLabModeIndex,
            studyLabModeNonce: _studyLabModeNonce,
            onRefreshWorkspace: () => ref.invalidate(
              studentLessonWorkspaceProvider(widget.sessionId),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarkBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.6)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _bookmarkCtrl,
              decoration: InputDecoration(
                hintText: context.tr('replay_bookmark_hint'),
                prefixIcon: const Icon(Icons.bookmark_border_rounded, size: 18),
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.bookmark_add_outlined, size: 15),
            label: Text(
              context.tr('replay_add_bookmark'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            onPressed: _addBookmark,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoAndChaptersColumn(
    ThemeData theme,
    bool isDark,
    StudentLessonWorkspaceEntity workspace,
  ) {
    final chapters = workspace.lessonPackage.chapters;
    final currentPos =
        ref.watch(replayPositionSecondsProvider(widget.sessionId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InteractiveReplayPlayer(
          sessionId: widget.sessionId,
          sessionTitle: workspace.sessionTitle,
          recording: workspace.recording,
          transcript: workspace.transcript,
          chapters: chapters,
          slides: workspace.slides,
          bookmarks: workspace.bookmarks,
          enableTheaterToggle: true,
        ),
        const SizedBox(height: 12),
        _buildBookmarkBar(isDark),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.auto_awesome_motion_rounded,
                size: 16, color: Color(0xFF60A5FA)),
            const SizedBox(width: 8),
            Text(
              context.tr('replay_chapters_title'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${chapters.length} chapitres',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF60A5FA),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...chapters.asMap().entries.map((entry) {
          final idx = entry.key;
          final ch = entry.value;
          final isActive = currentPos >= ch.startSec && currentPos <= ch.endSec;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.18 : 0.1)
                  : (isDark ? const Color(0xFF131C31) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.65)
                    : (isDark
                        ? const Color(0xFF334155).withValues(alpha: 0.55)
                        : const Color(0xFFE2E8F0)),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _seekTo(ch.startSec),
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? const Color(0xFF2563EB)
                            : (isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9)),
                      ),
                      alignment: Alignment.center,
                      child: isActive
                          ? const Icon(Icons.play_arrow_rounded,
                              size: 16, color: Colors.white)
                          : Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF475569),
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                ch.formattedRange,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF60A5FA),
                                ),
                              ),
                              if (isActive) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    'ACTIF',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF93C5FD),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ch.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          if (ch.summary.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              ch.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

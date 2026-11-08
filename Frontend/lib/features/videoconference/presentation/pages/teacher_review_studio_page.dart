import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/recording_providers.dart';
import '../../domain/entities/recording_models.dart';
import '../widgets/interactive_replay_player.dart';
import '../widgets/teacher_review_publishing_toolbar.dart';
import '../widgets/teacher_review_tabs_view.dart';

class TeacherReviewStudioPage extends ConsumerStatefulWidget {
  final String sessionId;

  const TeacherReviewStudioPage({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<TeacherReviewStudioPage> createState() =>
      _TeacherReviewStudioPageState();
}

class _TeacherReviewStudioPageState
    extends ConsumerState<TeacherReviewStudioPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _shortSummaryCtrl = TextEditingController();
  final TextEditingController _detailedSummaryCtrl = TextEditingController();
  final TextEditingController _markdownCtrl = TextEditingController();
  final TextEditingController _mindmapCtrl = TextEditingController();

  String? _initializedPackageId;
  List<TranscriptSegmentEntity> _editedSegments = [];
  bool _hasTranscriptEdits = false;
  bool _isBusy = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    _titleCtrl.dispose();
    _shortSummaryCtrl.dispose();
    _detailedSummaryCtrl.dispose();
    _markdownCtrl.dispose();
    _mindmapCtrl.dispose();
    super.dispose();
  }

  void _setupPollingIfNeeded(TeacherReviewWorkspaceEntity workspace) {
    final latestJob = workspace.jobs.isNotEmpty ? workspace.jobs.first : null;
    final isProcessing = workspace.recording?.status == 'PROCESSING' ||
        latestJob?.status == 'RUNNING' ||
        workspace.lessonPackage == null;
    if (isProcessing) {
      _pollTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        ref.invalidate(teacherReviewWorkspaceProvider(widget.sessionId));
      });
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void _hydrateControllers(TeacherReviewWorkspaceEntity workspace) {
    final pkg = workspace.lessonPackage;
    if (pkg == null) return;
    if (_initializedPackageId == '${pkg.id}_v${pkg.currentVersion}') return;
    _initializedPackageId = '${pkg.id}_v${pkg.currentVersion}';

    _titleCtrl.text = pkg.title;
    _shortSummaryCtrl.text = pkg.shortSummary;
    _detailedSummaryCtrl.text = pkg.detailedSummary;
    _markdownCtrl.text = pkg.structuredMarkdown;
    _mindmapCtrl.text = pkg.mindMapMermaid ?? '';
    _editedSegments = List<TranscriptSegmentEntity>.from(
      workspace.transcript?.segments ?? const [],
    );
    _hasTranscriptEdits = false;
  }

  Future<void> _saveEdits() async {
    setState(() => _isBusy = true);
    try {
      final ds = ref.read(recordingRemoteDataSourceProvider);
      final payload = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'shortSummary': _shortSummaryCtrl.text.trim(),
        'detailedSummary': _detailedSummaryCtrl.text.trim(),
        'structuredMarkdown': _markdownCtrl.text,
        'mindMapMermaid': _mindmapCtrl.text.trim(),
        'changeSummary': 'Modification enseignant dans le Studio IA',
      };
      if (_hasTranscriptEdits) {
        payload['transcriptSegments'] =
            _editedSegments.map((s) => s.toJson()).toList();
      }
      await ds.updateTeacherReview(
        sessionId: widget.sessionId,
        payload: payload,
      );
      ref.invalidate(teacherReviewWorkspaceProvider(widget.sessionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('review_saved_success'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _regenerateSection(String section) async {
    setState(() => _isBusy = true);
    try {
      final ds = ref.read(recordingRemoteDataSourceProvider);
      await ds.regenerateLessonSection(
        sessionId: widget.sessionId,
        section: section,
      );
      _initializedPackageId = null;
      ref.invalidate(teacherReviewWorkspaceProvider(widget.sessionId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _runStatusAction(String action) async {
    setState(() => _isBusy = true);
    try {
      final ds = ref.read(recordingRemoteDataSourceProvider);
      if (action == 'approve') {
        await ds.approveLessonPackage(widget.sessionId);
      } else if (action == 'publish') {
        await ds.publishLessonPackage(widget.sessionId);
      } else if (action == 'unpublish') {
        await ds.unpublishLessonPackage(widget.sessionId);
      } else if (action == 'retry') {
        await ds.retryProcessing(widget.sessionId);
      }
      ref.invalidate(teacherReviewWorkspaceProvider(widget.sessionId));
      if (mounted) {
        final msgKey = action == 'approve'
            ? 'review_approved_success'
            : action == 'publish'
                ? 'review_published_success'
                : action == 'unpublish'
                    ? 'review_unpublished_success'
                    : 'rec_stopped_toast';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(msgKey))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncWorkspace =
        ref.watch(teacherReviewWorkspaceProvider(widget.sessionId));
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('review_studio_title'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              context.tr('review_studio_subtitle'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: Text(context.tr('btn_preview_replay')),
            onPressed: () =>
                context.push('/videoconference/${widget.sessionId}/replay'),
          ),
          const SizedBox(width: 8),
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
                Text('${context.tr('error')}: $err',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('retry')),
                  onPressed: () => ref.invalidate(
                    teacherReviewWorkspaceProvider(widget.sessionId),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (workspace) {
          _setupPollingIfNeeded(workspace);
          _hydrateControllers(workspace);
          final pkg = workspace.lessonPackage;

          return Column(
            children: [
              if (_isBusy) const LinearProgressIndicator(minHeight: 2),
              TeacherReviewPublishingToolbar(
                workspace: workspace,
                pkg: pkg,
                isBusy: _isBusy,
                onRetry: () => _runStatusAction('retry'),
                onSave: _saveEdits,
                onApprove: () => _runStatusAction('approve'),
                onPublish: () => _runStatusAction('publish'),
                onUnpublish: () => _runStatusAction('unpublish'),
              ),
              Expanded(
                child: pkg == null
                    ? _buildEmptyPipelineState(theme, workspace)
                    : isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 440,
                                child: _buildLeftStagePane(theme, workspace),
                              ),
                              const VerticalDivider(width: 1),
                              Expanded(
                                child: TeacherReviewTabsView(
                                  sessionId: widget.sessionId,
                                  tabController: _tabController,
                                  workspace: workspace,
                                  titleCtrl: _titleCtrl,
                                  shortSummaryCtrl: _shortSummaryCtrl,
                                  detailedSummaryCtrl: _detailedSummaryCtrl,
                                  markdownCtrl: _markdownCtrl,
                                  mindmapCtrl: _mindmapCtrl,
                                  editedSegments: _editedSegments,
                                  isBusy: _isBusy,
                                  onRegenerateSection: _regenerateSection,
                                  onSegmentEdited: (idx, updated) {
                                    setState(() {
                                      _editedSegments[idx] = updated;
                                      _hasTranscriptEdits = true;
                                    });
                                  },
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: InteractiveReplayPlayer(
                                  sessionId: widget.sessionId,
                                  sessionTitle: workspace.sessionTitle,
                                  recording: workspace.recording,
                                  transcript: workspace.transcript,
                                  chapters: pkg.chapters,
                                  slides: workspace.slides,
                                ),
                              ),
                              Expanded(
                                child: TeacherReviewTabsView(
                                  sessionId: widget.sessionId,
                                  tabController: _tabController,
                                  workspace: workspace,
                                  titleCtrl: _titleCtrl,
                                  shortSummaryCtrl: _shortSummaryCtrl,
                                  detailedSummaryCtrl: _detailedSummaryCtrl,
                                  markdownCtrl: _markdownCtrl,
                                  mindmapCtrl: _mindmapCtrl,
                                  editedSegments: _editedSegments,
                                  isBusy: _isBusy,
                                  onRegenerateSection: _regenerateSection,
                                  onSegmentEdited: (idx, updated) {
                                    setState(() {
                                      _editedSegments[idx] = updated;
                                      _hasTranscriptEdits = true;
                                    });
                                  },
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

  Widget _buildEmptyPipelineState(
    ThemeData theme,
    TeacherReviewWorkspaceEntity workspace,
  ) {
    final latestJob = workspace.jobs.isNotEmpty ? workspace.jobs.first : null;
    final isProcessing = workspace.recording?.status == 'PROCESSING' ||
        latestJob?.status == 'RUNNING';
    final progress = latestJob?.progressPercent ?? 35;
    final stageMsg = latestJob?.stage ?? 'Analyse IA en cours...';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isProcessing) ...[
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 18),
                Text(
                  'Analyse IA de la séance en cours...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Extraction du discours, reconnaissance des diapositives et génération du cours structuré.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress / 100.0,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$progress% — $stageMsg',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.auto_awesome_motion_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr('review_no_package_title'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('review_no_package_desc'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(context.tr('review_btn_retry_pipeline')),
                  onPressed: _isBusy ? null : () => _runStatusAction('retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftStagePane(
    ThemeData theme,
    TeacherReviewWorkspaceEntity workspace,
  ) {
    final pkg = workspace.lessonPackage!;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        InteractiveReplayPlayer(
          sessionId: widget.sessionId,
          sessionTitle: workspace.sessionTitle,
          recording: workspace.recording,
          transcript: workspace.transcript,
          chapters: pkg.chapters,
          slides: workspace.slides,
        ),
        const SizedBox(height: 14),
        Text(
          context.tr('replay_chapters_title'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...pkg.chapters.map(
          (ch) => ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Text(
              ch.formattedRange,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B82F6),
              ),
            ),
            title: Text(ch.title, style: const TextStyle(fontSize: 13)),
            subtitle: Text(
              ch.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5),
            ),
            onTap: () {
              ref
                  .read(replayPositionSecondsProvider(widget.sessionId).notifier)
                  .state = ch.startSec;
            },
          ),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/smart_toast.dart';
import '../../application/recording_providers.dart';
import '../../domain/entities/recording_models.dart';
import '../widgets/interactive_replay_player.dart';
import '../widgets/teacher_review_chapter_timeline.dart';
import '../widgets/teacher_review_pipeline_banner.dart';
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

class _TeacherReviewStudioPageState extends ConsumerState<TeacherReviewStudioPage>
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
        (workspace.recording?.status != 'FAILED' &&
            workspace.lessonPackage == null);
    if (isProcessing) {
      _pollTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        ref.invalidate(teacherReviewWorkspaceProvider(widget.sessionId));
      });
    } else {
      if (_pollTimer != null) {
        _pollTimer?.cancel();
        _pollTimer = null;
        _initializedPackageId = null;
      }
    }
  }

  static String _cleanAiPreamble(String text) {
    var cleaned = text.trim();
    final preamblePattern = RegExp(
      r'^(?:En tant que|Voici le r[eé]sum[eé]|Voici les notes|Bonjour|Bienvenue|Je suis|En r[eé]ponse)[^\n]*\n+(?:\*{3,}|-{3,})?\s*',
      caseSensitive: false,
    );
    while (preamblePattern.hasMatch(cleaned)) {
      cleaned = cleaned.replaceFirst(preamblePattern, '').trim();
    }
    return cleaned;
  }

  void _hydrateControllers(TeacherReviewWorkspaceEntity workspace) {
    final pkg = workspace.lessonPackage;
    if (pkg == null) return;
    if (_initializedPackageId == '${pkg.id}_v${pkg.currentVersion}') return;
    _initializedPackageId = '${pkg.id}_v${pkg.currentVersion}';

    _titleCtrl.text = pkg.title;
    _shortSummaryCtrl.text = _cleanAiPreamble(pkg.shortSummary);
    _detailedSummaryCtrl.text = _cleanAiPreamble(pkg.detailedSummary);
    _markdownCtrl.text = _cleanAiPreamble(pkg.structuredMarkdown);
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
        SmartToast.success(
          context,
          context.tr('review_saved_success'),
          title: 'Enregistrement',
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
      if (mounted) {
        SmartToast.info(
          context,
          'Régénération de la section $section en cours...',
          title: 'IA en cours',
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
        _initializedPackageId = null;
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
        final message = action == 'retry'
            ? 'L\'analyse IA de la séance a démarré.'
            : context.tr(msgKey);
        final title = action == 'publish'
            ? 'Publication réussie'
            : action == 'approve'
                ? 'Contenu validé'
                : 'Studio IA';
        SmartToast.success(
          context,
          message,
          title: title,
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
      appBar: _buildStudioAppBar(context, theme, asyncWorkspace.valueOrNull),
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
          final latestJob =
              workspace.jobs.isNotEmpty ? workspace.jobs.first : null;
          final isProcessing = workspace.recording?.status == 'PROCESSING' ||
              latestJob?.status == 'RUNNING';

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
              if (isProcessing)
                TeacherReviewActiveProcessingBanner(workspace: workspace),
              Expanded(
                child: pkg == null
                    ? TeacherReviewEmptyPipelineState(
                        workspace: workspace,
                        isBusy: _isBusy,
                        onRetry: () => _runStatusAction('retry'),
                      )
                    : isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 480,
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
                        : ListView(
                            children: [
                              _buildLeftStagePane(theme, workspace),
                              const Divider(height: 1),
                              SizedBox(
                                height: 600,
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

  PreferredSizeWidget _buildStudioAppBar(
    BuildContext context,
    ThemeData theme,
    TeacherReviewWorkspaceEntity? workspace,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final title = workspace?.sessionTitle ?? 'Séance';
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
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFF818CF8)),
                SizedBox(width: 4),
                Text(
                  'Studio IA & Publication',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF818CF8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton.tonalIcon(
          icon: const Icon(Icons.visibility_rounded, size: 15),
          label: const Text('Aperçu Étudiant', style: TextStyle(fontSize: 12)),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () =>
              context.push('/videoconference/${widget.sessionId}/replay'),
        ),
        const SizedBox(width: 14),
      ],
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
        TeacherReviewChapterTimeline(
          sessionId: widget.sessionId,
          chapters: pkg.chapters,
        ),
      ],
    );
  }
}

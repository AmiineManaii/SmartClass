import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/recording_models.dart';

const List<_PipelineStageStep> _pipelineSteps = [
  _PipelineStageStep(
    key: 'VALIDATION',
    label: 'Validation de la vidéo MP4',
    detail: 'Vérification du flux vidéo/audio et extraction de la miniature',
  ),
  _PipelineStageStep(
    key: 'AUDIO_EXTRACTION',
    label: 'Extraction audio 16 kHz',
    detail: 'Séparation de la piste vocale via FFmpeg',
  ),
  _PipelineStageStep(
    key: 'TRANSCRIPTION',
    label: 'Transcription horodatée (Faster-Whisper)',
    detail: 'Reconnaissance vocale et génération des sous-titres VTT/SRT',
  ),
  _PipelineStageStep(
    key: 'VISUAL_ANALYSIS',
    label: 'Extraction des frames & Vision IA',
    detail: 'Détection des changements de slides (dHash) et lecture OCR',
  ),
  _PipelineStageStep(
    key: 'DOCUMENT_ANALYSIS',
    label: 'Analyse des documents supports',
    detail: 'Corrélation avec les supports de cours éventuels',
  ),
  _PipelineStageStep(
    key: 'TEMPORAL_ALIGNMENT',
    label: 'Découpage intelligent en chapitres',
    detail: 'Alignement temporel entre la voix et les diapositives',
  ),
  _PipelineStageStep(
    key: 'LESSON_GENERATION',
    label: 'Génération IA : résumé, notes, quiz & flashcards',
    detail: 'Synthèse complète et carte mentale par le modèle Ollama local',
  ),
];

class _PipelineStageStep {
  final String key;
  final String label;
  final String detail;

  const _PipelineStageStep({
    required this.key,
    required this.label,
    required this.detail,
  });
}

int _stageIndexOf(String rawStage) {
  final s = rawStage.toUpperCase();
  if (s == 'COMPLETED') return _pipelineSteps.length;
  if (s == 'QUALITY_VALIDATION') return _pipelineSteps.length - 1;
  if (s == 'SLIDE_ANALYSIS') return 3;
  if (s == 'CHAPTER_GENERATION') return 5;
  final idx = _pipelineSteps.indexWhere((e) => e.key == s);
  return idx >= 0 ? idx : 0;
}

String _stageLabelFor(String rawStage) {
  final s = rawStage.toUpperCase();
  if (s == 'COMPLETED') return 'Finalisation terminée';
  if (s == 'QUALITY_VALIDATION') {
    return 'Étape 7/7 : Validation qualité & cohérence IA';
  }
  final idx = _stageIndexOf(s);
  final step = _pipelineSteps[idx.clamp(0, _pipelineSteps.length - 1)];
  return 'Étape ${idx + 1}/${_pipelineSteps.length} : ${step.label}';
}

String _stageDetailFor(String rawStage, MediaProcessingJobEntity? job) {
  if (job != null && job.stageLogs.isNotEmpty) {
    final lastMsg = job.stageLogs.last.message.trim();
    if (lastMsg.isNotEmpty) return lastMsg;
  }
  final idx = _stageIndexOf(rawStage);
  if (idx >= _pipelineSteps.length) {
    return 'Finalisation du studio pédagogique...';
  }
  return _pipelineSteps[idx].detail;
}

/// Live second-by-second elapsed timer pill (matching Course Generator style).
class _LiveElapsedTimerBadge extends StatefulWidget {
  final DateTime? startedAt;
  final bool compact;

  const _LiveElapsedTimerBadge({
    required this.startedAt,
    this.compact = false,
  });

  @override
  State<_LiveElapsedTimerBadge> createState() => _LiveElapsedTimerBadgeState();
}

class _LiveElapsedTimerBadgeState extends State<_LiveElapsedTimerBadge> {
  late DateTime _anchor;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _anchor = widget.startedAt ?? DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _LiveElapsedTimerBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startedAt != null && widget.startedAt != oldWidget.startedAt) {
      _anchor = widget.startedAt!;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsedSec =
        DateTime.now().difference(_anchor).inSeconds.clamp(0, 86400);
    final formatted = formatDurationTimestamp(elapsedSec);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 8 : 12,
        vertical: widget.compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: widget.compact ? 13 : 15,
            color: const Color(0xFF60A5FA),
          ),
          const SizedBox(width: 5),
          Text(
            formatted,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: widget.compact ? 12 : 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF93C5FD),
            ),
          ),
        ],
      ),
    );
  }
}

class TeacherReviewActiveProcessingBanner extends StatelessWidget {
  final TeacherReviewWorkspaceEntity workspace;

  const TeacherReviewActiveProcessingBanner({
    super.key,
    required this.workspace,
  });

  @override
  Widget build(BuildContext context) {
    final latestJob = workspace.jobs.isNotEmpty ? workspace.jobs.first : null;
    final progress = latestJob?.progressPercent ?? 10;
    final stage = latestJob?.stage ?? 'VALIDATION';
    final activeModel = latestJob?.stageLogs.isNotEmpty == true
        ? latestJob!.stageLogs.last.modelUsed
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_stageLabelFor(stage)} ($progress%)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF93C5FD),
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (activeModel != null && activeModel.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activeModel,
                    style: const TextStyle(
                      color: Color(0xFFA5B4FC),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _LiveElapsedTimerBadge(
                startedAt: latestJob?.startedAt,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progress / 100.0).clamp(0.05, 1.0),
              minHeight: 4,
              backgroundColor: const Color(0xFF334155),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }
}

class TeacherReviewFailedBanner extends StatelessWidget {
  final String errorMessage;
  final bool isBusy;
  final VoidCallback onRetry;

  const TeacherReviewFailedBanner({
    super.key,
    required this.errorMessage,
    required this.isBusy,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withValues(alpha: 0.35),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFCA5A5),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(
                color: Color(0xFFFEE2E2),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: const Text(
              'Relancer l\'analyse IA',
              style: TextStyle(fontSize: 12),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: isBusy ? null : onRetry,
          ),
        ],
      ),
    );
  }
}

class TeacherReviewEmptyPipelineState extends StatelessWidget {
  final TeacherReviewWorkspaceEntity workspace;
  final bool isBusy;
  final VoidCallback onRetry;

  const TeacherReviewEmptyPipelineState({
    super.key,
    required this.workspace,
    required this.isBusy,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final latestJob = workspace.jobs.isNotEmpty ? workspace.jobs.first : null;
    final recStatus = workspace.recording?.status ?? '';
    final isFailed =
        recStatus == 'FAILED' || (latestJob?.isFailed ?? false);
    final isProcessing = !isFailed &&
        (recStatus == 'PROCESSING' ||
            recStatus == 'RECORDED' ||
            (latestJob?.isActive ?? false));
    final progress = latestJob?.progressPercent ?? 10;
    final stage = latestJob?.stage ?? 'VALIDATION';
    final currentStepIdx = _stageIndexOf(stage);
    final errorMsg = latestJob?.errorMessage ??
        workspace.recording?.errorMessage ??
        'L\'analyse IA n\'a pas pu aboutir. Vérifiez qu\'Ollama est démarré puis réessayez.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131B2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFailed
                    ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                    : isProcessing
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.45)
                        : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isProcessing) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Génération IA en cours...',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      _LiveElapsedTimerBadge(startedAt: latestJob?.startedAt),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _stageDetailFor(stage, latestJob),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (progress / 100.0).clamp(0.05, 1.0),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _stageLabelFor(stage),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        '$progress%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  ...List.generate(_pipelineSteps.length, (i) {
                    final step = _pipelineSteps[i];
                    final isDone = i < currentStepIdx;
                    final isCurrent = i == currentStepIdx;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          if (isDone)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: Color(0xFF10B981),
                            )
                          else if (isCurrent)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: theme.colorScheme.outline,
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              step.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isDone
                                    ? const Color(0xFF10B981)
                                    : isCurrent
                                        ? (isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A))
                                        : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  Text(
                    'Le Studio de révision s\'ouvrira automatiquement dès la fin du traitement.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else if (isFailed) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      size: 40,
                      color: Color(0xFFF87171),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Analyse IA interrompue',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFCA5A5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    errorMsg,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.tr('review_btn_retry_pipeline')),
                    onPressed: isBusy ? null : onRetry,
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
                    onPressed: isBusy ? null : onRetry,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

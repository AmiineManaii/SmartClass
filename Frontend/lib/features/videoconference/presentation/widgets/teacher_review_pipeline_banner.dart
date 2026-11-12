import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/recording_models.dart';

class TeacherReviewActiveProcessingBanner extends StatelessWidget {
  final TeacherReviewWorkspaceEntity workspace;

  const TeacherReviewActiveProcessingBanner({
    super.key,
    required this.workspace,
  });

  String _getStageLabel(String stage) {
    switch (stage.toUpperCase()) {
      case 'VALIDATION':
        return 'Étape 1/7 : Validation du fichier vidéo';
      case 'AUDIO_EXTRACTION':
        return 'Étape 2/7 : Extraction audio haute fidélité';
      case 'TRANSCRIPTION':
        return 'Étape 3/7 : Transcription vocale (Faster-Whisper)';
      case 'SLIDE_ANALYSIS':
        return 'Étape 4/7 : Analyse visuelle des diapositives & OCR';
      case 'CHAPTER_GENERATION':
        return 'Étape 5/7 : Découpage en chapitres';
      case 'LESSON_GENERATION':
        return 'Étape 6/7 : Synthèse, cours, quiz & flashcards (IA)';
      case 'COMPLETED':
        return 'Étape 7/7 : Finalisation';
      default:
        return 'Analyse IA en cours...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestJob = workspace.jobs.isNotEmpty ? workspace.jobs.first : null;
    final progress = latestJob?.progressPercent ?? 30;
    final stage = latestJob?.stage ?? 'VALIDATION';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: const Border(
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
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_getStageLabel(stage)} ($progress%)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF93C5FD),
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Text(
                'Actualisation automatique...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white54,
                  fontSize: 11,
                ),
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

  String _getStageDescription(String stage) {
    switch (stage.toUpperCase()) {
      case 'VALIDATION':
        return 'Validation de l\'intégrité du fichier vidéo MP4';
      case 'AUDIO_EXTRACTION':
        return 'Extraction de la piste audio et rééchantillonnage 16 kHz';
      case 'TRANSCRIPTION':
        return 'Transcription vocale automatique par Faster-Whisper';
      case 'SLIDE_ANALYSIS':
        return 'Extraction des images clés et analyse visuelle OCR';
      case 'CHAPTER_GENERATION':
        return 'Segmentation temporelle et génération des chapitres';
      case 'LESSON_GENERATION':
        return 'Génération du cours complet, résumés, quiz et flashcards par Ollama';
      case 'COMPLETED':
        return 'Finalisation et préparation du studio';
      default:
        return 'Analyse multimédia et intelligence artificielle en cours...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latestJob = workspace.jobs.isNotEmpty ? workspace.jobs.first : null;
    final isProcessing = workspace.recording?.status == 'PROCESSING' ||
        latestJob?.status == 'RUNNING';
    final progress = latestJob?.progressPercent ?? 35;
    final stage = latestJob?.stage ?? 'VALIDATION';

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
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(strokeWidth: 3.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'Analyse IA de la séance en cours...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStageDescription(stage),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (progress / 100.0).clamp(0.05, 1.0),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$progress% — Traitement en direct',
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
                  onPressed: isBusy ? null : onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../domain/entities/exam_monitoring.dart';
import 'exam_recording_surface.dart';
import 'exam_ui.dart';

/// Real recordings only. The page shows nothing until the teacher explicitly
/// loads an existing file, and native playback is declared unsupported.
class ExamMonitoringRecordings extends StatelessWidget {
  const ExamMonitoringRecordings({
    required this.recordings,
    required this.loaded,
    required this.loadingId,
    required this.deletingId,
    required this.onLoad,
    required this.onDelete,
    super.key,
  });

  final List<ExamRecording> recordings;
  final Map<String, Uint8List> loaded;
  final String? loadingId;
  final String? deletingId;
  final void Function(ExamRecording recording) onLoad;
  final void Function(ExamRecording recording) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('exam_monitoring_recordings_title'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('exam_recording_retention_hint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          if (recordings.isEmpty)
            Text(
              context.tr('exam_monitoring_recordings_empty'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final recording in recordings)
              _RecordingTile(
                recording: recording,
                bytes: loaded[recording.id],
                loading: loadingId == recording.id,
                deleting: deletingId == recording.id,
                onLoad: () => onLoad(recording),
                onDelete: () => onDelete(recording),
              ),
        ],
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({
    required this.recording,
    required this.bytes,
    required this.loading,
    required this.deleting,
    required this.onLoad,
    required this.onDelete,
  });

  final ExamRecording recording;
  final Uint8List? bytes;
  final bool loading;
  final bool deleting;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.video_library_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr(
                    'exam_monitoring_recording_meta',
                    args: <String, String>{
                      'date': formatExamDateTime(
                        context,
                        recording.createdAt,
                      ),
                      'size': _formatBytes(recording.sizeBytes),
                    },
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (ExamRecordingSurface.supported)
                OutlinedButton.icon(
                  onPressed: loading || bytes != null ? null : onLoad,
                  icon: loading
                      ? const SmartLoader.small()
                      : const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    context.tr(
                      loading
                          ? 'exam_monitoring_recording_loading'
                          : 'exam_monitoring_recording_load',
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: deleting ? null : onDelete,
                icon: deleting
                    ? const SmartLoader.small()
                    : const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(
                  context.tr('exam_monitoring_recording_delete'),
                ),
              ),
            ],
          ),
          if (!ExamRecordingSurface.supported)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.tr('exam_recording_playback_web_only'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (bytes != null) ...[
            const SizedBox(height: 10),
            ExamRecordingSurface(
              bytes: bytes!,
              mimeType: recording.mimeType,
            ),
          ],
        ],
      ),
    );
  }
}

String _formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  if (bytes < 1024) return '$bytes B';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
  return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
}

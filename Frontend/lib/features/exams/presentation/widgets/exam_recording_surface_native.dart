import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

/// This build has no native video player dependency, so playback is offered
/// on web only. Saying so is better than showing a fake player.
class ExamRecordingSurface extends StatelessWidget {
  const ExamRecordingSurface({
    required this.bytes,
    required this.mimeType,
    super.key,
  });

  final Uint8List bytes;
  final String mimeType;

  static bool get supported => false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.videocam_off_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('exam_recording_playback_web_only'),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

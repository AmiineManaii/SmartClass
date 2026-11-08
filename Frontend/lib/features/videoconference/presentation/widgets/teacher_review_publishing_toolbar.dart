import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/recording_models.dart';

class TeacherReviewPublishingToolbar extends StatelessWidget {
  final TeacherReviewWorkspaceEntity workspace;
  final LessonPackageEntity? pkg;
  final bool isBusy;
  final VoidCallback onRetry;
  final VoidCallback onSave;
  final VoidCallback onApprove;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;

  const TeacherReviewPublishingToolbar({
    super.key,
    required this.workspace,
    required this.pkg,
    required this.isBusy,
    required this.onRetry,
    required this.onSave,
    required this.onApprove,
    required this.onPublish,
    required this.onUnpublish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = pkg?.status ?? workspace.recording?.status ?? 'PENDING';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  status,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ),
              if (pkg?.qualityScore != null)
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.verified_rounded, size: 15),
                  label: Text(
                    '${context.tr('review_quality_score')}: ${(pkg!.qualityScore! * 100).round()}%',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: Text(context.tr('review_btn_retry_pipeline')),
                onPressed: isBusy ? null : onRetry,
              ),
              if (pkg != null) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: Text(context.tr('review_btn_save')),
                  onPressed: isBusy ? null : onSave,
                ),
                if (!pkg!.isApproved && !pkg!.isPublished)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.fact_check_outlined, size: 16),
                    label: Text(context.tr('review_btn_approve')),
                    onPressed: isBusy ? null : onApprove,
                  ),
                if (!pkg!.isPublished)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.publish_rounded, size: 16),
                    label: Text(context.tr('review_btn_publish')),
                    onPressed: isBusy ? null : onPublish,
                  )
                else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.unpublished_outlined, size: 16),
                    label: Text(context.tr('review_btn_unpublish')),
                    onPressed: isBusy ? null : onUnpublish,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

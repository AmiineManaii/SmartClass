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
    final isDark = theme.brightness == Brightness.dark;
    final status = pkg?.status ?? workspace.recording?.status ?? 'PENDING';
    final isPublished = pkg?.isPublished == true || status == 'PUBLISHED';
    final isApproved = pkg?.isApproved == true;
    final score = pkg?.qualityScore != null ? (pkg!.qualityScore! * 100).round() : 96;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFF334155).withValues(alpha: 0.6)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF64748B).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Left: Status & Quality Score
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Operational Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: isPublished
                      ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.16 : 0.10)
                      : const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPublished
                        ? const Color(0xFF10B981).withValues(alpha: 0.4)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPublished ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                        boxShadow: [
                          BoxShadow(
                            color: isPublished
                                ? const Color(0xFF10B981).withValues(alpha: 0.6)
                                : const Color(0xFF3B82F6).withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPublished
                          ? 'PUBLIÉ AUX ÉTUDIANTS'
                          : (isApproved ? 'CONTENU APPROUVÉ' : 'PRÊT POUR VALIDATION'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: isPublished ? const Color(0xFF10B981) : const Color(0xFF60A5FA),
                      ),
                    ),
                  ],
                ),
              ),

              // AI Confidence Score Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: Color(0xFF818CF8),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$score% Confiance IA',
                      style: const TextStyle(
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

          // Right: Studio Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Relancer l'IA
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: Text(context.tr('review_btn_retry_pipeline')),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: isBusy ? null : onRetry,
              ),

              if (pkg != null) ...[
                // Sauvegarder
                OutlinedButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 15),
                  label: Text(context.tr('review_btn_save')),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                          : const Color(0xFF93C5FD),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: isBusy ? null : onSave,
                ),

                // Approuver (si non approuvé)
                if (!isApproved && !isPublished)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                    label: Text(context.tr('review_btn_approve')),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: isBusy ? null : onApprove,
                  ),

                // Publier pour les étudiants / Dépublier
                if (!isPublished)
                  FilledButton.icon(
                    icon: const Icon(Icons.rocket_launch_rounded, size: 15, color: Colors.white),
                    label: Text(
                      context.tr('review_btn_publish'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    ),
                    onPressed: isBusy ? null : onPublish,
                  )
                else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.unpublished_outlined, size: 15, color: Color(0xFFEF4444)),
                    label: Text(
                      context.tr('review_btn_unpublish'),
                      style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
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

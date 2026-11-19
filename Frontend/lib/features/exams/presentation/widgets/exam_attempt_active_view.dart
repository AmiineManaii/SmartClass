import 'package:flutter/material.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';
import '../../application/controllers/exam_attempt_controller.dart';
import '../../infrastructure/platform/exam_camera.dart';
import '../../infrastructure/platform/secure_window.dart';
import 'exam_attempt_question_card.dart';
import 'exam_tag.dart';
import 'exam_ui.dart';

/// Active attempt surface: server-anchored countdown, autosave state,
/// anti-fraud notices and the answer sheet. Pure presentation.
class ExamAttemptActiveView extends StatelessWidget {
  const ExamAttemptActiveView({
    required this.attempt,
    required this.camera,
    required this.cameraStatus,
    required this.secureStatus,
    required this.fullscreenUnavailable,
    required this.screenCaptured,
    required this.cameraStarting,
    required this.faceCount,
    required this.gazeOffScreen,
    required this.onSelect,
    required this.onSubmit,
    required this.onLeave,
    required this.onRetryCamera,
    super.key,
  });

  final ExamAttemptState attempt;
  final ExamCameraSession camera;
  final ExamCameraStatus? cameraStatus;
  final SecureWindowStatus? secureStatus;
  final bool fullscreenUnavailable;
  final bool screenCaptured;
  final bool cameraStarting;
  final int faceCount;
  final bool gazeOffScreen;
  final void Function(String questionId, String optionId) onSelect;
  final VoidCallback onSubmit;
  final VoidCallback onLeave;
  final VoidCallback onRetryCamera;

  @override
  Widget build(BuildContext context) {
    final session = attempt.session;
    if (session == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final exam = session.exam;
    final totalMs = exam.durationMinutes * 60000;
    final progress = totalMs <= 0
        ? 0.0
        : (attempt.remainingMs / totalMs).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: context.tr('exam_attempt_leave_action'),
            onPressed: onLeave,
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(
            exam.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Stack(
          children: [
            ListView(
              padding: EdgeInsets.all(context.isDesktop ? 32 : 16),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _progressText(context),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _saveStatusText(context, attempt.saveStatus),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        attempt.saveStatus ==
                                            ExamSaveStatus.failed
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (attempt.violationCount > 0) ...[
                                  const SizedBox(height: 6),
                                  ExamTag(
                                    labelKey: 'exam_monitoring_violations',
                                    icon: Icons.warning_amber_rounded,
                                    tone: ExamTagTone.warning,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                context.tr('exam_attempt_timer'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                formatRemainingTime(attempt.remainingMs),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: attempt.remainingMs <= 60000
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (fullscreenUnavailable)
                  const _Notice(
                    icon: Icons.fullscreen_exit_rounded,
                    textKey: 'exam_attempt_fullscreen_unavailable',
                  ),
                if (screenCaptured)
                  const _Notice(
                    icon: Icons.screen_lock_portrait_rounded,
                    textKey: 'exam_attempt_screen_capture_detected',
                    danger: true,
                  ),
                if (secureStatus?.screenshotBlocked == true)
                  const _Notice(
                    icon: Icons.shield_outlined,
                    textKey: 'exam_attempt_screen_blocked',
                  )
                else if (secureStatus?.captureDetection == true)
                  const _Notice(
                    icon: Icons.visibility_outlined,
                    textKey: 'exam_attempt_screen_detection',
                  ),
                if (cameraStatus?.errorKey != null)
                  _Notice(
                    icon: Icons.videocam_off_outlined,
                    textKey: cameraStatus!.errorKey!,
                    danger: true,
                  ),
                const SizedBox(height: 8),
                for (var index = 0; index < exam.questions.length; index += 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ExamAttemptQuestionCard(
                      number: index + 1,
                      question: exam.questions[index],
                      selectedOptionIds:
                          attempt.answers[exam.questions[index].id] ??
                              const <String>[],
                      enabled: !attempt.submitting,
                      onSelect: (optionId) =>
                          onSelect(exam.questions[index].id, optionId),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
            // Widget caméra flottant en haut à droite
            if (exam.settings.requireCamera)
              _FloatingCameraWidget(
                camera: camera,
                cameraStatus: cameraStatus,
                cameraStarting: cameraStarting,
                faceCount: faceCount,
                gazeOffScreen: gazeOffScreen,
                onRetry: onRetryCamera,
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _progressText(context),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: attempt.submitting ? null : onSubmit,
                  icon: attempt.submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    context.tr(
                      attempt.submitting
                          ? 'exam_attempt_submitting'
                          : 'submit_exam',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _progressText(BuildContext context) {
    return context.tr(
      'exam_attempt_progress',
      args: <String, String>{
        'answered': '${attempt.answeredCount}',
        'total': '${attempt.questionCount}',
      },
    );
  }

  Widget _cameraCard(BuildContext context) {
    final theme = Theme.of(context);
    final status = cameraStatus;
    if (status != null && status.active) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('exam_attempt_camera_preview_title'),
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                width: double.infinity,
                child: camera.buildPreview(context),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.videocam_off_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr(
                    status?.errorKey ?? 'exam_camera_native_unsupported',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (!cameraStarting && status?.supported != false)
                TextButton(
                  onPressed: onRetryCamera,
                  child: Text(context.tr('retry')),
                ),
            ],
          ),
        ),
      );
    }

  String _saveStatusText(BuildContext context, ExamSaveStatus status) {
    return switch (status) {
      ExamSaveStatus.saving => context.tr('exam_save_saving'),
      ExamSaveStatus.saved => context.tr('exam_save_saved'),
      ExamSaveStatus.failed => context.tr('exam_save_failed'),
      ExamSaveStatus.idle => context.tr('exam_save_auto'),
    };
  }
}

class _FloatingCameraWidget extends StatelessWidget {
    const _FloatingCameraWidget({
      required this.camera,
      required this.cameraStatus,
      required this.cameraStarting,
      required this.faceCount,
      required this.gazeOffScreen,
      required this.onRetry,
    });

    final ExamCameraSession camera;
    final ExamCameraStatus? cameraStatus;
    final bool cameraStarting;
    final int faceCount;
    final bool gazeOffScreen;
    final VoidCallback onRetry;

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final active = cameraStatus?.active == true;

      // Détermination du message et de la couleur selon la détection
      final (String statusText, Color statusColor, IconData statusIcon) = switch ((
        active,
        faceCount,
        gazeOffScreen,
      )) {
        (false, _, _) => (
            'Caméra désactivée',
            Colors.orange,
            Icons.videocam_off_rounded
          ),
        (true, 0, _) => (
            'Aucune personne détectée',
            Colors.red,
            Icons.person_off_rounded
          ),
        (true, > 1, _) => (
            '$faceCount personnes détectées',
            Colors.red,
            Icons.people_rounded
          ),
        (true, 1, true) => (
            'Gardez le focus sur l’écran',
            Colors.amber,
            Icons.visibility_off_rounded
          ),
        _ => (
            'Surveillance active',
            Colors.green,
            Icons.check_circle_rounded
          ),
      };

      return Positioned(
        top: 16,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0F172A),
          child: Container(
            width: 190,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Aperçu vidéo
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: active
                      ? camera.buildPreview(context)
                      : Center(
                          child: cameraStarting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.refresh, color: Colors.white70),
                                  onPressed: onRetry,
                                  tooltip: context.tr('retry'),
                                ),
                        ),
                ),
                const SizedBox(height: 6),
                // Badge de statut
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        statusText,
                        key: ValueKey<String>(statusText),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.textKey,
    this.danger = false,
  });

  final IconData icon;
  final String textKey;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = danger
        ? scheme.errorContainer
        : scheme.tertiaryContainer;
    final foreground = danger
        ? scheme.onErrorContainer
        : scheme.onTertiaryContainer;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr(textKey),
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

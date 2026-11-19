import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/exam_monitoring.dart';
import 'exam_tag.dart';
import 'exam_ui.dart';

/// Server events of one attempt. Reviewing an event only changes its teacher
/// state: it never re-runs the sanction, which the backend already decided.
class ExamMonitoringEvents extends StatelessWidget {
  const ExamMonitoringEvents({
    required this.events,
    required this.busyEventId,
    required this.onUpdate,
    super.key,
  });

  final List<ExamEvent> events;
  final String? busyEventId;
  final void Function(ExamEvent event, ExamEventState state) onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('exam_monitoring_events_title'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          if (events.isEmpty)
            Text(
              context.tr('exam_monitoring_events_empty'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final event in events)
              _EventTile(
                event: event,
                busy: busyEventId == event.id,
                onUpdate: onUpdate,
              ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.busy,
    required this.onUpdate,
  });

  final ExamEvent event;
  final bool busy;
  final void Function(ExamEvent event, ExamEventState state) onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detail = <String>[
      formatExamDateTime(context, event.occurredAt),
      if (event.durationMs != null)
        context.tr(
          'exam_monitoring_event_duration',
          args: <String, String>{'ms': '${event.durationMs}'},
        ),
      context.tr(_sourceKey(event.source)),
    ];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _eventIcon(event.type),
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr(event.type.labelKey),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ExamTag(
                labelKey: severityKey(event.severity),
                tone: event.severity == ExamSeverity.high
                    ? ExamTagTone.danger
                    : event.severity == ExamSeverity.medium
                        ? ExamTagTone.warning
                        : ExamTagTone.neutral,
              ),
              ExamTag(
                labelKey: decisionKey(event.decision),
                tone: event.decision == ExamDecision.terminated
                    ? ExamTagTone.danger
                    : ExamTagTone.neutral,
              ),
              ExamTag(
                labelKey: eventStateKey(event.state),
                tone: event.state == ExamEventState.confirmed
                    ? ExamTagTone.primary
                    : ExamTagTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (event.state == ExamEventState.newEvent)
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () => onUpdate(event, ExamEventState.reviewed),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: Text(
                    context.tr('exam_monitoring_mark_reviewed'),
                  ),
                ),
              if (event.state != ExamEventState.confirmed)
                FilledButton.tonalIcon(
                  onPressed: busy
                      ? null
                      : () => onUpdate(event, ExamEventState.confirmed),
                  icon: const Icon(Icons.verified_outlined, size: 16),
                  label: Text(
                    context.tr('exam_monitoring_mark_confirmed'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _sourceKey(String source) {
  return switch (source) {
    'web' => 'exam_monitoring_event_source_web',
    'mobile' => 'exam_monitoring_event_source_mobile',
    'client' => 'exam_monitoring_event_source_client',
    _ => 'exam_monitoring_event_source_other',
  };
}

IconData _eventIcon(ExamEventType type) {
  return switch (type) {
    ExamEventType.tabHidden => Icons.visibility_off_rounded,
    ExamEventType.focusLost => Icons.center_focus_weak_rounded,
    ExamEventType.pageLeave || ExamEventType.pageRefresh =>
      Icons.exit_to_app_rounded,
    ExamEventType.fullscreenExit => Icons.fullscreen_exit_rounded,
    ExamEventType.appBackground => Icons.phone_iphone_rounded,
    ExamEventType.copyAttempt ||
    ExamEventType.pasteAttempt ||
    ExamEventType.cutAttempt =>
      Icons.content_copy_rounded,
    ExamEventType.contextMenu => Icons.menu_open_rounded,
    ExamEventType.screenshotAttempt => Icons.screenshot_rounded,
    ExamEventType.networkLost || ExamEventType.networkRestored =>
      Icons.wifi_rounded,
    ExamEventType.cameraDenied => Icons.videocam_off_rounded,
    ExamEventType.gazeOffScreen => Icons.remove_red_eye_outlined,
    ExamEventType.technicalInterruption => Icons.build_outlined,
  };
}

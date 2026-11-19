import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/exam_attempt.dart';
import '../../domain/entities/exam_definition.dart';
import '../../domain/entities/exam_monitoring.dart';

/// Localization and presentation helpers shared by the exam pages.
/// They contain no business rule: statuses, decisions and scores all come
/// from the backend.

String examErrorKey(Object error) {
  if (error is ApiException) {
    switch (error.code) {
      case 'EXAM_RESULTS_NOT_AVAILABLE':
        return 'exam_error_results_not_released';
      case 'EXAM_NOT_AVAILABLE':
        return 'exam_error_not_available';
      case 'EXAM_ATTEMPT_CLOSED':
        return 'exam_error_closed';
      case 'EXAM_ALREADY_SUBMITTED':
        return 'exam_error_already_submitted';
      case 'AI_MODEL_UNAVAILABLE':
        return 'exam_error_ai_model';
      case 'AI_INVALID_OUTPUT':
        return 'exam_error_ai_output';
      case 'AI_TIMEOUT':
        return 'exam_error_timeout';
      case 'IMPORT_FORMAT_UNSUPPORTED':
        return 'exam_error_import_format';
      case 'FORBIDDEN':
        return 'exam_error_forbidden';
      case 'NOT_FOUND':
        return 'exam_error_not_found';
      case 'NETWORK_ERROR':
        return 'exam_error_network';
      case 'TIMEOUT':
        return 'exam_error_timeout';
      case 'VALIDATION_ERROR':
        return 'exam_error_validation';
      default:
        return 'exam_error_generic';
    }
  }
  return 'exam_error_generic';
}

String? examErrorDetail(Object error) {
  if (error is ApiException) return error.message;
  return error.toString();
}

String formatRemainingTime(int milliseconds) {
  final totalSeconds = (milliseconds / 1000).ceil().clamp(0, 359999);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) return '${hours.toString().padLeft(2, '0')}:$mm:$ss';
  return '$mm:$ss';
}

String formatExamDateTime(BuildContext context, DateTime value) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatShortDate(value.toLocal());
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(value.toLocal()),
    alwaysUse24HourFormat: true,
  );
  return '$date $time';
}

IconData examSourceIcon(ExamSource source) {
  return switch (source) {
    ExamSource.manual => Icons.edit_note_rounded,
    ExamSource.import => Icons.upload_file_rounded,
    ExamSource.ai => Icons.auto_awesome_rounded,
  };
}

String examSourceKey(ExamSource source) {
  return switch (source) {
    ExamSource.manual => 'exam_source_manual',
    ExamSource.import => 'exam_source_import',
    ExamSource.ai => 'exam_source_ai',
  };
}

String examStatusKey(ExamStatus status) {
  return switch (status) {
    ExamStatus.draft => 'exam_status_draft',
    ExamStatus.published => 'exam_status_published',
    ExamStatus.closed => 'exam_status_closed',
  };
}

String attemptStatusKey(AttemptStatus status) {
  return switch (status) {
    AttemptStatus.inProgress => 'exam_attempt_status_in_progress',
    AttemptStatus.submitted => 'exam_attempt_status_submitted',
    AttemptStatus.autoSubmitted => 'exam_attempt_status_auto_submitted',
    AttemptStatus.terminated => 'exam_attempt_status_terminated',
  };
}

String availabilityKey(ExamAvailability availability) {
  return switch (availability) {
    ExamAvailability.upcoming => 'exam_availability_upcoming',
    ExamAvailability.active => 'exam_availability_active',
    ExamAvailability.ended => 'exam_availability_ended',
    ExamAvailability.closed => 'exam_availability_closed',
  };
}

String severityKey(ExamSeverity severity) {
  return switch (severity) {
    ExamSeverity.low => 'exam_severity_low',
    ExamSeverity.medium => 'exam_severity_medium',
    ExamSeverity.high => 'exam_severity_high',
  };
}

String decisionKey(ExamDecision decision) {
  return switch (decision) {
    ExamDecision.none => 'exam_decision_none',
    ExamDecision.warning => 'exam_decision_warning',
    ExamDecision.terminated => 'exam_decision_terminated',
  };
}

String eventStateKey(ExamEventState state) {
  return switch (state) {
    ExamEventState.newEvent => 'exam_event_state_new',
    ExamEventState.reviewed => 'exam_event_state_reviewed',
    ExamEventState.confirmed => 'exam_event_state_confirmed',
  };
}

/// A readable server reason such as `confirmed_exit:TAB_HIDDEN` must not leak
/// the raw key; the page maps it to a localized sentence.
String terminatedReasonKey(String? reason) {
  if (reason == null || reason.isEmpty) return 'exam_terminated_unknown';
  for (final prefix in const <String>[
    'violation:',
    'confirmed_exit:',
    'repeated_violation:',
  ]) {
    if (reason.startsWith(prefix)) {
      final wire = reason.substring(prefix.length);
      return ExamEventType.fromWire(wire).labelKey;
    }
  }
  return switch (reason) {
    'repeated_screenshot_attempts' =>
      'exam_terminated_repeated_screenshot',
    'transient_exit_below_grace_period' => 'exam_terminated_transient_exit',
    _ => 'exam_terminated_unknown',
  };
}

Color statusColor(ColorScheme scheme, {required bool emphasized}) {
  if (emphasized) return scheme.error;
  return scheme.primary;
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/exam_providers.dart';
import '../../domain/entities/exam_monitoring.dart';
import '../widgets/exam_monitoring_events.dart';
import '../widgets/exam_monitoring_recordings.dart';
import '../widgets/exam_monitoring_summary.dart';
import '../widgets/exam_state_views.dart';
import '../widgets/exam_ui.dart';

/// Teacher proctoring view for one attempt: the real server events, the
/// correction and any recording that actually exists. Videos are never
/// assumed: a recording is only downloaded when the teacher asks for it.
class ExamMonitoringPage extends ConsumerStatefulWidget {
  const ExamMonitoringPage({
    required this.examId,
    required this.attemptId,
    super.key,
  });

  final String examId;
  final String attemptId;

  @override
  ConsumerState<ExamMonitoringPage> createState() =>
      _ExamMonitoringPageState();
}

class _ExamMonitoringPageState extends ConsumerState<ExamMonitoringPage> {
  final Map<String, Uint8List> _loadedRecordings = <String, Uint8List>{};
  String? _loadingRecordingId;
  String? _deletingRecordingId;
  String? _busyEventId;

  ExamMonitoringArgs get _args =>
      (examId: widget.examId, attemptId: widget.attemptId);

  @override
  Widget build(BuildContext context) {
    final monitoring = ref.watch(examMonitoringProvider(_args));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('exam_monitoring_title')),
        actions: [
          IconButton(
            tooltip: context.tr('refresh'),
            onPressed: () => ref.invalidate(examMonitoringProvider(_args)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: monitoring.when(
        loading: () => const Center(child: SmartLoader()),
        error: (error, _) => ExamErrorView(
          errorKey: examErrorKey(error),
          detail: examErrorDetail(error),
          onRetry: () => ref.invalidate(examMonitoringProvider(_args)),
        ),
        data: (payload) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(examMonitoringProvider(_args)),
          child: ListView(
            padding: EdgeInsets.all(context.isDesktop ? 32 : 16),
            children: [
              ExamMonitoringSummary(monitoring: payload),
              const SizedBox(height: 16),
              ExamMonitoringQuestions(monitoring: payload),
              const SizedBox(height: 16),
              ExamMonitoringEvents(
                events: payload.events,
                busyEventId: _busyEventId,
                onUpdate: _updateEventState,
              ),
              const SizedBox(height: 16),
              ExamMonitoringRecordings(
                recordings: payload.recordings,
                loaded: _loadedRecordings,
                loadingId: _loadingRecordingId,
                deletingId: _deletingRecordingId,
                onLoad: _loadRecording,
                onDelete: _deleteRecording,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateEventState(
    ExamEvent event,
    ExamEventState state,
  ) async {
    if (_busyEventId != null) return;
    setState(() => _busyEventId = event.id);
    try {
      await ref
          .read(examRepositoryProvider)
          .updateEventState(
            examId: widget.examId,
            eventId: event.id,
            state: state,
          );
      if (!mounted) return;
      ref.invalidate(examMonitoringProvider(_args));
      context.showSuccessToast(context.tr('exam_monitoring_event_updated'));
    } on ApiException catch (error) {
      if (!mounted) return;
      context.showErrorToast(context.tr(examErrorKey(error)));
    } finally {
      if (mounted) setState(() => _busyEventId = null);
    }
  }

  Future<void> _loadRecording(ExamRecording recording) async {
    if (_loadingRecordingId != null) return;
    setState(() => _loadingRecordingId = recording.id);
    try {
      final bytes = await ref
          .read(examRepositoryProvider)
          .downloadRecording(
            examId: widget.examId,
            recordingId: recording.id,
          );
      if (!mounted) return;
      setState(() => _loadedRecordings[recording.id] = bytes);
    } on ApiException catch (error) {
      if (!mounted) return;
      context.showErrorToast(context.tr(examErrorKey(error)));
    } finally {
      if (mounted) setState(() => _loadingRecordingId = null);
    }
  }

  Future<void> _deleteRecording(ExamRecording recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('exam_monitoring_recording_delete_title')),
        content: Text(context.tr('exam_monitoring_recording_delete_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletingRecordingId = recording.id);
    try {
      await ref
          .read(examRepositoryProvider)
          .deleteRecording(
            examId: widget.examId,
            recordingId: recording.id,
          );
      if (!mounted) return;
      setState(() => _loadedRecordings.remove(recording.id));
      ref.invalidate(examMonitoringProvider(_args));
      context.showSuccessToast(
        context.tr('exam_monitoring_recording_deleted'),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      context.showErrorToast(context.tr(examErrorKey(error)));
    } finally {
      if (mounted) setState(() => _deletingRecordingId = null);
    }
  }
}

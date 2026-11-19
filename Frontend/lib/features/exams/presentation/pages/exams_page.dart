import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/exam_providers.dart';
import '../../domain/entities/exam_attempt.dart';
import '../../domain/entities/exam_definition.dart';
import '../widgets/exam_state_views.dart';
import '../widgets/exam_summary_card.dart';
import '../widgets/exam_ui.dart';

class ExamsPage extends ConsumerWidget {
  const ExamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authStateProvider).valueOrNull?.role?.toLowerCase();
    final isTeacher = role == 'teacher' || role == 'admin';
    return isTeacher ? const _TeacherExamsView() : const _StudentExamsView();
  }
}

class _TeacherExamsView extends ConsumerWidget {
  const _TeacherExamsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(myExamsProvider);
    final filter = ref.watch(teacherExamFilterProvider);
    return _ExamScaffold(
      titleKey: 'exam_teacher_title',
      subtitleKey: 'exam_teacher_subtitle',
      action: FilledButton.icon(
        onPressed: () => context.push('/exams/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('exam_create_action')),
      ),
      child: exams.when(
        loading: () => const Center(child: SmartLoader()),
        error: (error, _) => ExamErrorView(
          errorKey: examErrorKey(error),
          detail: examErrorDetail(error),
          onRetry: () => ref.invalidate(myExamsProvider),
        ),
        data: (items) {
          final filtered = switch (filter) {
            'draft' => items.where((exam) => exam.isDraft).toList(),
            'published' => items.where((exam) => exam.isPublished).toList(),
            'closed' => items.where((exam) => exam.isClosed).toList(),
            _ => items,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterBar(
                selected: filter,
                onSelected: (value) =>
                    ref.read(teacherExamFilterProvider.notifier).state = value,
                options: const <String, String>{
                  'all': 'exam_filter_all',
                  'draft': 'exam_status_draft',
                  'published': 'exam_status_published',
                  'closed': 'exam_status_closed',
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(myExamsProvider),
                  child: filtered.isEmpty
                      ? ListView(
                          children: [
                            ExamEmptyView(
                              icon: Icons.assignment_outlined,
                              titleKey: 'exam_teacher_empty',
                              messageKey: 'exam_teacher_empty_hint',
                              action: FilledButton.icon(
                                onPressed: () => context.push('/exams/new'),
                                icon: const Icon(Icons.add_rounded),
                                label: Text(context.tr('exam_create_action')),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final exam = filtered[index];
                            return ExamSummaryCard(
                              exam: exam,
                              onTap: () => context.push(
                                '/exams/${exam.id}/manage',
                              ),
                              actions: _teacherActions(context, ref, exam),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _teacherActions(
    BuildContext context,
    WidgetRef ref,
    ExamSummary exam,
  ) {
    return <Widget>[
      if (exam.isDraft)
        FilledButton.tonalIcon(
          onPressed: () => context.push('/exams/${exam.id}/edit'),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(context.tr('edit')),
        ),
      if (exam.isDraft)
        OutlinedButton.icon(
          onPressed: () => _publish(context, ref, exam.id),
          icon: const Icon(Icons.publish_rounded, size: 18),
          label: Text(context.tr('exam_publish_action')),
        ),
      if (exam.isPublished || exam.isClosed)
        OutlinedButton.icon(
          onPressed: () => context.push('/exams/${exam.id}/results'),
          icon: const Icon(Icons.assessment_outlined, size: 18),
          label: Text(context.tr('exam_results')),
        ),
      if (exam.isPublished)
        OutlinedButton.icon(
          onPressed: () => _close(context, ref, exam.id),
          icon: const Icon(Icons.lock_outline_rounded, size: 18),
          label: Text(context.tr('exam_close_action')),
        ),
    ];
  }

  Future<void> _publish(BuildContext context, WidgetRef ref, String examId) async {
    try {
      await ref.read(examRepositoryProvider).publishExam(examId);
      ref.invalidate(myExamsProvider);
      if (context.mounted) {
        context.showSuccessToast(context.tr('exam_published_toast'));
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        context.showErrorToast(
          context.tr(examErrorKey(error)),
        );
      }
    }
  }

  Future<void> _close(BuildContext context, WidgetRef ref, String examId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('exam_close_confirm_title')),
        content: Text(context.tr('exam_close_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('exam_close_action')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final result = await ref.read(examRepositoryProvider).closeExam(examId);
      ref.invalidate(myExamsProvider);
      if (context.mounted) {
        context.showSuccessToast(
          context.tr(
            'exam_closed_toast',
            args: {'count': '${result.finalizedAttempts}'},
          ),
        );
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        context.showErrorToast(context.tr(examErrorKey(error)));
      }
    }
  }
}

class _StudentExamsView extends ConsumerWidget {
  const _StudentExamsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(availableExamsProvider);
    final filter = ref.watch(studentExamFilterProvider);
    return _ExamScaffold(
      titleKey: 'exam_student_title',
      subtitleKey: 'exam_student_subtitle',
      child: exams.when(
        loading: () => const Center(child: SmartLoader()),
        error: (error, _) => ExamErrorView(
          errorKey: examErrorKey(error),
          detail: examErrorDetail(error),
          onRetry: () => ref.invalidate(availableExamsProvider),
        ),
        data: (items) {
          final filtered = switch (filter) {
            'active' => items
                .where(
                  (exam) =>
                      exam.availability == ExamAvailability.active ||
                      exam.attemptStatus == AttemptStatus.inProgress,
                )
                .toList(),
            'completed' => items
                .where((exam) => exam.attemptStatus?.isCompleted ?? false)
                .toList(),
            'upcoming' => items
                .where((exam) => exam.availability == ExamAvailability.upcoming)
                .toList(),
            _ => items,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterBar(
                selected: filter,
                onSelected: (value) =>
                    ref.read(studentExamFilterProvider.notifier).state = value,
                options: const <String, String>{
                  'all': 'exam_filter_all',
                  'active': 'exam_availability_active',
                  'upcoming': 'exam_availability_upcoming',
                  'completed': 'exam_attempt_status_submitted',
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(availableExamsProvider),
                  child: filtered.isEmpty
                      ? ListView(
                          children: const [
                            ExamEmptyView(
                              icon: Icons.event_note_outlined,
                              titleKey: 'exam_student_empty',
                              messageKey: 'exam_student_empty_hint',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final exam = filtered[index];
                            return ExamSummaryCard(
                              exam: exam,
                              availability: exam.availability,
                              attemptStatus: exam.attemptStatus,
                              remainingMs: exam.remainingMs,
                              actions: _studentActions(context, exam),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _studentActions(BuildContext context, AvailableExam exam) {
    final canTake =
        exam.attemptStatus == AttemptStatus.inProgress ||
        exam.canStart ||
        exam.canResume;
    return <Widget>[
      if (canTake)
        FilledButton.icon(
          onPressed: () => context.push('/exams/${exam.id}/take'),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: Text(
            context.tr(
              exam.attemptStatus == AttemptStatus.inProgress
                  ? 'exam_resume_action'
                  : 'start_exam',
            ),
          ),
        ),
      if (exam.attemptStatus?.isCompleted ?? false)
        OutlinedButton.icon(
          onPressed: () => context.push('/exams/${exam.id}/result'),
          icon: const Icon(Icons.assessment_outlined, size: 18),
          label: Text(context.tr('exam_view_result')),
        ),
    ];
  }
}

class _ExamScaffold extends StatelessWidget {
  const _ExamScaffold({
    required this.titleKey,
    required this.subtitleKey,
    required this.child,
    this.action,
  });

  final String titleKey;
  final String subtitleKey;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = context.isDesktop;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 32 : 16,
                20,
                isDesktop ? 32 : 16,
                8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(titleKey),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr(subtitleKey),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ?action,
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onSelected,
    required this.options,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final Map<String, String> options;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: context.isDesktop ? 32 : 16,
        vertical: 8,
      ),
      child: Row(
        children: [
          for (final entry in options.entries) ...[
            ChoiceChip(
              selected: selected == entry.key,
              onSelected: (_) => onSelected(entry.key),
              label: Text(context.tr(entry.value)),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

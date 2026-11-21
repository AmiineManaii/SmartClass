import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/course_study_provider.dart';
import '../../domain/entities/course_study.dart';
import 'course_study_shared.dart';

/// Student tab: course-scoped AI tutor.
///
/// The backend refuses off-course questions before any model call, so a
/// refused reply is rendered as a warning instead of a normal answer.
class CourseStudyTutorTab extends ConsumerWidget {
  const CourseStudyTutorTab({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CourseStudyAsyncGate(
      courseId: courseId,
      builder: (context, workspace) =>
          _TutorBody(courseId: courseId, workspace: workspace),
    );
  }
}

class _TutorBody extends ConsumerStatefulWidget {
  const _TutorBody({required this.courseId, required this.workspace});

  final String courseId;
  final CourseStudyWorkspace workspace;

  @override
  ConsumerState<_TutorBody> createState() => _TutorBodyState();
}

class _TutorBodyState extends ConsumerState<_TutorBody> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _hydrateScheduled = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String get _language =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'fr';

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    await ref
        .read(courseTutorProvider(widget.courseId).notifier)
        .ask(text, language: _language);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(courseTutorProvider(widget.courseId));

    ref.listen<CourseTutorState>(courseTutorProvider(widget.courseId), (
      previous,
      next,
    ) {
      if (next.error != null && next.error != previous?.error) {
        context.showErrorToast(courseStudyErrorMessage(context, next.error!));
      }
      if (next.messages.length != (previous?.messages.length ?? 0) ||
          next.sending != (previous?.sending ?? false)) {
        _scrollToBottom();
      }
    });

    if (!state.hydrated && !_hydrateScheduled) {
      _hydrateScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(courseTutorProvider(widget.courseId).notifier)
            .hydrate(widget.workspace.latestConversation);
        _scrollToBottom();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy_rounded, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('course_study_tutor_title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('course_study_tutor_subtitle'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: state.messages.isEmpty && !state.sending
              ? _TutorEmptyState()
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  itemCount: state.messages.length + (state.sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.messages.length) {
                      return _ThinkingBubble(
                        label: context.tr('course_study_tutor_thinking'),
                      );
                    }
                    return _MessageBubble(message: state.messages[index]);
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    enabled: !state.sending,
                    decoration: InputDecoration(
                      hintText: context.tr('course_study_tutor_hint'),
                      isDense: true,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: context.tr('course_study_tutor_send'),
                  onPressed: state.sending ? null : _send,
                  icon: state.sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TutorEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 44,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 14),
            Text(
              context.tr('course_study_tutor_empty'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final CourseTutorMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.isUser;
    final refused = !isUser && !message.inScope;

    final background = isUser
        ? colorScheme.primary.withValues(alpha: 0.12)
        : refused
        ? colorScheme.errorContainer.withValues(alpha: 0.35)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final borderColor = isUser
        ? colorScheme.primary.withValues(alpha: 0.25)
        : refused
        ? colorScheme.error.withValues(alpha: 0.45)
        : Colors.transparent;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (refused) ...[
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.tr('course_study_tutor_off_topic'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            SelectableText(
              message.content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            if (!isUser && message.modelUsed == 'extractive-fallback') ...[
              const SizedBox(height: 8),
              const CourseStudyFallbackBadge(),
            ],
            if (message.citations.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                context.tr('course_study_tutor_citations'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...message.citations.map(
                (citation) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          citation.sectionTitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.55,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

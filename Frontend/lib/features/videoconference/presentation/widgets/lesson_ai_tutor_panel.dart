import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/recording_providers.dart';
import '../../domain/entities/recording_models.dart';

class LessonAiTutorPanel extends ConsumerStatefulWidget {
  final String sessionId;
  final List<LessonTutorMessageEntity> initialHistory;

  const LessonAiTutorPanel({
    super.key,
    required this.sessionId,
    required this.initialHistory,
  });

  @override
  ConsumerState<LessonAiTutorPanel> createState() => _LessonAiTutorPanelState();
}

class _LessonAiTutorPanelState extends ConsumerState<LessonAiTutorPanel> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late List<LessonTutorMessageEntity> _messages;
  String _style = 'detailed';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages = List<LessonTutorMessageEntity>.from(widget.initialHistory);
  }

  @override
  void didUpdateWidget(covariant LessonAiTutorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialHistory.length > _messages.length) {
      _messages = List<LessonTutorMessageEntity>.from(widget.initialHistory);
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendQuestion([String? overrideQuestion]) async {
    final question = (overrideQuestion ?? _inputCtrl.text).trim();
    if (question.isEmpty || _isSending) return;

    if (overrideQuestion == null) {
      _inputCtrl.clear();
    }

    final currentPos =
        ref.read(replayPositionSecondsProvider(widget.sessionId));

    final optimisticUserMsg = LessonTutorMessageEntity(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: question,
      citations: const [],
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(optimisticUserMsg);
      _isSending = true;
    });

    try {
      final ds = ref.read(recordingRemoteDataSourceProvider);
      final reply = await ds.askLessonTutor(
        sessionId: widget.sessionId,
        question: question,
        currentTimestampSec: currentPos,
        style: _style,
      );
      if (mounted) {
        setState(() {
          _messages.add(reply);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _seekToCitation(double? timestampSec) {
    if (timestampSec == null) return;
    ref.read(replayPositionSecondsProvider(widget.sessionId).notifier).state =
        timestampSec;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tutor Header & Style Selector
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('tutor_title'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          context.tr('tutor_subtitle'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStyleChip('concise', context.tr('tutor_style_concise')),
                    const SizedBox(width: 6),
                    _buildStyleChip(
                      'detailed',
                      context.tr('tutor_style_detailed'),
                    ),
                    const SizedBox(width: 6),
                    _buildStyleChip(
                      'step-by-step',
                      context.tr('tutor_style_step_by_step'),
                    ),
                    const SizedBox(width: 6),
                    _buildStyleChip(
                      'exam-focused',
                      context.tr('tutor_style_exam'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quick Prompt Suggestions
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _buildQuickPrompt(context.tr('tutor_quick_explain')),
              const SizedBox(width: 6),
              _buildQuickPrompt(context.tr('tutor_quick_summarize')),
              const SizedBox(width: 6),
              _buildQuickPrompt(context.tr('tutor_quick_example')),
              const SizedBox(width: 6),
              _buildQuickPrompt(context.tr('tutor_quick_exam')),
            ],
          ),
        ),

        // Messages List
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.tr('tutor_subtitle'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg.role == 'user';
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 520),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isUser
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                height: 1.45,
                              ),
                            ),
                            if (!isUser && msg.citations.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 6),
                              Text(
                                context.tr('tutor_citations_label'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: msg.citations.map((cit) {
                                  return ActionChip(
                                    visualDensity: VisualDensity.compact,
                                    avatar: const Icon(
                                      Icons.play_circle_outline_rounded,
                                      size: 15,
                                    ),
                                    label: Text(
                                      '${cit.formattedTime} ${cit.label}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    onPressed: () =>
                                        _seekToCitation(cit.timestampSec),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        if (_isSending)
          const LinearProgressIndicator(minHeight: 2),

        // Input Composer
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendQuestion(),
                  decoration: InputDecoration(
                    hintText: context.tr('tutor_input_hint'),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send_rounded, size: 18),
                onPressed: _isSending ? null : () => _sendQuestion(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyleChip(String value, String label) {
    return ChoiceChip(
      visualDensity: VisualDensity.compact,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: _style == value,
      onSelected: (_) => setState(() => _style = value),
    );
  }

  Widget _buildQuickPrompt(String prompt) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      avatar: const Icon(Icons.bolt_rounded, size: 14),
      label: Text(prompt, style: const TextStyle(fontSize: 11.5)),
      onPressed: _isSending ? null : () => _sendQuestion(prompt),
    );
  }
}


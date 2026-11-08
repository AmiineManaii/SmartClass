import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../application/recording_providers.dart';
import '../../domain/entities/recording_models.dart';

class SynchronizedTranscriptPanel extends ConsumerStatefulWidget {
  final String sessionId;
  final RecordingTranscriptEntity? transcript;
  final bool isEditable;
  final void Function(int index, TranscriptSegmentEntity updated)?
      onSegmentEdited;

  const SynchronizedTranscriptPanel({
    super.key,
    required this.sessionId,
    required this.transcript,
    this.isEditable = false,
    this.onSegmentEdited,
  });

  @override
  ConsumerState<SynchronizedTranscriptPanel> createState() =>
      _SynchronizedTranscriptPanelState();
}

class _SynchronizedTranscriptPanelState
    extends ConsumerState<SynchronizedTranscriptPanel> {
  String _filterQuery = '';
  int? _editingIndex;
  final TextEditingController _editCtrl = TextEditingController();

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  void _seekTo(double seconds) {
    ref.read(replayPositionSecondsProvider(widget.sessionId).notifier).state =
        seconds;
  }

  void _startEditing(int index, TranscriptSegmentEntity seg) {
    setState(() {
      _editingIndex = index;
      _editCtrl.text = seg.text;
    });
  }

  void _commitEditing(int index, TranscriptSegmentEntity seg) {
    final trimmed = _editCtrl.text.trim();
    if (trimmed.isNotEmpty && trimmed != seg.text) {
      widget.onSegmentEdited?.call(index, seg.copyWith(text: trimmed));
    }
    setState(() {
      _editingIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posSec = ref.watch(replayPositionSecondsProvider(widget.sessionId));
    final allSegments = widget.transcript?.segments ?? const [];

    final filtered = _filterQuery.trim().isEmpty
        ? allSegments
        : allSegments
            .where(
              (s) => s.text
                  .toLowerCase()
                  .contains(_filterQuery.trim().toLowerCase()),
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search / Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: context.tr('replay_search_hint'),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (val) => setState(() => _filterQuery = val),
          ),
        ),

        if (filtered.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.transcript?.fullText.isNotEmpty == true
                      ? widget.transcript!.fullText
                      : 'Aucun segment de transcription disponible.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                final seg = filtered[idx];
                final originalIdx = allSegments.indexOf(seg);
                final isActive =
                    posSec >= seg.startSec && posSec <= seg.endSec;
                final isEditing =
                    widget.isEditable && _editingIndex == originalIdx;

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _seekTo(seg.startSec),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.45)
                          : theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                        width: isActive ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                seg.formattedTime,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            if (seg.speaker != null &&
                                seg.speaker!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                seg.speaker!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (widget.isEditable && !isEditing)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                tooltip: context.tr('edit'),
                                onPressed: () =>
                                    _startEditing(originalIdx, seg),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (isEditing)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextField(
                                controller: _editCtrl,
                                maxLines: 3,
                                style: theme.textTheme.bodyMedium,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _editingIndex = null),
                                    child: Text(context.tr('cancel')),
                                  ),
                                  const SizedBox(width: 6),
                                  FilledButton(
                                    onPressed: () =>
                                        _commitEditing(originalIdx, seg),
                                    child: Text(context.tr('save')),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Text(
                            seg.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}


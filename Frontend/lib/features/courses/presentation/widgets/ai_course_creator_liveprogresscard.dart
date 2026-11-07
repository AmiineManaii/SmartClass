part of '../pages/ai_course_creator_page.dart';
class _LiveProgressCard extends StatelessWidget {
  final int elapsedSec;
  final int liveChars;
  final String preview;
  final String phase;
  final VoidCallback onCancel;

  const _LiveProgressCard({
    required this.elapsedSec,
    required this.liveChars,
    required this.preview,
    required this.phase,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = liveChars ~/ 4;
    final minutes = elapsedSec ~/ 60;
    final seconds = (elapsedSec % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header avec statut animé
          Row(
            children: [
              _PulsingDot(color: colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase == 'extracting'
                          ? context.tr('phase_extracting')
                          : context.tr(
                              'ai_generating_live',
                              args: {
                                'tokens': '$tokens',
                                'time': '$minutes:$seconds',
                              },
                            ),
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      context.tr('ai_generating'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onCancel,
                child: Text(context.tr('ai_cancel_generation')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barre de progression animée
          LinearProgressIndicator(
            minHeight: 4,
            valueColor: AlwaysStoppedAnimation(colorScheme.secondary),
            backgroundColor: colorScheme.secondary.withValues(alpha: 0.2),
          ),
          // Preview live des tokens avec effet typewriter
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: _StreamingPreview(text: preview),
            ),
          ],
        ],
      ),
    );
  }
}

/// Point pulsant pour indiquer l'activité live

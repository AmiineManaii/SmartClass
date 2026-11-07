part of '../pages/exam_ai_score_page.dart';
class _QuestionBreakdownCard extends StatelessWidget {
  final String id;
  final String topic;
  final String question;
  final bool isError;
  final String studentAnswer;
  final String expectedAnswer;
  final String notion;
  final String pointsText;
  final bool aiExplanationExpanded;
  final VoidCallback onToggleAiExplanation;
  final String aiExplanation;

  const _QuestionBreakdownCard({
    required this.id,
    required this.topic,
    required this.question,
    required this.isError,
    required this.studentAnswer,
    required this.expectedAnswer,
    required this.notion,
    required this.pointsText,
    required this.aiExplanationExpanded,
    required this.onToggleAiExplanation,
    required this.aiExplanation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? colorScheme.error.withValues(alpha: 0.25)
              : colorScheme.tertiary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$id • $topic',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isError
                      ? colorScheme.errorContainer
                      : colorScheme.tertiaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  pointsText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isError
                        ? colorScheme.onErrorContainer
                        : colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isError) ...[
            // Incorrect student answer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cancel_rounded,
                    size: 16,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      studentAnswer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  Text(
                    'Ta réponse',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Correct answer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    expectedAnswer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.tertiary,
                    ),
                  ),
                ),
                Text(
                  isError ? 'Réponse attendue' : 'Bonne réponse (+2 pts)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Notion pill
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  notion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          if (isError) ...[
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: onToggleAiExplanation,
              icon: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.amber,
              ),
              label: Text(
                aiExplanationExpanded
                    ? 'Masquer l\'explication IA'
                    : 'Expliquer mon erreur avec l\'IA',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (aiExplanationExpanded) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Explication Pédagogique IA',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      aiExplanation,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}


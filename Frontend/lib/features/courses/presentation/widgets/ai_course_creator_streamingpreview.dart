part of '../pages/ai_course_creator_page.dart';
class _StreamingPreview extends StatelessWidget {
  final String text;
  const _StreamingPreview({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          // Auto-scroll vers le bas pour voir les nouveaux tokens
          reverse: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SelectableText(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }
}


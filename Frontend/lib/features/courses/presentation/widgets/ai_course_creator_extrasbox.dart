part of '../pages/ai_course_creator_page.dart';
class _ExtrasBox extends StatelessWidget {
  final bool examples;
  final bool mermaid;
  final void Function(bool examples, bool mermaid) onChanged;

  const _ExtrasBox({
    required this.examples,
    required this.mermaid,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget row(
      String titleKey,
      String descKey,
      bool value,
      ValueChanged<bool> set,
    ) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(value: value, onChanged: (v) => set(v ?? false)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(titleKey), style: theme.textTheme.bodyMedium),
                Text(
                  context.tr(descKey),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          row(
            'ai_extra_examples',
            'ai_extra_examples_desc',
            examples,
            (v) => onChanged(v, mermaid),
          ),
          const SizedBox(height: 12),
          row(
            'ai_extra_mermaid',
            'ai_extra_mermaid_desc',
            mermaid,
            (v) => onChanged(examples, v),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, size: 18, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('ai_extras_auto'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


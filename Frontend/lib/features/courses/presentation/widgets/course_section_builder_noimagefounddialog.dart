part of '../pages/course_section_builder_page.dart';
class _NoImageFoundDialog extends StatefulWidget {
  const _NoImageFoundDialog();

  @override
  State<_NoImageFoundDialog> createState() => _NoImageFoundDialogState();
}

class _NoImageFoundDialogState extends State<_NoImageFoundDialog> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      scrollable: true,
      title: Row(
        children: [
          Icon(Icons.image_not_supported_outlined, color: colorScheme.error),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              context.tr('ai_image_no_result_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('ai_image_search_empty'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: context.tr('ai_image_refine_hint'),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                final trimmed = value.trim();
                Navigator.of(context).pop(
                  trimmed.isEmpty
                      ? const _ImageRetry.regenerate()
                      : _ImageRetry.refine(trimmed),
                );
              },
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(const _ImageRetry.regenerate()),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(context.tr('ai_image_retry_regenerate')),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _queryController,
          builder: (context, value, _) {
            final trimmed = value.text.trim();
            return FilledButton.icon(
              onPressed: trimmed.isEmpty
                  ? null
                  : () =>
                        Navigator.of(context).pop(_ImageRetry.refine(trimmed)),
              icon: const Icon(Icons.travel_explore_rounded, size: 18),
              label: Text(context.tr('ai_image_retry_refine')),
            );
          },
        ),
      ],
    );
  }
}

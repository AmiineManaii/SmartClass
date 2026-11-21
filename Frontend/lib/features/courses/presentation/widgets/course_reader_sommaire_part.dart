part of '../pages/course_reader_body.dart';

/// Sommaire extrait des titres Markdown du cours.
class _SommaireChip extends StatelessWidget {
  final String content;

  const _SommaireChip({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headings = _extractHeadings(content);

    if (headings.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ActionChip(
        avatar: const Icon(Icons.list_alt_rounded, size: 14),
        label: Text(
          '${context.tr('course_sommaire')} (${headings.length})',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        backgroundColor: theme.colorScheme.primaryContainer.withValues(
          alpha: 0.3,
        ),
        side: BorderSide.none,
        onPressed: () => _showSommaire(context, headings),
      ),
    );
  }

  List<_HeadingItem> _extractHeadings(String content) {
    final lines = content.split('\n');
    final result = <_HeadingItem>[];
    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.startsWith('# ')) {
        result.add(
          _HeadingItem(
            title: trimmed.substring(2).trim(),
            level: 1,
            lineIndex: i,
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        result.add(
          _HeadingItem(
            title: trimmed.substring(3).trim(),
            level: 2,
            lineIndex: i,
          ),
        );
      } else if (trimmed.startsWith('### ')) {
        result.add(
          _HeadingItem(
            title: trimmed.substring(4).trim(),
            level: 3,
            lineIndex: i,
          ),
        );
      }
    }
    return result;
  }

  void _showSommaire(BuildContext context, List<_HeadingItem> headings) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.list_alt_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${context.tr('course_sommaire')} (${headings.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: headings.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final h = headings[index];
                      final indent = (h.level - 1) * 16.0;
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(indent + 8, 10, 8, 10),
                          child: Row(
                            children: [
                              Icon(
                                _buildHeadingIcon(h, theme),
                                size: h.level == 3 ? 6 : 16,
                                color: h.level == 1
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  h.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: h.level == 1
                                        ? FontWeight.bold
                                        : h.level == 2
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
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
            ),
          ),
        );
      },
    );
  }
}

IconData _buildHeadingIcon(_HeadingItem h, ThemeData theme) {
  return switch (h.level) {
    1 => Icons.folder_rounded,
    2 => Icons.subdirectory_arrow_right_rounded,
    _ => Icons.circle,
  };
}

class _HeadingItem {
  final String title;
  final int level;
  final int lineIndex;

  const _HeadingItem({
    required this.title,
    required this.level,
    required this.lineIndex,
  });
}

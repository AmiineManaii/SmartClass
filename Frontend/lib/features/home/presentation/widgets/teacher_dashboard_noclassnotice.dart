part of '../widgets/teacher_dashboard_view.dart';
class _NoClassNotice extends StatelessWidget {
  final VoidCallback? onCreateVirtual;

  const _NoClassNotice({this.onCreateVirtual});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.secondaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.co_present_outlined,
              color: colorScheme.onSecondaryFixed,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('teacher_no_class'),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('teacher_no_class_desc'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (onCreateVirtual != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreateVirtual,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Créer une classe virtuelle'),
            ),
          ],
        ],
      ),
    );
  }
}


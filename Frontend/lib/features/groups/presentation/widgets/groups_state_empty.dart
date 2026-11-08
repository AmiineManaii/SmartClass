part of '../pages/groups_page.dart';
extension on _GroupsPageState {
  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    bool isTeacherOrAdmin,
  ) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF122675).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 48,
                color: Color(0xFF122675),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('no_groups'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isTeacherOrAdmin
                  ? 'Créez votre première classe virtuelle ou partagez un code d\'invitation pour rassembler vos étudiants.'
                  : 'Rejoignez votre classe grâce au code fourni par votre enseignant pour accéder aux ressources de cours.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                if (isTeacherOrAdmin)
                  AppButton(
                    text: context.tr('create_group'),
                    onPressed: () => _showCreateGroupDialog(context, ref),
                    isFullWidth: false,
                  ),
                AppButton(
                  text: context.tr('join_group'),
                  onPressed: () => _showJoinGroupDialog(context, ref),
                  variant: isTeacherOrAdmin
                      ? AppButtonVariant.outlined
                      : AppButtonVariant.primary,
                  isFullWidth: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

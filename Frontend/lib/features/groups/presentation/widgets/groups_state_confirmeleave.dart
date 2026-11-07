part of '../pages/groups_page.dart';
extension on _GroupsPageState {
  void _confirmLeaveGroup(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    String groupName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Quitter la classe'),
        content: Text(
          'Voulez-vous vraiment quitter la classe "$groupName" ? Vous perdrez l\'acc├¿s aux ressources associ├®es.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(groupsRemoteDataSourceProvider)
                    .leaveClass(groupId);
                ref.invalidate(myGroupsProvider);
                ref.invalidate(studentClassMembershipProvider);
                if (context.mounted) {
                  context.showInfoToast('Vous avez quitt├® la classe.');
                }
              } catch (e) {
                if (context.mounted) {
                  context.showErrorToast(
                    e.toString().replaceFirst('ApiException: ', ''),
                  );
                }
              }
            },
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}

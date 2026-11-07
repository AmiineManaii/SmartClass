part of '../pages/groups_page.dart';
extension on _GroupsPageState {
  void _showJoinGroupDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(context.tr('join_group')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Entrez le code d\'invitation fourni par votre enseignant :',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Code d\'invitation',
                  hintText: 'ex: SC-AB12CD',
                  prefixIcon: const Icon(Icons.vpn_key_rounded),
                  errorText: errorMessage,
                ),
                textCapitalization: TextCapitalization.characters,
                autofocus: true,
                enabled: !isLoading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final code = controller.text.trim();
                      if (code.isEmpty) {
                        updateState(() => errorMessage = 'Veuillez saisir un code');
                        return;
                      }
                      updateState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      try {
                        await ref
                            .read(groupsRemoteDataSourceProvider)
                            .joinClass(code);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        ref.invalidate(myGroupsProvider);
                        ref.invalidate(studentClassMembershipProvider);
                        if (context.mounted) {
                          context.showSuccessToast(context.tr('join_group_success'));
                        }
                      } catch (e) {
                        updateState(() {
                          isLoading = false;
                          errorMessage =
                              e.toString().replaceFirst('ApiException: ', '');
                        });
                      }
                    },
              child: isLoading
                  ? const SmartLoader.small(
                      color: Colors.white,
                      customSize: 18,
                    )
                  : Text(context.tr('join_group')),
            ),
          ],
        ),
      ),
    );
  }

}

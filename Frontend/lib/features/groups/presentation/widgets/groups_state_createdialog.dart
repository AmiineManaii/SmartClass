part of '../pages/groups_page.dart';
extension on _GroupsPageState {
  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateGroupSheet(ref: ref),
    );
  }

}

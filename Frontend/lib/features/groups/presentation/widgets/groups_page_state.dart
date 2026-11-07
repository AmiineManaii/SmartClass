part of '../pages/groups_page.dart';

class _GroupsPageState extends ConsumerState<GroupsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'ALL'; // 'ALL', 'TEACHER', 'STUDENT'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text.trim().toLowerCase();
      if (text != _searchQuery) {
        updateState(() => _searchQuery = text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void updateState(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) => _buildPage(context);
}

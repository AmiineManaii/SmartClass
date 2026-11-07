part of '../pages/videoconference_page.dart';

class _VideoconferencePageState extends ConsumerState<VideoconferencePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) updateState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }


  void updateState(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) => _buildPage(context);
}

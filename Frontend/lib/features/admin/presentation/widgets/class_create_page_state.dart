part of '../pages/class_create_page.dart';

class _ClassCreatePageState extends ConsumerState<ClassCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customDepartmentController = TextEditingController();
  String _level = 'L3';
  String? _department;
  String? _referentId;
  String? _referentName;
  int _capacity = 35;
  bool _forumEnabled = true;
  bool _entSyncEnabled = true;
  bool _saving = false;
  bool _prefilled = false;

  bool get _isEdit => widget.editClassId != null;

  static const _maxDescription = 300;

  static const _licenceLevels = ['L1', 'L2', 'L3'];
  static const _masterLevels = ['Master 1', 'Master 2'];
  static const _doctoratLevels = ['Doctorat'];
  static const _capacityPresets = [20, 25, 30, 35, 40, 50, 60];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _customDepartmentController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customDepartmentController.dispose();
    super.dispose();
  }

  static ClassLevel _apiLevel(String label) {
    if (label == 'Doctorat') return ClassLevel.doctorat;
    if (label.startsWith('Master')) return ClassLevel.master;
    return ClassLevel.licence;
  }

  static String _labelFor(ClassLevel level) {
    switch (level) {
      case ClassLevel.master:
        return 'Master 1';
      case ClassLevel.doctorat:
        return 'Doctorat';
      case ClassLevel.licence:
        return 'L3';
    }
  }

  Color _colorForLevel(String level) {
    if (level.startsWith('Doctorat')) return const Color(0xFFD97706);
    if (level.startsWith('Master')) return const Color(0xFF7C3AED);
    return const Color(0xFF2563EB);
  }


  void updateState(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) => _buildPage(context);
}

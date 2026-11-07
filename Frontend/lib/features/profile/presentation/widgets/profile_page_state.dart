part of '../pages/profile_page.dart';

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers for Tab 0: Personal Profile
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _universityController;
  late final TextEditingController _majorController;
  late final TextEditingController _bioController;

  // Selected sub-section in left menu
  int _selectedMenuIndex = 0;

  // Security & Authentication states (Tab 1)
  bool _twoFactorEnabled = false;
  // ignore: unused_field
  List<Map<String, dynamic>> _auditLogs = [];
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Passkeys list
  List<Map<String, String>> _passkeys = [];

  // Notification toggles (Tab 2)
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsEmergencyAlerts = false;
  bool _aiSmartMentorRecommendations = true;
  bool _deadlinesReminders = true;
  bool _quietHoursEnabled = true;

  // Privacy & GDPR toggles (Tab 4)
  bool _profileVisibleToCohort = true;
  bool _rankingVisible = true;
  bool _shareAiSummaries = false;

  // Active Sessions list (Tab 5)
  bool _isLoadingSessions = false;
  List<Map<String, dynamic>> _remoteSessions = [];

  // Accessibility toggles (Tab 3)
  bool _highContrast = false;
  bool _reduceAnimations = false;

  bool _isSaving = false;
  bool _justSaved = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authStateProvider).valueOrNull;
    _twoFactorEnabled = authState?.twoFactorEnabled ?? false;

    final role = authState?.role?.toLowerCase() ?? 'student';
    final isTeacher = role == 'teacher';
    final isAdmin = role == 'admin';

    final defaultId = isAdmin
        ? 'ADM-2026-001'
        : (isTeacher ? 'PPR-2026-89421' : 'CNE-2026-984210');
    final initialId =
        (authState?.studentId != null && authState!.studentId!.isNotEmpty)
        ? (isTeacher && authState.studentId!.startsWith('CNE-')
              ? defaultId
              : (isAdmin && authState.studentId!.startsWith('CNE-')
                    ? defaultId
                    : authState.studentId!))
        : defaultId;

    final defaultMajor = isAdmin
        ? 'Direction & Administration ENT'
        : (isTeacher
              ? 'Département Informatique & Technologies Numériques'
              : 'Cycle Ingénieur • Génie Informatique');
    final initialMajor =
        (authState?.major != null && authState!.major!.isNotEmpty)
        ? (isTeacher &&
                  (authState.major!.startsWith('Cycle') ||
                      authState.major!.startsWith('Master'))
              ? defaultMajor
              : (isAdmin &&
                        (authState.major!.startsWith('Cycle') ||
                            authState.major!.startsWith('Master'))
                    ? defaultMajor
                    : authState.major!))
        : defaultMajor;

    final defaultBio = isAdmin
        ? 'Administrateur Système • Supervision globale et administration de la plateforme académique SmartClass.'
        : (isTeacher
              ? 'Enseignant en Informatique & Systèmes Numériques • Spécialisé en Génie Logiciel, IA et Systèmes Distribués.'
              : 'Étudiant en Cycle d\'Ingénieur • Passionné par l\'intelligence artificielle et le génie logiciel.');
    final initialBio = (authState?.bio != null && authState!.bio!.isNotEmpty)
        ? (isTeacher && authState.bio!.contains('Étudiant')
              ? defaultBio
              : (isAdmin && authState.bio!.contains('Étudiant')
                    ? defaultBio
                    : authState.bio!))
        : defaultBio;

    final defaultUniversity = isAdmin
        ? 'Administration Centrale ENT'
        : (isTeacher
              ? 'Institut Supérieur / Université'
              : 'Université Mohammed V de Rabat');
    final initialUniversity =
        (authState?.institution != null && authState!.institution!.isNotEmpty)
        ? authState.institution!
        : defaultUniversity;

    _fullNameController = TextEditingController(
      text:
          (authState?.displayName != null && authState!.displayName!.isNotEmpty)
          ? authState.displayName!
          : (isAdmin
                ? 'Administrateur SmartClass'
                : (isTeacher ? 'Professeur' : 'Ahmed Mohsen')),
    );
    _emailController = TextEditingController(
      text: (authState?.email != null && authState!.email!.isNotEmpty)
          ? authState.email!
          : 'faroukmessay006@gmail.com',
    );
    _studentIdController = TextEditingController(text: initialId);
    _universityController = TextEditingController(text: initialUniversity);
    _majorController = TextEditingController(text: initialMajor);
    _bioController = TextEditingController(text: initialBio);

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadAcademicProfile();
    _loadAuditLogs();
    _loadSessions();
    _loadPreferences();
  }

  Future<void> _loadAcademicProfile() async {
    try {
      final tokens = ref.read(tokenStorageProvider);
      final authState = ref.read(authStateProvider).valueOrNull;
      final role = authState?.role?.toLowerCase() ?? 'student';
      final isTeacher = role == 'teacher';
      final isAdmin = role == 'admin';
      final userKey = authState?.userId ?? authState?.email;
      final profile = await tokens.readAcademicProfile(userKey);

      var inst = profile['institution'] ?? authState?.institution ?? '';
      var fac = profile['faculty'] ?? authState?.faculty ?? '';
      var maj = profile['major'] ?? authState?.major ?? '';
      var sId = profile['studentId'] ?? authState?.studentId ?? '';
      var bio = profile['bio'] ?? authState?.bio ?? '';

      // Default university & academic values according to role
      if (isAdmin) {
        if (inst.isEmpty) {
          inst = 'Administration Centrale ENT';
        }
        if (maj.isEmpty ||
            maj.startsWith('Cycle') ||
            maj.startsWith('Master')) {
          maj = 'Direction & Administration ENT';
        }
        if (sId.isEmpty || sId.startsWith('CNE-')) {
          sId = 'ADM-2026-001';
        }
        if (bio.isEmpty || bio.contains('Étudiant')) {
          bio =
              'Administrateur Système • Supervision globale et administration de la plateforme académique SmartClass.';
        }
      } else if (isTeacher) {
        if (inst.isEmpty) {
          inst = 'Institut Supérieur / Université';
        }
        if (maj.isEmpty ||
            maj.startsWith('Cycle Ingénieur') ||
            maj.startsWith('Master')) {
          maj = 'Département Informatique & Technologies Numériques';
        }
        if (sId.isEmpty || sId.startsWith('CNE-')) {
          sId = 'PPR-2026-89421';
        }
        if (bio.isEmpty || bio.contains('Étudiant')) {
          bio =
              'Enseignant en Informatique & Systèmes Numériques • Spécialisé en Génie Logiciel, IA et Systèmes Distribués.';
        }
      } else {
        if (inst.isEmpty) {
          inst = 'Université Mohammed V de Rabat';
        }
        if (maj.isEmpty) {
          maj = 'Cycle Ingénieur • Génie Informatique';
        }
        if (sId.isEmpty) {
          sId = 'CNE-2026-984210';
        }
        if (bio.isEmpty) {
          bio =
              'Étudiant en Cycle d\'Ingénieur • Passionné par l\'intelligence artificielle et le génie logiciel.';
        }
      }

      if (mounted) {
        setState(() {
          if (_universityController.text.trim().isEmpty) {
            _universityController.text = inst;
          }
          if (_majorController.text.trim().isEmpty ||
              ((isTeacher || isAdmin) &&
                  (_majorController.text.startsWith('Cycle') ||
                      _majorController.text.startsWith('Master')))) {
            _majorController.text = maj;
          }
          if (_studentIdController.text.trim().isEmpty ||
              (isTeacher && _studentIdController.text.startsWith('CNE-')) ||
              (isAdmin && _studentIdController.text.startsWith('CNE-'))) {
            _studentIdController.text = sId;
          }
          if (_bioController.text.trim().isEmpty ||
              ((isTeacher || isAdmin) &&
                  _bioController.text.contains('Étudiant'))) {
            _bioController.text = bio;
          }
        });
      }

      final activeInst = _universityController.text.trim().isNotEmpty
          ? _universityController.text.trim()
          : inst;

      await ref
          .read(authStateProvider.notifier)
          .updateAcademicProfile(
            institution: activeInst,
            faculty: fac,
            major: _majorController.text.trim().isNotEmpty
                ? _majorController.text.trim()
                : maj,
            studentId: _studentIdController.text.trim().isNotEmpty
                ? _studentIdController.text.trim()
                : sId,
            bio: _bioController.text.trim().isNotEmpty
                ? _bioController.text.trim()
                : bio,
          );
    } catch (_) {}
  }

  Future<void> _loadAuditLogs() async {
    try {
      final logs = await ref.read(authStateProvider.notifier).getAuditLogs();
      if (mounted && logs.isNotEmpty) {
        setState(() => _auditLogs = logs);
      }
    } catch (_) {}
  }

  Future<void> _loadSessions() async {
    if (!mounted) return;
    setState(() => _isLoadingSessions = true);
    try {
      final sessions = await ref.read(authStateProvider.notifier).getSessions();
      if (mounted) {
        setState(() {
          _remoteSessions = sessions
              .where((s) => s['isCurrent'] != true)
              .toList();
        });
      }
    } catch (_) {
      // Offline fallback
    } finally {
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _pushNotifications = prefs.getBool('pref_push_notif') ?? true;
          _emailNotifications = prefs.getBool('pref_email_notif') ?? true;
          _smsEmergencyAlerts = prefs.getBool('pref_sms_alerts') ?? false;
          _aiSmartMentorRecommendations =
              prefs.getBool('pref_ai_mentor') ?? true;
          _deadlinesReminders = prefs.getBool('pref_deadlines') ?? true;
          _quietHoursEnabled = prefs.getBool('pref_quiet_hours') ?? true;
          _profileVisibleToCohort =
              prefs.getBool('pref_profile_visible') ?? true;
          _rankingVisible = prefs.getBool('pref_ranking_visible') ?? true;
          _shareAiSummaries = prefs.getBool('pref_share_ai') ?? false;
        });
      }
      final rawPk = prefs.getString('smartclass_passkeys');
      if (rawPk != null && mounted) {
        final list = jsonDecode(rawPk) as List;
        setState(() {
          _passkeys = list
              .map((e) => Map<String, String>.from(e as Map))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_push_notif', _pushNotifications);
      await prefs.setBool('pref_email_notif', _emailNotifications);
      await prefs.setBool('pref_sms_alerts', _smsEmergencyAlerts);
      await prefs.setBool('pref_ai_mentor', _aiSmartMentorRecommendations);
      await prefs.setBool('pref_deadlines', _deadlinesReminders);
      await prefs.setBool('pref_quiet_hours', _quietHoursEnabled);
      await prefs.setBool('pref_profile_visible', _profileVisibleToCohort);
      await prefs.setBool('pref_ranking_visible', _rankingVisible);
      await prefs.setBool('pref_share_ai', _shareAiSummaries);
    } catch (_) {}
  }

  Future<void> _addPasskey(String name) async {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final newPk = {
      'id': 'pk-${now.millisecondsSinceEpoch}',
      'name': name.trim().isNotEmpty ? name.trim() : 'Appareil certifié',
      'date': dateStr,
      'icon': 'key',
    };
    setState(() => _passkeys.add(newPk));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smartclass_passkeys', jsonEncode(_passkeys));
    } catch (_) {}
    _showSuccessSnackBar('Clé / Passkey enregistrée avec succès.');
  }

  Future<void> _removePasskey(String id) async {
    setState(() => _passkeys.removeWhere((p) => p['id'] == id));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smartclass_passkeys', jsonEncode(_passkeys));
    } catch (_) {}
    _showSuccessSnackBar('Passkey supprimée.');
  }

  Future<void> _revokeSession(String id) async {
    try {
      await ref.read(authStateProvider.notifier).revokeSession(id);
      if (mounted) {
        setState(() => _remoteSessions.removeWhere((s) => s['id'] == id));
        _showSuccessSnackBar('Session révoquée avec succès.');
        _loadAuditLogs();
      }
    } catch (_) {
      _showErrorSnackBar('Erreur lors de la révocation de la session.');
    }
  }

  Future<void> _revokeAllSessions() async {
    try {
      await ref.read(authStateProvider.notifier).revokeAllOtherSessions();
      if (mounted) {
        setState(() => _remoteSessions.clear());
        _showSuccessSnackBar(context.tr('all_sessions_revoked'));
        _loadAuditLogs();
      }
    } catch (_) {
      _showErrorSnackBar('Erreur lors de la révocation des sessions.');
    }
  }

  bool _isExporting = false;

  Future<void> _exportDataBackend({required String format}) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    final isPdf = format.toLowerCase() == 'pdf';
    _showSuccessSnackBar(
      isPdf
          ? 'Génération de l\'attestation PDF officielle en cours par le serveur...'
          : 'Génération de l\'archive JSON RGPD en cours...',
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final authState = ref.read(authStateProvider).valueOrNull;
      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final safeName = (authState?.displayName ?? 'compte').replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );

      if (isPdf) {
        final bytes = await apiClient.getBytes(
          '${ApiConfig.apiPrefix}/users/me/export',
          queryParameters: {'format': 'pdf'},
        );
        final filename = 'smartclass_export_${safeName}_$dateStr.pdf';
        downloadBytesFile(filename, bytes, 'application/pdf');
        _showSuccessSnackBar(
          'Document PDF officiel généré et téléchargé ($filename).',
        );
      } else {
        final res = await apiClient.get<dynamic>(
          '${ApiConfig.apiPrefix}/users/me/export',
          queryParameters: {'format': 'json'},
        );
        final dynamic rawData = res.data;
        final jsonStr = rawData is String
            ? rawData
            : const JsonEncoder.withIndent('  ').convert(rawData);
        final filename = 'smartclass_export_${safeName}_$dateStr.json';
        downloadJsonFile(filename, jsonStr);
        Clipboard.setData(ClipboardData(text: jsonStr));
        _showSuccessSnackBar(
          'Archive JSON téléchargée ($filename) et copiée dans le presse-papiers.',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'export des données : $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _bioController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void updateState(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) => buildProfile(context);
}

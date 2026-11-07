// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
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
        updateState(() {
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
        updateState(() => _auditLogs = logs);
      }
    } catch (_) {}
  }

  Future<void> _loadSessions() async {
    if (!mounted) return;
    updateState(() => _isLoadingSessions = true);
    try {
      final sessions = await ref.read(authStateProvider.notifier).getSessions();
      if (mounted) {
        updateState(() {
          _remoteSessions = sessions
              .where((s) => s['isCurrent'] != true)
              .toList();
        });
      }
    } catch (_) {
      // Offline fallback
    } finally {
      if (mounted) updateState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        updateState(() {
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
        updateState(() {
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
    updateState(() => _passkeys.add(newPk));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smartclass_passkeys', jsonEncode(_passkeys));
    } catch (_) {}
    _showSuccessSnackBar('Clé / Passkey enregistrée avec succès.');
  }

  Future<void> _removePasskey(String id) async {
    updateState(() => _passkeys.removeWhere((p) => p['id'] == id));
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
        updateState(() => _remoteSessions.removeWhere((s) => s['id'] == id));
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
        updateState(() => _remoteSessions.clear());
        _showSuccessSnackBar(context.tr('all_sessions_revoked'));
        _loadAuditLogs();
      }
    } catch (_) {
      _showErrorSnackBar('Erreur lors de la révocation des sessions.');
    }
  }

}




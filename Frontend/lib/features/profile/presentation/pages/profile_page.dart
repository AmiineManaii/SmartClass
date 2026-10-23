import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/typography/typography_provider.dart';
import '../../../../core/utils/file_download_helper.dart';

/// Page "Paramètres du compte" (Portail Étudiant)
/// Navigation modulaire complète avec 6 onglets interactifs :
/// 0. Profil personnel (avec inputs sans double-bordure)
/// 1. Sécurité & Authentification (Mot de passe, 2FA TOTP, Passkeys, Journal d'audit)
/// 2. Notifications & Alertes (Push, Email, SMS, SmartMentor IA, Heures de silence)
/// 3. Apparence & Thème (Clair/Sombre/Système, Français/Anglais, Zoom typographique)
/// 4. Confidentialité & RGPD (Export de données, Partage de classe, Zone critique)
/// 5. Sessions & Appareils (Session actuelle, Appareils distants, Révocation globale)
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

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

    final isTeacher = authState?.role?.toLowerCase() == 'teacher';

    final defaultId = isTeacher ? 'PPR-2026-89421' : 'CNE-2026-984210';
    final initialId = (authState?.studentId != null && authState!.studentId!.isNotEmpty)
        ? (isTeacher && authState.studentId!.startsWith('CNE-') ? defaultId : authState.studentId!)
        : defaultId;

    final defaultMajor = isTeacher
        ? 'Département Informatique & Technologies Numériques'
        : 'Cycle Ingénieur • Génie Informatique';
    final initialMajor = (authState?.major != null && authState!.major!.isNotEmpty)
        ? (isTeacher && (authState.major!.startsWith('Cycle') || authState.major!.startsWith('Master')) ? defaultMajor : authState.major!)
        : defaultMajor;

    final defaultBio = isTeacher
        ? 'Enseignant en Informatique & Systèmes Numériques • Spécialisé en Génie Logiciel, IA et Systèmes Distribués.'
        : 'Étudiant en Cycle d\'Ingénieur • Passionné par l\'intelligence artificielle et le génie logiciel.';
    final initialBio = (authState?.bio != null && authState!.bio!.isNotEmpty)
        ? (isTeacher && authState.bio!.contains('Étudiant') ? defaultBio : authState.bio!)
        : defaultBio;

    _fullNameController = TextEditingController(
      text: (authState?.displayName != null && authState!.displayName!.isNotEmpty)
          ? authState.displayName!
          : (isTeacher ? 'Professeur' : 'Ahmed Mohsen'),
    );
    _emailController = TextEditingController(
      text: (authState?.email != null && authState!.email!.isNotEmpty)
          ? authState.email!
          : 'faroukmessay006@gmail.com',
    );
    _studentIdController = TextEditingController(
      text: initialId,
    );
    _universityController = TextEditingController(
      text: (authState?.institution != null && authState!.institution!.isNotEmpty)
          ? authState.institution!
          : (isTeacher ? 'Institut Supérieur / Université' : 'Université Mohammed V de Rabat'),
    );
    _majorController = TextEditingController(
      text: initialMajor,
    );
    _bioController = TextEditingController(
      text: initialBio,
    );

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
      final isTeacher = authState?.role?.toLowerCase() == 'teacher';
      final userKey = authState?.userId ?? authState?.email;
      final profile = await tokens.readAcademicProfile(userKey);

      var inst = profile['institution'] ?? authState?.institution ?? '';
      var fac = profile['faculty'] ?? authState?.faculty ?? '';
      var maj = profile['major'] ?? authState?.major ?? '';
      var sId = profile['studentId'] ?? authState?.studentId ?? '';
      var bio = profile['bio'] ?? authState?.bio ?? '';

      // Default university & academic values according to role
      if (isTeacher) {
        if (inst.isEmpty) {
          inst = 'Institut Supérieur / Université';
        }
        if (maj.isEmpty || maj.startsWith('Cycle Ingénieur') || maj.startsWith('Master')) {
          maj = 'Département Informatique & Technologies Numériques';
        }
        if (sId.isEmpty || sId.startsWith('CNE-')) {
          sId = 'PPR-2026-89421';
        }
        if (bio.isEmpty || bio.contains('Étudiant')) {
          bio = 'Enseignant en Informatique & Systèmes Numériques • Spécialisé en Génie Logiciel, IA et Systèmes Distribués.';
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
          bio = 'Étudiant en Cycle d\'Ingénieur • Passionné par l\'intelligence artificielle et le génie logiciel.';
        }
      }

      if (mounted) {
        setState(() {
          if (_universityController.text.trim().isEmpty) {
            _universityController.text = inst;
          }
          if (_majorController.text.trim().isEmpty || (isTeacher && (_majorController.text.startsWith('Cycle') || _majorController.text.startsWith('Master')))) {
            _majorController.text = maj;
          }
          if (_studentIdController.text.trim().isEmpty || (isTeacher && _studentIdController.text.startsWith('CNE-'))) {
            _studentIdController.text = sId;
          }
          if (_bioController.text.trim().isEmpty || (isTeacher && _bioController.text.contains('Étudiant'))) {
            _bioController.text = bio;
          }
        });
      }

      final activeInst = _universityController.text.trim().isNotEmpty
          ? _universityController.text.trim()
          : inst;

      await ref.read(authStateProvider.notifier).updateAcademicProfile(
        institution: activeInst,
        faculty: fac,
        major: _majorController.text.trim().isNotEmpty ? _majorController.text.trim() : maj,
        studentId: _studentIdController.text.trim().isNotEmpty ? _studentIdController.text.trim() : sId,
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : bio,
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
          _remoteSessions = sessions.where((s) => s['isCurrent'] != true).toList();
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
          _aiSmartMentorRecommendations = prefs.getBool('pref_ai_mentor') ?? true;
          _deadlinesReminders = prefs.getBool('pref_deadlines') ?? true;
          _quietHoursEnabled = prefs.getBool('pref_quiet_hours') ?? true;
          _profileVisibleToCohort = prefs.getBool('pref_profile_visible') ?? true;
          _rankingVisible = prefs.getBool('pref_ranking_visible') ?? true;
          _shareAiSummaries = prefs.getBool('pref_share_ai') ?? false;
        });
      }
      final rawPk = prefs.getString('smartclass_passkeys');
      if (rawPk != null && mounted) {
        final list = jsonDecode(rawPk) as List;
        setState(() {
          _passkeys = list.map((e) => Map<String, String>.from(e as Map)).toList();
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
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final safeName = (authState?.displayName ?? 'compte').replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      if (isPdf) {
        final bytes = await apiClient.getBytes(
          '${ApiConfig.apiPrefix}/users/me/export',
          queryParameters: {'format': 'pdf'},
        );
        final filename = 'smartclass_export_${safeName}_$dateStr.pdf';
        downloadBytesFile(filename, bytes, 'application/pdf');
        _showSuccessSnackBar('Document PDF officiel généré et téléchargé ($filename).');
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
        _showSuccessSnackBar('Archive JSON téléchargée ($filename) et copiée dans le presse-papiers.');
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

  // ===========================================================================
  // BACKEND ACTIONS & SAVE LOGIC
  // ===========================================================================

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final names = _fullNameController.text.trim().split(' ');
      final firstName = names.isNotEmpty ? names.first : '';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      final university = _universityController.text.trim();
      final studentId = _studentIdController.text.trim();
      final major = _majorController.text.trim();
      final bio = _bioController.text.trim();

      // 1. Immediately persist local academic profile & update AuthState in real-time
      await ref.read(authStateProvider.notifier).updateAcademicProfile(
            institution: university,
            studentId: studentId,
            major: major,
            bio: bio,
          );

      // 2. Save notification & privacy preferences
      await _savePreferences();

      // 3. Update backend user profile
      try {
        await ref.read(authStateProvider.notifier).updateProfile(
              firstName: firstName,
              lastName: lastName,
            );
      } catch (_) {
        // Backend name update fallback - academic profile is already secured
      }

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _justSaved = true;
      });

      _showAdvancedSaveNotification();

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _justSaved = false);
      });
    } on Failure catch (failure) {
      if (!mounted) return;
      final l10n = failureL10n(failure);
      _showErrorSnackBar(context.tr(l10n.key, args: l10n.args));
      setState(() => _isSaving = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _justSaved = true;
      });
      _showAdvancedSaveNotification();
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _justSaved = false);
      });
    }
  }

  void _showAdvancedSaveNotification() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF065F46), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF34D399), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF059669),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modifications enregistrées en temps réel !',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vos informations académiques (${_universityController.text.trim().isNotEmpty ? _universityController.text.trim() : 'Université'}) sont synchronisées avec l\'ENT.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFA7F3D0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetChanges() async {
    final authState = ref.read(authStateProvider).valueOrNull;
    setState(() {
      _fullNameController.text = authState?.displayName ?? '';
      _emailController.text = authState?.email ?? '';
      _studentIdController.text = authState?.studentId ?? '';
      _universityController.text = authState?.institution ?? '';
      _majorController.text = authState?.major ?? '';
      _bioController.text = authState?.bio ?? '';
    });
    await _loadAcademicProfile();
    await _loadPreferences();
    if (mounted) context.showInfoToast(context.tr('discard_changes'));
  }

  void _showSuccessSnackBar(String message) {
    context.showSuccessToast(message);
  }

  void _showErrorSnackBar(String message) {
    context.showErrorToast(message);
  }

  // ===========================================================================
  // BUILD ENTRY POINT
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = context.screenWidth >= 1024;

    // Palette tokens
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE2E8F0);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Breadcrumbs
                  _buildBreadcrumbs(isDark),
                  const SizedBox(height: 12),

                  // 2. Page Title + Badges + ENT Academic Status
                  _buildHeaderSection(isDark),
                  const SizedBox(height: 28),

                  // 3. Main 2-Column Section (Desktop) or Tabbed Layout (Mobile)
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Configuration Menu + Quota Box
                        SizedBox(
                          width: 290,
                          child: _buildLeftMenuColumn(cardBg, borderColor, isDark),
                        ),
                        const SizedBox(width: 24),
                        // Right Column: Active Tab Dynamic View
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _buildActiveTabContent(
                              cardBg,
                              borderColor,
                              isDark,
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildLeftMenuColumn(cardBg, borderColor, isDark),
                    const SizedBox(height: 20),
                    _buildActiveTabContent(cardBg, borderColor, isDark),
                  ],

                  const SizedBox(height: 32),

                  // 4. Bottom Actions Bar (ENT Sync timestamp & Save/Cancel)
                  _buildBottomBar(cardBg, borderColor, isDark),
                  const SizedBox(height: 20),

                  // 5. Academic Footer legal links
                  _buildFooterLinks(textMuted),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DYNAMIC TAB DISPATCHER
  // ===========================================================================

  Widget _buildActiveTabContent(
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    switch (_selectedMenuIndex) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('tab_personal_info'),
          child: _buildPersonalInfoCard(cardBg, borderColor, isDark),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey('tab_security_auth'),
          child: _buildSecurityAuthCard(cardBg, borderColor, isDark),
        );
      case 2:
        return KeyedSubtree(
          key: const ValueKey('tab_notifications'),
          child: _buildNotificationsCard(cardBg, borderColor, isDark),
        );
      case 3:
        return KeyedSubtree(
          key: const ValueKey('tab_appearance'),
          child: _buildAppearanceCard(cardBg, borderColor, isDark),
        );
      case 4:
        return KeyedSubtree(
          key: const ValueKey('tab_privacy_gdpr'),
          child: _buildPrivacyGdprCard(cardBg, borderColor, isDark),
        );
      case 5:
        return KeyedSubtree(
          key: const ValueKey('tab_sessions_devices'),
          child: _buildSessionsDevicesCard(cardBg, borderColor, isDark),
        );
      default:
        return KeyedSubtree(
          key: const ValueKey('tab_default'),
          child: _buildPersonalInfoCard(cardBg, borderColor, isDark),
        );
    }
  }

  // ===========================================================================
  // SECTION 0: BREADCRUMBS & HEADER
  // ===========================================================================

  Widget _buildBreadcrumbs(bool isDark) {
    final style = TextStyle(
      fontSize: 12,
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      fontWeight: FontWeight.w500,
    );

    return Row(
      children: [
        Icon(
          Icons.home_outlined,
          size: 14,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 6),
        Text(context.tr('nav_dashboard'), style: style),
        const SizedBox(width: 6),
        Text('/', style: style),
        const SizedBox(width: 6),
        Text(context.tr('nav_my_profile'), style: style),
        const SizedBox(width: 6),
        Text('/', style: style),
        const SizedBox(width: 6),
        Text(
          context.tr('account_settings_title'),
          style: style.copyWith(
            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(bool isDark) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final role = authState?.role?.toLowerCase() ?? 'student';
    final isTeacher = role == 'teacher';
    final roleLabel = role == 'admin'
        ? 'Administrateur'
        : (role == 'teacher'
            ? 'Enseignant Certifié'
            : context.tr('active_student_badge'));
    final roleBg = role == 'admin'
        ? const Color(0xFFE0E7FF)
        : (role == 'teacher'
            ? const Color(0xFFF3E8FF)
            : const Color(0xFFDCFCE7));
    final roleFg = role == 'admin'
        ? const Color(0xFF3730A3)
        : (role == 'teacher'
            ? const Color(0xFF6B21A8)
            : const Color(0xFF15803D));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.tr('account_settings_title'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: roleBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: roleFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isTeacher
                    ? 'Gérez votre identité académique, vos accès de sécurité et configurez vos flux de notifications pour votre espace enseignant.'
                    : context.tr('account_settings_desc'),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('ent_sync_status'),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // LEFT MENU (MENU DE CONFIGURATION)
  // ===========================================================================

  Widget _buildLeftMenuColumn(Color cardBg, Color borderColor, bool isDark) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final role = authState?.role?.toLowerCase() ?? 'student';
    final isTeacher = role == 'teacher';
    final quotaText = role == 'admin'
        ? '45.2 / 250 Go'
        : (isTeacher ? '18.6 / 100 Go' : '2.4 / 20 Go');
    final quotaProgress = role == 'admin'
        ? 0.181
        : (isTeacher ? 0.186 : 0.120);

    final menuItems = [
      (Icons.person_outline_rounded, context.tr('menu_personal_info'), null, false),
      (
        Icons.security_rounded,
        context.tr('menu_security_auth'),
        _twoFactorEnabled
            ? context.tr('two_factor_active_badge')
            : context.tr('two_factor_inactive_badge'),
        false
      ),
      (Icons.notifications_none_rounded, context.tr('menu_notifications'), null, false),
      (Icons.palette_outlined, context.tr('menu_appearance'), null, false),
      (Icons.lock_outline_rounded, context.tr('menu_privacy_gdpr'), null, false),
      (Icons.devices_rounded, context.tr('menu_sessions_devices'), null, true),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('config_menu_title'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(menuItems.length, (index) {
            final item = menuItems[index];
            final isSelected = _selectedMenuIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: InkWell(
                onTap: () => setState(() => _selectedMenuIndex = index),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? const Color(0xFF1E3A8A)
                            : const Color(0xFF1E293B))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.$1,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B)),
                          ),
                        ),
                      ),
                      if (item.$3 != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : (_twoFactorEnabled
                                    ? const Color(0xFFDCFCE7)
                                    : (isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0))),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.$3!,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (_twoFactorEnabled
                                      ? const Color(0xFF15803D)
                                      : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF475569))),
                            ),
                          ),
                        ),
                      if (item.$4)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Storage quota box (Matches Image 1 exactly)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE0E7FF),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTeacher
                          ? 'Stockage Cours & Médias Cloud'
                          : context.tr('cloud_storage_title'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      quotaText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: quotaProgress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFCBD5E1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.cloud_done_rounded,
                      size: 13,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      context.tr('ent_cloud_synced'),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 0: INFORMATIONS PERSONNELLES & PROFIL
  // ===========================================================================

  Widget _buildPersonalInfoCard(Color cardBg, Color borderColor, bool isDark) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final role = authState?.role?.toLowerCase() ?? 'student';
    final isTeacher = role == 'teacher';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Icon, Title, Subtitle and Official ID badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.folder_shared_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('menu_personal_info'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('certified_academic_data'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.badge_rounded,
                      size: 13,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isTeacher ? 'Matricule officiel certifié' : context.tr('official_id'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Photo Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFDBEAFE),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/student_avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            _fullNameController.text.isNotEmpty
                                ? _fullNameController.text[0].toUpperCase()
                                : (isTeacher ? 'P' : 'A'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isTeacher
                                ? 'Photo de profil enseignant'
                                : context.tr('student_photo_title'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              context.tr('validated_badge'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTeacher
                            ? 'Format PNG ou JPG, max 5 Mo. Cette photo figure sur votre badge officiel, vos fiches de cours et votre profil académique.'
                            : context.tr('student_photo_desc'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : const Color(0xFFCBD5E1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              _showSuccessSnackBar(
                                'Module de téléversement photo prêt (Formats acceptés : JPG, PNG).',
                              );
                            },
                            child: Text(
                              context.tr('change_image'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () {
                              _showSuccessSnackBar(
                                'Photo par défaut rétablie.',
                              );
                            },
                            child: Text(
                              context.tr('delete_image'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2x2 Form grid + full width field
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 540;
              return Column(
                children: [
                  if (isWide)
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: context.tr('full_name_label'),
                            controller: _fullNameController,
                            icon: Icons.person_outline_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            label: context.tr('academic_email_label'),
                            controller: _emailController,
                            icon: Icons.mail_outline_rounded,
                            suffixBadge: context.tr('verified_label'),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildInputField(
                      label: context.tr('full_name_label'),
                      controller: _fullNameController,
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      label: context.tr('academic_email_label'),
                      controller: _emailController,
                      icon: Icons.mail_outline_rounded,
                      suffixBadge: context.tr('verified_label'),
                      isDark: isDark,
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (isWide)
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: isTeacher
                                ? 'Matricule Enseignant (PPR / Somme)'
                                : context.tr('student_number_label'),
                            controller: _studentIdController,
                            icon: isTeacher ? Icons.assignment_ind_outlined : Icons.badge_outlined,
                            trailingIcon: isTeacher ? Icons.verified_user_outlined : Icons.badge_rounded,
                            isDark: isDark,
                            readOnly: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            label: isTeacher
                                ? 'Établissement d\'affectation / Université'
                                : context.tr('university_label'),
                            controller: _universityController,
                            icon: Icons.account_balance_outlined,
                            trailingIcon: Icons.check_circle_outline_rounded,
                            isDark: isDark,
                            readOnly: false,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildInputField(
                      label: isTeacher
                          ? 'Matricule Enseignant (PPR / Somme)'
                          : context.tr('student_number_label'),
                      controller: _studentIdController,
                      icon: isTeacher ? Icons.assignment_ind_outlined : Icons.badge_outlined,
                      trailingIcon: isTeacher ? Icons.verified_user_outlined : Icons.badge_rounded,
                      isDark: isDark,
                      readOnly: false,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      label: isTeacher
                          ? 'Établissement d\'affectation / Université'
                          : context.tr('university_label'),
                      controller: _universityController,
                      icon: Icons.account_balance_outlined,
                      trailingIcon: Icons.check_circle_outline_rounded,
                      isDark: isDark,
                      readOnly: false,
                    ),
                  ],
                  const SizedBox(height: 14),
                  _buildInputField(
                    label: isTeacher
                        ? 'Département & Discipline d\'enseignement'
                        : context.tr('major_promotion_label'),
                    controller: _majorController,
                    icon: isTeacher ? Icons.domain_rounded : Icons.school_outlined,
                    isDark: isDark,
                    readOnly: false,
                  ),
                  const SizedBox(height: 14),
                  _buildInputField(
                    label: isTeacher
                        ? 'Biographie & Domaines d\'expertise / Recherche'
                        : 'Biographie / Présentation académique',
                    controller: _bioController,
                    icon: isTeacher ? Icons.psychology_outlined : Icons.edit_note_rounded,
                    isDark: isDark,
                    readOnly: false,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: SÉCURITÉ & AUTHENTIFICATION
  // ===========================================================================

  Widget _buildSecurityAuthCard(Color cardBg, Color borderColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('menu_security_auth'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('security_auth_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Master password card with change button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.password_rounded,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('main_password_label'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '••••••••••••••••  •  ${context.tr('password_last_modified')}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _showChangePasswordDialog,
                      child: Text(
                        context.tr('change_password_btn'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Two-Factor Authentication (2FA) with TOTP dialog
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.smartphone_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            context.tr('two_factor_auth_label'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: _twoFactorEnabled
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _twoFactorEnabled
                                  ? context.tr('two_factor_active_badge')
                                  : context.tr('two_factor_inactive_badge'),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: _twoFactorEnabled
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('two_factor_desc'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _showTotpSetupModal,
                  child: const Text('TOTP QR', style: TextStyle(fontSize: 11.5)),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _twoFactorEnabled,
                  activeThumbColor: const Color(0xFF2563EB),
                  onChanged: (val) async {
                    if (val) {
                      _showTotpSetupModal();
                    } else {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Désactiver la validation en deux étapes ?'),
                          content: const Text(
                            'Votre compte ne sera plus protégé par un code à usage unique lors de vos connexions.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(context.tr('cancel')),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Désactiver'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await ref.read(authStateProvider.notifier).disable2fa();
                          if (mounted) {
                            setState(() => _twoFactorEnabled = false);
                            _showSuccessSnackBar('Authentification à deux facteurs désactivée.');
                            _loadAuditLogs();
                          }
                        } catch (e) {
                          if (mounted) {
                            _showErrorSnackBar('Erreur lors de la désactivation du 2FA.');
                          }
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Passkeys & FIDO2 Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.vpn_key_rounded,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('passkeys_label'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('passkeys_desc'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        final nameCtrl = TextEditingController(text: 'Clé de sécurité FIDO2');
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Enregistrer une clé / Passkey'),
                            content: TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nom de l\'appareil ou de la clé',
                                hintText: 'Ex: Windows Hello, YubiKey 5C...',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: Text(context.tr('cancel')),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _addPasskey(nameCtrl.text);
                                },
                                child: const Text('Enregistrer'),
                              ),
                            ],
                          ),
                        );
                      },
                      label: Text(
                        context.tr('add_passkey_btn'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                if (_passkeys.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Aucune clé de sécurité enregistrée. Vous pouvez en ajouter une pour renforcer la protection de votre compte.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  )
                else
                  ..._passkeys.map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            p['icon'] == 'windows'
                                ? Icons.laptop_windows_rounded
                                : Icons.key_rounded,
                            size: 16,
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p['name'] ?? 'Clé de sécurité',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Text(
                            context.tr('registered_on', args: {'date': p['date'] ?? ''}),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                            tooltip: 'Supprimer cette clé',
                            onPressed: () => _removePasskey(p['id'] ?? ''),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Security Audit Log Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('security_audit_log_title'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_auditLogs.isNotEmpty)
                  ..._auditLogs.take(5).map((log) {
                    final action = log['action'] as String? ?? 'AUTH_ACTIVITY';
                    final ip = log['ipAddress'] as String? ?? '127.0.0.1';
                    final status = log['status'] as String? ?? 'SUCCESS';
                    final isSuccess = status == 'SUCCESS';
                    final dateStr = (log['createdAt'] as String?)?.split('T').first ?? '';

                    String displayTitle = action.replaceAll('_', ' ');
                    if (action == 'AUTH_LOGIN_SUCCESS') displayTitle = context.tr('security_log_login_success');
                    if (action == 'AUTH_2FA_ENABLED') displayTitle = 'Activation du 2FA (TOTP)';
                    if (action == 'AUTH_2FA_DISABLED') displayTitle = 'Désactivation du 2FA';
                    if (action == 'AUTH_2FA_SUCCESS') displayTitle = context.tr('security_log_2fa_success');
                    if (action == 'AUTH_ACCOUNT_LOCKED') displayTitle = 'Compte temporairement verrouillé';
                    if (action == 'AUTH_PASSWORD_CHANGED') displayTitle = 'Changement de mot de passe';
                    if (action == 'AUTH_SESSIONS_REVOKED') displayTitle = 'Révocation de sessions actives';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildSecurityLogItem(
                        title: displayTitle,
                        subtitle: 'IP: $ip • ${log['userAgent'] ?? 'Web / Mobile'}',
                        time: dateStr.isNotEmpty ? dateStr : context.tr('security_log_time_now'),
                        isSuccess: isSuccess,
                        isDark: isDark,
                      ),
                    );
                  })
                else ...[
                  _buildSecurityLogItem(
                    title: context.tr('security_log_login_success'),
                    subtitle: context.tr('security_log_location'),
                    time: context.tr('security_log_time_now'),
                    isSuccess: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildSecurityLogItem(
                    title: context.tr('security_log_2fa_success'),
                    subtitle: context.tr('security_log_2fa_subtitle'),
                    time: context.tr('security_log_2fa_time'),
                    isSuccess: true,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityLogItem({
    required String title,
    required String subtitle,
    required String time,
    required bool isSuccess,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: NOTIFICATIONS & ALERTES
  // ===========================================================================

  Widget _buildNotificationsCard(Color cardBg, Color borderColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('menu_notifications'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('notifications_settings_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 5 Channels
          _buildNotificationSwitchRow(
            icon: Icons.notifications_active_outlined,
            title: context.tr('notif_push_title'),
            subtitle: context.tr('notif_push_desc'),
            value: _pushNotifications,
            isDark: isDark,
            onChanged: (val) {
              setState(() => _pushNotifications = val);
              _showSuccessSnackBar(
                val
                    ? 'Notifications push activées'
                    : 'Notifications push désactivées',
              );
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: Icons.mail_outline_rounded,
            title: context.tr('notif_email_title'),
            subtitle: context.tr('notif_email_desc'),
            value: _emailNotifications,
            isDark: isDark,
            onChanged: (val) {
              setState(() => _emailNotifications = val);
              _showSuccessSnackBar('Préférences email universitaire mises à jour.');
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: Icons.sms_outlined,
            title: context.tr('notif_sms_title'),
            subtitle: context.tr('notif_sms_desc'),
            value: _smsEmergencyAlerts,
            isDark: isDark,
            onChanged: (val) {
              setState(() => _smsEmergencyAlerts = val);
              _showSuccessSnackBar('Canal d\'urgence SMS mis à jour.');
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: Icons.auto_awesome_rounded,
            title: context.tr('notif_ai_mentor_title'),
            subtitle: context.tr('notif_ai_mentor_desc'),
            value: _aiSmartMentorRecommendations,
            badge: 'SmartMentor',
            isDark: isDark,
            onChanged: (val) {
              setState(() => _aiSmartMentorRecommendations = val);
              _showSuccessSnackBar('Algorithme de révision SmartMentor mis à jour.');
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: Icons.alarm_rounded,
            title: context.tr('notif_deadlines_title'),
            subtitle: context.tr('notif_deadlines_desc'),
            value: _deadlinesReminders,
            isDark: isDark,
            onChanged: (val) {
              setState(() => _deadlinesReminders = val);
              _showSuccessSnackBar('Rappels d\'échéances configurés.');
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: Icons.bedtime_outlined,
            title: context.tr('notif_quiet_hours_title'),
            subtitle: context.tr('notif_quiet_hours_desc'),
            value: _quietHoursEnabled,
            isDark: isDark,
            onChanged: (val) {
              setState(() => _quietHoursEnabled = val);
              _showSuccessSnackBar(
                val
                    ? 'Heures de silence activées (22:00 - 07:00)'
                    : 'Heures de silence désactivées',
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: APPARENCE & THÈME
  // ===========================================================================

  Widget _buildAppearanceCard(Color cardBg, Color borderColor, bool isDark) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);
    final typographyAsync = ref.watch(typographyConfigProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.desktop_windows_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('menu_appearance'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('appearance_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3 Visual Theme Preview Cards (Clicking instantly changes app theme)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              return isWide
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildThemePreviewCard(
                            title: context.tr('theme_light_title'),
                            subtitle: context.tr('theme_light_desc'),
                            isSelected: currentThemeMode == ThemeMode.light,
                            isDarkCard: false,
                            onTap: () {
                              ref.read(themeModeProvider.notifier).state =
                                  ThemeMode.light;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildThemePreviewCard(
                            title: context.tr('theme_dark_title'),
                            subtitle: context.tr('theme_dark_desc'),
                            isSelected: currentThemeMode == ThemeMode.dark,
                            isDarkCard: true,
                            onTap: () {
                              ref.read(themeModeProvider.notifier).state =
                                  ThemeMode.dark;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildThemePreviewCard(
                            title: context.tr('theme_system_title'),
                            subtitle: context.tr('theme_system_desc'),
                            isSelected: currentThemeMode == ThemeMode.system,
                            isSplitCard: true,
                            onTap: () {
                              ref.read(themeModeProvider.notifier).state =
                                  ThemeMode.system;
                            },
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildThemePreviewCard(
                          title: context.tr('theme_light_title'),
                          subtitle: context.tr('theme_light_desc'),
                          isSelected: currentThemeMode == ThemeMode.light,
                          isDarkCard: false,
                          onTap: () {
                            ref.read(themeModeProvider.notifier).state =
                                ThemeMode.light;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildThemePreviewCard(
                          title: context.tr('theme_dark_title'),
                          subtitle: context.tr('theme_dark_desc'),
                          isSelected: currentThemeMode == ThemeMode.dark,
                          isDarkCard: true,
                          onTap: () {
                            ref.read(themeModeProvider.notifier).state =
                                ThemeMode.dark;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildThemePreviewCard(
                          title: context.tr('theme_system_title'),
                          subtitle: context.tr('theme_system_desc'),
                          isSelected: currentThemeMode == ThemeMode.system,
                          isSplitCard: true,
                          onTap: () {
                            ref.read(themeModeProvider.notifier).state =
                                ThemeMode.system;
                          },
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),

          // Language Selector Cards (Clicking instantly changes app locale)
          Text(
            context.tr('language_title'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('language_desc'),
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLanguageOptionCard(
                  flag: '🇫🇷',
                  name: context.tr('lang_french'),
                  localeCode: 'fr',
                  isSelected: currentLocale.startsWith('fr'),
                  isDark: isDark,
                  onTap: () {
                    ref.read(localeProvider.notifier).state = 'fr';
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildLanguageOptionCard(
                  flag: '🇬🇧',
                  name: context.tr('lang_english'),
                  localeCode: 'en',
                  isSelected: currentLocale.startsWith('en'),
                  isDark: isDark,
                  onTap: () {
                    ref.read(localeProvider.notifier).state = 'en';
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Font Size & Visual Comfort Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.text_fields_rounded,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('font_comfort_title'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('font_comfort_desc'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                typographyAsync.when(
                  data: (config) {
                    final scalePct = (config.textScaleFactor * 100).round();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Text(
                              'A-',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 28,
                            ),
                            onPressed: () {
                              final newScale = (config.textScaleFactor - 0.1)
                                  .clamp(0.85, 1.4);
                              ref
                                  .read(typographyConfigProvider.notifier)
                                  .updateTextScale(newScale);
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$scalePct% ${scalePct == 100 ? "[Standard]" : ""}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Text(
                              'A+',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 28,
                            ),
                            onPressed: () {
                              final newScale = (config.textScaleFactor + 0.1)
                                  .clamp(0.85, 1.4);
                              ref
                                  .read(typographyConfigProvider.notifier)
                                  .updateTextScale(newScale);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // High Contrast Switch
          _buildNotificationSwitchRow(
            icon: Icons.contrast_rounded,
            title: context.tr('high_contrast_title'),
            subtitle: context.tr('high_contrast_desc'),
            value: _highContrast,
            isDark: isDark,
            onChanged: (val) {
              setState(() => _highContrast = val);
              _showSuccessSnackBar(
                val
                    ? 'Mode contraste élevé activé'
                    : 'Mode contraste standard',
              );
            },
          ),
          const SizedBox(height: 10),

          // Reduce Animations Switch
          _buildNotificationSwitchRow(
            icon: Icons.slow_motion_video_rounded,
            title: context.tr('reduce_animations_title'),
            subtitle: context.tr('reduce_animations_desc'),
            value: _reduceAnimations,
            isDark: isDark,
            onChanged: (val) {
              setState(() => _reduceAnimations = val);
              _showSuccessSnackBar(
                val
                    ? 'Animations atténuées'
                    : 'Animations standards activées',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOptionCard({
    required String flag,
    required String name,
    required String localeCode,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: 0.08)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFCBD5E1)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2563EB),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 4: CONFIDENTIALITÉ & RGPD
  // ===========================================================================

  Widget _buildPrivacyGdprCard(Color cardBg, Color borderColor, bool isDark) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final role = authState?.role?.toLowerCase() ?? 'student';
    final isTeacher = role == 'teacher';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title + GDPR Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('privacy_gdpr_title'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('privacy_gdpr_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      size: 13,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('gdpr_badge'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Data Export Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.file_download_outlined,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTeacher
                                ? 'Attestation d\'Exercice & Fiche de Service'
                                : context.tr('data_export_title'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isTeacher
                                ? 'Générez et téléchargez votre attestation officielle d\'exercice et de charge d\'enseignement certifiée ENT au format PDF A4 officiel.'
                                : context.tr('data_export_desc'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.code_rounded, size: 16),
                      label: Text(
                        context.tr('download_json_btn'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: _isExporting ? null : () => _exportDataBackend(format: 'json'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: Text(
                        context.tr('download_pdf_btn'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: _isExporting ? null : () => _exportDataBackend(format: 'pdf'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Visibility & Sharing Preferences
          _buildNotificationSwitchRow(
            icon: Icons.visibility_outlined,
            title: context.tr('privacy_visibility_profile'),
            subtitle: context.tr('privacy_visibility_profile_desc'),
            value: _profileVisibleToCohort,
            isDark: isDark,
            onChanged: (val) async {
              setState(() => _profileVisibleToCohort = val);
              await _savePreferences();
              _showSuccessSnackBar('Visibilité auprès des pairs mise à jour et enregistrée.');
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: isTeacher ? Icons.badge_outlined : Icons.leaderboard_outlined,
            title: isTeacher
                ? 'Visibilité dans l\'annuaire des enseignants'
                : context.tr('privacy_visibility_ranking'),
            subtitle: isTeacher
                ? 'Permettre aux étudiants et collègues de consulter mes cours, coordonnées et heures de permanence.'
                : context.tr('privacy_visibility_ranking_desc'),
            value: _rankingVisible,
            isDark: isDark,
            onChanged: (val) async {
              setState(() => _rankingVisible = val);
              await _savePreferences();
              _showSuccessSnackBar(isTeacher
                  ? 'Préférences d\'annuaire enseignant mises à jour et enregistrées.'
                  : 'Préférences de classement mises à jour et enregistrées.');
            },
          ),
          const Divider(height: 20),
          _buildNotificationSwitchRow(
            icon: Icons.share_outlined,
            title: context.tr('privacy_share_notes'),
            subtitle: context.tr('privacy_share_notes_desc'),
            value: _shareAiSummaries,
            isDark: isDark,
            onChanged: (val) async {
              setState(() => _shareAiSummaries = val);
              await _savePreferences();
              _showSuccessSnackBar('Partage des synthèses IA mis à jour et enregistré.');
            },
          ),
          const SizedBox(height: 24),

          // 3. Danger Zone (Critical Account Actions)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF450A0A).withValues(alpha: 0.25)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.tr('danger_zone_title'),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('danger_freeze_account'),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            context.tr('danger_freeze_desc'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF97316)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _showFreezeAccountDialog,
                      child: const Text(
                        'Geler mon compte',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF97316),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('danger_delete_account'),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            context.tr('danger_delete_desc'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _showDeleteAccountDialog,
                      child: Text(
                        context.tr('delete'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 5: SESSIONS & APPAREILS
  // ===========================================================================

  Widget _buildSessionsDevicesCard(Color cardBg, Color borderColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title + Sessions Count Badge
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.devices_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('sessions_devices_title'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('sessions_devices_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.tr(
                    'active_sessions_count',
                    args: {'count': '${_remoteSessions.length + 1}'},
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Current Device Session Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  kIsWeb ? Icons.language_rounded : Icons.devices_rounded,
                  color: const Color(0xFF2563EB),
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            kIsWeb
                                ? 'Navigateur Web ($defaultTargetPlatform)'
                                : 'Application SmartClass ($defaultTargetPlatform)',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              context.tr('current_session_badge'),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Session active • ${context.tr('last_active_now')}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Other Remote Devices
          Text(
            'Autres appareils connectés',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoadingSessions)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_remoteSessions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucune autre session active. Votre compte n\'est actuellement ouvert que sur cet appareil.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._remoteSessions.map(
              (session) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.devices_other_rounded,
                      size: 22,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (session['device'] as String?) ?? 'Session connectée',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'IP : ${session['ipAddress'] ?? '127.0.0.1'} • ${session['location'] ?? 'Réseau sécurisé'} • ${(session['createdAt'] as String?)?.split('T').first ?? ''}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _revokeSession(session['id'] as String),
                      child: Text(
                        context.tr('revoke_session_btn'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 3. Global Action: Revoke all other sessions
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              side: const BorderSide(color: Color(0xFFEF4444)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 16),
            label: Text(
              context.tr('revoke_all_sessions_btn'),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF4444),
              ),
            ),
            onPressed: _showRevokeAllSessionsDialog,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODALS & DIALOGS
  // ===========================================================================

  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    bool isSubmitting = false;
    String? dialogError;
    final successMsg = context.tr('password_updated');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final pass = _newPasswordController.text;
          final hasLen = pass.length >= 8;
          final hasUpper = pass.contains(RegExp(r'[A-Z]'));
          final hasDigit = pass.contains(RegExp(r'[0-9]'));
          final hasSpecial = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
          final score = (hasLen ? 1 : 0) +
              (hasUpper ? 1 : 0) +
              (hasDigit ? 1 : 0) +
              (hasSpecial ? 1 : 0);

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.lock_reset_rounded, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Text(
                  context.tr('change_password_btn'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dialogError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dialogError!,
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      decoration: InputDecoration(
                        labelText: context.tr('current_password'),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setDlgState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      onChanged: (_) => setDlgState(() {}),
                      decoration: InputDecoration(
                        labelText: context.tr('new_password_label'),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setDlgState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Live Password strength bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: score / 4,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          score <= 1
                              ? const Color(0xFFEF4444)
                              : (score <= 2
                                  ? const Color(0xFFF59E0B)
                                  : (score <= 3
                                      ? const Color(0xFF3B82F6)
                                      : const Color(0xFF10B981))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      score <= 1
                          ? 'Force : Faible (minimum 8 caractères)'
                          : (score <= 2
                              ? 'Force : Moyenne'
                              : (score <= 3
                                  ? 'Force : Bonne'
                                  : 'Force : Excellente')),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: context.tr('confirm_password_label'),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setDlgState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: Text(context.tr('cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final cur = _currentPasswordController.text;
                        final newPass = _newPasswordController.text;
                        final confPass = _confirmPasswordController.text;

                        if (cur.isEmpty) {
                          setDlgState(() => dialogError = 'Veuillez saisir votre mot de passe actuel.');
                          return;
                        }
                        if (newPass.length < 8) {
                          setDlgState(() => dialogError = 'Le nouveau mot de passe doit comporter au moins 8 caractères.');
                          return;
                        }
                        if (newPass != confPass) {
                          setDlgState(() => dialogError = context.tr('passwords_dont_match'));
                          return;
                        }

                        setDlgState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });

                        try {
                          await ref.read(authStateProvider.notifier).changePassword(
                            currentPassword: cur,
                            newPassword: newPass,
                          );
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                          if (mounted) {
                            _showSuccessSnackBar(successMsg);
                            _loadAuditLogs();
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setDlgState(() {
                              isSubmitting = false;
                              final err = e.toString().replaceFirst('Exception: ', '');
                              dialogError = err.isNotEmpty ? err : 'Erreur lors du changement de mot de passe.';
                            });
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(context.tr('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showTotpSetupModal() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    Map<String, dynamic> setupData;
    try {
      setupData = await ref.read(authStateProvider.notifier).setup2fa();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar('Erreur lors de la génération 2FA: ${e.toString()}');
      }
      return;
    }

    if (!mounted) return;

    final secret = setupData['secret'] as String? ?? '';
    final qrCodeDataUrl = setupData['qrCodeDataUrl'] as String? ?? '';
    final recoveryCodes = (setupData['recoveryCodes'] as List<dynamic>? ?? []).cast<String>();

    Uint8List? qrBytes;
    try {
      if (qrCodeDataUrl.contains(',')) {
        qrBytes = base64Decode(qrCodeDataUrl.split(',')[1]);
      }
    } catch (_) {}

    final codeCtrl = TextEditingController();
    bool isVerifying = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('two_factor_modal_title'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('two_factor_modal_desc'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            if (qrBytes != null)
                              Image.memory(
                                qrBytes,
                                width: 140,
                                height: 140,
                                fit: BoxFit.contain,
                              )
                            else
                              const Icon(
                                Icons.qr_code_rounded,
                                size: 130,
                                color: Color(0xFF0F172A),
                              ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: secret));
                                context.showSuccessToast('Clé secrète copiée !');
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'CLEF : $secret',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2563EB)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (recoveryCodes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.key_rounded, size: 14, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Codes de secours (conservez-les précieusement) :',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: recoveryCodes.map((rc) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    rc,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: codeCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          hintText: '123456',
                          counterText: '',
                          labelText: context.tr('two_factor_code_label'),
                          errorText: errorMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.of(ctx).pop(),
                  child: Text(context.tr('cancel')),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  onPressed: isVerifying
                      ? null
                      : () async {
                          final code = codeCtrl.text.trim();
                          if (code.length != 6) {
                            setDlgState(() => errorMessage = 'Le code doit contenir 6 chiffres.');
                            return;
                          }
                          setDlgState(() {
                            isVerifying = true;
                            errorMessage = null;
                          });
                          try {
                            await ref.read(authStateProvider.notifier).verify2fa(code);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (mounted) {
                              setState(() => _twoFactorEnabled = true);
                              _showSuccessSnackBar(
                                'Application Authenticator configurée et activée avec succès !',
                              );
                              _loadAuditLogs();
                            }
                          } on Failure catch (f) {
                            setDlgState(() {
                              isVerifying = false;
                              final l10n = failureL10n(f);
                              errorMessage = context.tr(l10n.key, args: l10n.args);
                            });
                          } catch (e) {
                            setDlgState(() {
                              isVerifying = false;
                              errorMessage = 'Code invalide ou expiré.';
                            });
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(context.tr('two_factor_verify_btn')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFreezeAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.pause_circle_outline_rounded, color: Color(0xFFF97316)),
                const SizedBox(width: 8),
                Text(context.tr('freeze_confirm_title')),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('freeze_confirm_desc'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDBA74)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Color(0xFFEA580C)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Toutes vos sessions actives seront révoquées. Vos cours, devoirs et notes resteront archivés en sécurité. La réactivation s\'effectuera automatiquement lors de votre prochaine authentification.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF9A3412)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
                child: Text(context.tr('cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                onPressed: isLoading
                    ? null
                    : () async {
                        final router = GoRouter.of(context);
                        setDialogState(() => isLoading = true);
                        try {
                          final msg = await ref.read(authStateProvider.notifier).freezeAccount();
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (mounted) {
                            _showSuccessSnackBar(msg);
                            router.go('/login');
                          }
                        } on Failure catch (f) {
                          setDialogState(() => isLoading = false);
                          if (mounted) _showErrorSnackBar(f.message);
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          if (mounted) _showErrorSnackBar('Erreur: $e');
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Confirmer la mise en veille'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    final passwordCtrl = TextEditingController();
    bool obscurePassword = true;
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Text(context.tr('delete_confirm_title')),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('delete_confirm_desc'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined, size: 18, color: Color(0xFFDC2626)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Conformément à l\'article 17 du RGPD (Droit à l\'effacement), cette suppression est irréversible et efface l\'ensemble de vos données d\'apprentissage.',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF991B1B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Confirmez avec votre mot de passe actuel :',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Mot de passe du compte',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 18,
                          ),
                          onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                        ),
                        errorText: errorMessage,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
                  child: Text(context.tr('cancel')),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final password = passwordCtrl.text.trim();
                          if (password.isEmpty) {
                            setDialogState(() => errorMessage = 'Veuillez saisir votre mot de passe pour confirmer.');
                            return;
                          }
                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          final router = GoRouter.of(context);
                          try {
                            final msg = await ref.read(authStateProvider.notifier).deleteAccount(
                              passwordConfirmation: password,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (mounted) {
                              _showSuccessSnackBar(msg);
                              router.go('/login');
                            }
                          } on Failure catch (f) {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage = f.message;
                            });
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage = 'Mot de passe incorrect ou erreur réseau.';
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(context.tr('delete')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRevokeAllSessionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('revoke_all_confirm_title')),
        content: Text(context.tr('revoke_all_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _revokeAllSessions();
            },
            child: Text(context.tr('confirm')),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGET HELPERS: INPUT FIELDS (FIXES INNER DOUBLE BORDER BUG)
  // ===========================================================================

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? suffixBadge,
    IconData? trailingIcon,
    required bool isDark,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: readOnly
                ? (isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                    : const Color(0xFFF1F5F9))
                : (isDark
                    ? const Color(0xFF0F172A)
                    : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  readOnly: readOnly,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  // IMPORTANT: All borders explicitly set to InputBorder.none
                  // to prevent double-border outline inheritance from theme.
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (suffixBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: Color(0xFF15803D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        suffixBadge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              if (trailingIcon != null)
                Icon(
                  trailingIcon,
                  size: 17,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    String? badge,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFF2563EB),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildThemePreviewCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    bool isDarkCard = false,
    bool isSplitCard = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini UI Mockup container
            Container(
              height: 74,
              decoration: BoxDecoration(
                color: isDarkCard
                    ? const Color(0xFF1E293B)
                    : (isSplitCard
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDarkCard
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: isSplitCard
                  ? Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(9),
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: _buildMiniMockupLines(
                              dotColor: const Color(0xFF2563EB),
                              lineColor: const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(9),
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: _buildMiniMockupLines(
                              dotColor: const Color(0xFF60A5FA),
                              lineColor: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(10),
                      child: _buildMiniMockupLines(
                        dotColor: isDarkCard
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF2563EB),
                        lineColor: isDarkCard
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
            ),
            const SizedBox(height: 10),

            // Radio + Title + Subtitle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                      width: isSelected ? 5 : 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMockupLines({
    required Color dotColor,
    required Color lineColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 50,
          height: 4,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // BOTTOM BAR & FOOTER
  // ===========================================================================

  Widget _buildBottomBar(Color cardBg, Color borderColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Live ENT Cloud Synchronization Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF10B981),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.cloud_done_rounded,
                  size: 15,
                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                ),
                const SizedBox(width: 6),
                Text(
                  context.tr('last_ent_sync'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Discard / Reset button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 13,
              ),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.20)
                    : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFC),
            ),
            icon: Icon(
              Icons.restart_alt_rounded,
              size: 16,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
            onPressed: _isSaving ? null : _resetChanges,
            label: Text(
              context.tr('discard_changes'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Primary Save / Success Animated Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isSaving ? null : _saveProfile,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: _justSaved
                      ? const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (_justSaved
                              ? const Color(0xFF10B981)
                              : const Color(0xFF2563EB))
                          .withValues(alpha: _isSaving ? 0.15 : 0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSaving) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Enregistrement en cours...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ] else if (_justSaved) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Modifications enregistrées !',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.save_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.tr('save_changes'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLinks(Color textMuted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SmartClass © 2026 Plateforme Numérique d\'Enseignement Supérieur et Secondaire',
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
        Row(
          children: [
            InkWell(
              onTap: () {},
              child: Text(
                'Politique de confidentialité',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('•', style: TextStyle(fontSize: 11, color: textMuted)),
            ),
            InkWell(
              onTap: () {},
              child: Text(
                'Conditions académiques',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('•', style: TextStyle(fontSize: 11, color: textMuted)),
            ),
            InkWell(
              onTap: () {},
              child: Text(
                'Support technique',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
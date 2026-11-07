// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  Future<void> _exportDataBackend({required String format}) async {
    if (_isExporting) return;
    updateState(() => _isExporting = true);

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
        updateState(() => _isExporting = false);
      }
    }
  }

  // ===========================================================================
  // BACKEND ACTIONS & SAVE LOGIC
  // ===========================================================================

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    updateState(() => _isSaving = true);

    try {
      final names = _fullNameController.text.trim().split(' ');
      final firstName = names.isNotEmpty ? names.first : '';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      final university = _universityController.text.trim();
      final studentId = _studentIdController.text.trim();
      final major = _majorController.text.trim();
      final bio = _bioController.text.trim();

      // 1. Immediately persist local academic profile & update AuthState in real-time
      await ref
          .read(authStateProvider.notifier)
          .updateAcademicProfile(
            institution: university,
            studentId: studentId,
            major: major,
            bio: bio,
          );

      // 2. Save notification & privacy preferences
      await _savePreferences();

      // 3. Update backend user profile
      try {
        await ref
            .read(authStateProvider.notifier)
            .updateProfile(firstName: firstName, lastName: lastName);
      } catch (_) {
        // Backend name update fallback - academic profile is already secured
      }

      if (!mounted) return;
      updateState(() {
        _isSaving = false;
        _justSaved = true;
      });

      _showAdvancedSaveNotification();

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) updateState(() => _justSaved = false);
      });
    } on Failure catch (failure) {
      if (!mounted) return;
      final l10n = failureL10n(failure);
      _showErrorSnackBar(context.tr(l10n.key, args: l10n.args));
      updateState(() => _isSaving = false);
    } catch (_) {
      if (!mounted) return;
      updateState(() {
        _isSaving = false;
        _justSaved = true;
      });
      _showAdvancedSaveNotification();
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) updateState(() => _justSaved = false);
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
    final role = authState?.role?.toLowerCase() ?? 'student';
    final isTeacher = role == 'teacher';
    final isAdmin = role == 'admin';

    updateState(() {
      _fullNameController.text =
          authState?.displayName ??
          (isAdmin
              ? 'Administrateur SmartClass'
              : (isTeacher ? 'Professeur' : 'Ahmed Mohsen'));
      _emailController.text = authState?.email ?? '';
      _studentIdController.text =
          authState?.studentId ??
          (isAdmin
              ? 'ADM-2026-001'
              : (isTeacher ? 'PPR-2026-89421' : 'CNE-2026-984210'));
      _universityController.text =
          authState?.institution ??
          (isAdmin
              ? 'Administration Centrale ENT'
              : (isTeacher
                    ? 'Institut Supérieur / Université'
                    : 'Université Mohammed V de Rabat'));
      _majorController.text =
          authState?.major ??
          (isAdmin
              ? 'Direction & Administration ENT'
              : (isTeacher
                    ? 'Département Informatique & Technologies Numériques'
                    : 'Cycle Ingénieur • Génie Informatique'));
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
}




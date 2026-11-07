// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
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
          final score =
              (hasLen ? 1 : 0) +
              (hasUpper ? 1 : 0) +
              (hasDigit ? 1 : 0) +
              (hasSpecial ? 1 : 0);

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
              width: context.screenWidth >= 600
                  ? 440
                  : (context.screenWidth - 48),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dialogError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 16,
                            ),
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
                          onPressed: () => setDlgState(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
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
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
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
                          onPressed: () => setDlgState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
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
                          setDlgState(
                            () => dialogError =
                                'Veuillez saisir votre mot de passe actuel.',
                          );
                          return;
                        }
                        if (newPass.length < 8) {
                          setDlgState(
                            () => dialogError =
                                'Le nouveau mot de passe doit comporter au moins 8 caractères.',
                          );
                          return;
                        }
                        if (newPass != confPass) {
                          setDlgState(
                            () => dialogError = context.tr(
                              'passwords_dont_match',
                            ),
                          );
                          return;
                        }

                        setDlgState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });

                        try {
                          await ref
                              .read(authStateProvider.notifier)
                              .changePassword(
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
                              final err = e.toString().replaceFirst(
                                'Exception: ',
                                '',
                              );
                              dialogError = err.isNotEmpty
                                  ? err
                                  : 'Erreur lors du changement de mot de passe.';
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

}

// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  Widget _buildSecurity2faSection(
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    // 2. Two-Factor Authentication (2FA) with TOTP dialog
    return Container(
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 460;
          final switchWidget = Switch(
            value: _twoFactorEnabled,
            activeThumbColor: const Color(0xFF2563EB),
            onChanged: (val) async {
              if (val) {
                _showTotpSetupModal();
              } else {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text(
                      'Désactiver la validation en deux étapes ?',
                    ),
                    content: const Text(
                      'Votre compte ne sera plus protégé par un code à usage unique lors de vos connexions.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(context.tr('cancel')),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                        ),
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
                      updateState(() => _twoFactorEnabled = false);
                      _showSuccessSnackBar(
                        'Authentification à deux facteurs désactivée.',
                      );
                      _loadAuditLogs();
                    }
                  } catch (e) {
                    if (mounted) {
                      _showErrorSnackBar(
                        'Erreur lors de la désactivation du 2FA.',
                      );
                    }
                  }
                }
              }
            },
          );

          final totpButton = OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              side: BorderSide(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _showTotpSetupModal,
            child: const Text('TOTP QR', style: TextStyle(fontSize: 11.5)),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.smartphone_rounded,
                      color: Color(0xFF10B981),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
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
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    totpButton,
                    const SizedBox(width: 10),
                    switchWidget,
                  ],
                ),
              ],
            );
          }

          return Row(
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
              totpButton,
              const SizedBox(width: 8),
              switchWidget,
            ],
          );
        },
      ),
    );
  }
}

// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  Future<void> _showTotpSetupModal() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic> setupData;
    try {
      setupData = await ref.read(authStateProvider.notifier).setup2fa();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar(
          'Erreur lors de la génération 2FA: ${e.toString()}',
        );
      }
      return;
    }

    if (!mounted) return;

    final secret = setupData['secret'] as String? ?? '';
    final qrCodeDataUrl = setupData['qrCodeDataUrl'] as String? ?? '';
    final recoveryCodes = (setupData['recoveryCodes'] as List<dynamic>? ?? [])
        .cast<String>();

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                width: context.screenWidth >= 600
                    ? 420
                    : (context.screenWidth - 48),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('two_factor_modal_desc'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
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
                                context.showSuccessToast(
                                  'Clé secrète copiée !',
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
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
                                    const Icon(
                                      Icons.copy_rounded,
                                      size: 14,
                                      color: Color(0xFF2563EB),
                                    ),
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
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.key_rounded,
                                    size: 14,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Codes de secours (conservez-les précieusement) :',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: recoveryCodes
                                    .map(
                                      (rc) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white10
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          rc,
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                  ),
                  onPressed: isVerifying
                      ? null
                      : () async {
                          final code = codeCtrl.text.trim();
                          if (code.length != 6) {
                            setDlgState(
                              () => errorMessage =
                                  'Le code doit contenir 6 chiffres.',
                            );
                            return;
                          }
                          setDlgState(() {
                            isVerifying = true;
                            errorMessage = null;
                          });
                          try {
                            await ref
                                .read(authStateProvider.notifier)
                                .verify2fa(code);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (mounted) {
                              updateState(() => _twoFactorEnabled = true);
                              _showSuccessSnackBar(
                                'Application Authenticator configurée et activée avec succès !',
                              );
                              _loadAuditLogs();
                            }
                          } on Failure catch (f) {
                            setDlgState(() {
                              isVerifying = false;
                              final l10n = failureL10n(f);
                              errorMessage = context.tr(
                                l10n.key,
                                args: l10n.args,
                              );
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
}

// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  void _showFreezeAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.pause_circle_outline_rounded,
                  color: Color(0xFFF97316),
                ),
                const SizedBox(width: 8),
                Text(context.tr('freeze_confirm_title')),
              ],
            ),
            content: SizedBox(
              width: context.screenWidth >= 600
                  ? 440
                  : (context.screenWidth - 48),
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
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFFEA580C),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Toutes vos sessions actives seront révoquées. Vos cours, devoirs et notes resteront archivés en sécurité. La réactivation s\'effectuera automatiquement lors de votre prochaine authentification.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF9A3412),
                            ),
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
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final router = GoRouter.of(context);
                        setDialogState(() => isLoading = true);
                        try {
                          final msg = await ref
                              .read(authStateProvider.notifier)
                              .freezeAccount();
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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
                width: context.screenWidth >= 600
                    ? 460
                    : (context.screenWidth - 48),
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
                          Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: Color(0xFFDC2626),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Conformément à l\'article 17 du RGPD (Droit à l\'effacement), cette suppression est irréversible et efface l\'ensemble de vos données d\'apprentissage.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Confirmez avec votre mot de passe actuel :',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                          ),
                          onPressed: () => setDialogState(
                            () => obscurePassword = !obscurePassword,
                          ),
                        ),
                        errorText: errorMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final password = passwordCtrl.text.trim();
                          if (password.isEmpty) {
                            setDialogState(
                              () => errorMessage =
                                  'Veuillez saisir votre mot de passe pour confirmer.',
                            );
                            return;
                          }
                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          final router = GoRouter.of(context);
                          try {
                            final msg = await ref
                                .read(authStateProvider.notifier)
                                .deleteAccount(passwordConfirmation: password);
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
                              errorMessage =
                                  'Mot de passe incorrect ou erreur réseau.';
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
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
}




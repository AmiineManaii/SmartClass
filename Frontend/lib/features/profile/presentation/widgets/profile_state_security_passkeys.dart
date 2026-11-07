// ignore_for_file: unused_element, unused_field, prefer_final_fields
part of '../pages/profile_page.dart';

extension on _ProfilePageState {
  Widget _buildSecurityPasskeysSection(Color cardBg, Color borderColor, bool isDark) {
    
          // 3. Passkeys & FIDO2 Card
    return           Container(
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
                        final nameCtrl = TextEditingController(text: 'Cl├® de s├®curit├® FIDO2');
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Enregistrer une cl├® / Passkey'),
                            content: TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nom de l\'appareil ou de la cl├®',
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
                      'Aucune cl├® de s├®curit├® enregistr├®e. Vous pouvez en ajouter une pour renforcer la protection de votre compte.',
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
                              p['name'] ?? 'Cl├® de s├®curit├®',
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
                            tooltip: 'Supprimer cette cl├®',
                            onPressed: () => _removePasskey(p['id'] ?? ''),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
  }
}

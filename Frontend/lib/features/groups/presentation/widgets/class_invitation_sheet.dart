import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../home/application/providers/student_dashboard_provider.dart';

class ClassInvitationSheet extends ConsumerStatefulWidget {
  final String classGroupId;
  final String className;

  const ClassInvitationSheet({
    required this.classGroupId,
    required this.className,
    super.key,
  });

  static Future<void> show(
    BuildContext context, {
    required String classGroupId,
    required String className,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClassInvitationSheet(
        classGroupId: classGroupId,
        className: className,
      ),
    );
  }

  @override
  ConsumerState<ClassInvitationSheet> createState() => _ClassInvitationSheetState();
}

class _ClassInvitationSheetState extends ConsumerState<ClassInvitationSheet> {
  bool _loading = true;
  bool _actionLoading = false;
  String? _errorMessage;

  bool _hasActive = false;
  Map<String, dynamic>? _activeInvitation;

  String? _newlyGeneratedCode;
  int _selectedHours = 48;
  final _maxUsesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final remote = ref.read(groupsRemoteDataSourceProvider);
      final res = await remote.getInvitationStatus(widget.classGroupId);
      if (!mounted) return;
      setState(() {
        _hasActive = res['hasActiveInvitation'] as bool? ?? false;
        _activeInvitation = res['invitation'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is ApiException ? e.message : e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _generateCode() async {
    setState(() {
      _actionLoading = true;
      _errorMessage = null;
    });

    try {
      final remote = ref.read(groupsRemoteDataSourceProvider);
      final maxUses = int.tryParse(_maxUsesController.text.trim());
      final res = await remote.generateInvitation(
        widget.classGroupId,
        expiresInHours: _selectedHours > 0 ? _selectedHours : null,
        maxUses: maxUses,
      );

      final inv = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
      final rawCode = inv['rawCode'] as String? ?? '';

      if (!mounted) return;
      setState(() {
        _newlyGeneratedCode = rawCode;
        _actionLoading = false;
      });
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is ApiException ? e.message : e.toString();
        _actionLoading = false;
      });
    }
  }

  Future<void> _rotateCode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Régénérer le code d\'invitation ?'),
        content: const Text(
          'L\'ancien code d\'invitation sera immédiatement révoqué et ne pourra plus être utilisé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Régénérer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _actionLoading = true;
      _errorMessage = null;
    });

    try {
      final remote = ref.read(groupsRemoteDataSourceProvider);
      final res = await remote.rotateInvitation(
        widget.classGroupId,
        expiresInHours: _selectedHours > 0 ? _selectedHours : null,
      );

      final inv = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
      final rawCode = inv['rawCode'] as String? ?? '';

      if (!mounted) return;
      setState(() {
        _newlyGeneratedCode = rawCode;
        _actionLoading = false;
      });
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is ApiException ? e.message : e.toString();
        _actionLoading = false;
      });
    }
  }

  Future<void> _revokeCode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Révoquer le code d\'invitation ?'),
        content: const Text(
          'Les étudiants ne pourront plus rejoindre cette classe avec ce code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _actionLoading = true;
      _errorMessage = null;
    });

    try {
      final remote = ref.read(groupsRemoteDataSourceProvider);
      await remote.revokeInvitation(widget.classGroupId);
      if (!mounted) return;
      setState(() {
        _newlyGeneratedCode = null;
        _actionLoading = false;
      });
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is ApiException ? e.message : e.toString();
        _actionLoading = false;
      });
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code d\'invitation copié dans le presse-papier !'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.key_rounded, color: colorScheme.onPrimaryContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code d\'invitation',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.className,
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 24),
          if (_loading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else ...[
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            if (_newlyGeneratedCode != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.6),
                      colorScheme.surfaceContainerHighest,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.primary, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'Nouveau code généré',
                      style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _newlyGeneratedCode!,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copier le code'),
                      onPressed: () => _copyToClipboard(_newlyGeneratedCode!),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ce code ne sera affiché qu\'une seule fois en clair. Partagez-le avec vos étudiants.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_hasActive && _activeInvitation != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Statut de l\'invitation',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'Actif',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.people_alt_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          'Utilisations : ${_activeInvitation!['usedCount'] ?? 0}${_activeInvitation!['maxUses'] != null ? ' / ${_activeInvitation!['maxUses']}' : ' (illimité)'}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          _activeInvitation!['expiresAt'] != null
                              ? 'Expire le : ${_activeInvitation!['expiresAt'].toString().split('T').first}'
                              : 'Validité : Illimitée',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Régénérer'),
                      onPressed: _actionLoading ? null : _rotateCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.block_rounded, size: 18),
                      label: const Text('Révoquer'),
                      onPressed: _actionLoading ? null : _revokeCode,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Aucun code d\'invitation actif pour cette classe. Générez-en un pour permettre aux étudiants de rejoindre directement.',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _selectedHours,
                decoration: const InputDecoration(
                  labelText: 'Durée de validité',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 24, child: Text('24 heures')),
                  DropdownMenuItem(value: 48, child: Text('48 heures (Recommandé)')),
                  DropdownMenuItem(value: 168, child: Text('7 jours')),
                  DropdownMenuItem(value: 720, child: Text('30 jours')),
                  DropdownMenuItem(value: 0, child: Text('Sans expiration')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedHours = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxUsesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limite d\'utilisations (optionnel)',
                  hintText: 'ex: 40 (laisser vide pour illimité)',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: _actionLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_link_rounded),
                label: const Text('Générer un code'),
                onPressed: _actionLoading ? null : _generateCode,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

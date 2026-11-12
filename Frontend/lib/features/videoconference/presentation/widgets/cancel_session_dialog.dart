import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/smart_toast.dart';
import '../../application/videoconference_providers.dart';
import '../../domain/entities/video_session.dart';

class CancelSessionDialog extends ConsumerStatefulWidget {
  final VideoSession session;

  const CancelSessionDialog({
    super.key,
    required this.session,
  });

  @override
  ConsumerState<CancelSessionDialog> createState() => _CancelSessionDialogState();
}

class _CancelSessionDialogState extends ConsumerState<CancelSessionDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleCancel() async {
    setState(() => _isLoading = true);
    try {
      final reason = _reasonController.text.trim();
      await ref.read(sessionActionsNotifierProvider.notifier).cancelSession(
            widget.session.id,
            cancelReason: reason.isNotEmpty ? reason : null,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        SmartToast.success(
          context,
          context.tr('cancel_success'),
          title: 'Séance annulée',
        );
      }
    } catch (e) {
      if (mounted) {
        SmartToast.error(
          context,
          e.toString(),
          title: 'Erreur',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('cancel_session')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('confirm_cancel_session')),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: context.tr('cancel_reason'),
              hintText: context.tr('cancel_reason_hint'),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        AppButton(
          text: context.tr('cancel'),
          variant: AppButtonVariant.outlined,
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
        ),
        AppButton(
          text: context.tr('cancel_session'),
          variant: AppButtonVariant.primary,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _handleCancel,
        ),
      ],
    );
  }
}

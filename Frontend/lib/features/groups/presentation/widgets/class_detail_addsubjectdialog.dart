part of '../pages/class_detail_page.dart';
class _AddSubjectDialog extends StatefulWidget {
  const _AddSubjectDialog();

  @override
  State<_AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<_AddSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _hoursController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final hours = _hoursController.text.trim();
    Navigator.of(context).pop(
      _SubjectInput(
        subject: _subjectController.text.trim(),
        weeklyHours: hours.isEmpty ? null : hours,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une matière'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _subjectController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Matière',
                hintText: 'Ex. Architecture Logicielle',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 2) {
                  return 'Saisissez au moins 2 caractères.';
                }
                if (text.length > 100) {
                  return '100 caractères maximum.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hoursController,
              decoration: const InputDecoration(
                labelText: 'Volume horaire (optionnel)',
                hintText: 'Ex. 3h/semaine',
              ),
              validator: (value) {
                if ((value?.trim().length ?? 0) > 50) {
                  return '50 caractères maximum.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Ajouter')),
      ],
    );
  }
}

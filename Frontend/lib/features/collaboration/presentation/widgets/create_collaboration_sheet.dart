import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';

class CreateCollaborationSheet extends ConsumerStatefulWidget {
  const CreateCollaborationSheet({super.key});

  @override
  ConsumerState<CreateCollaborationSheet> createState() =>
      _CreateCollaborationSheetState();
}

class _CreateCollaborationSheetState
    extends ConsumerState<CreateCollaborationSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.translate('share_resource')),
              Tab(text: l10n.translate('create_study_session')),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildShareResourceForm(context),
                _buildCreateSessionForm(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareResourceForm(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.translate('share_resource'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            decoration: InputDecoration(
              labelText: l10n.translate('resource_title'),
              hintText: 'ex: Exercices corrigés - Chapitre 3',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: l10n.translate('resource_type'),
              prefixIcon: const Icon(Icons.category_rounded),
            ),
            items: ['PDF', 'Lien', 'Image', 'Vidéo', 'Code', 'Autre']
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Fichier / Lien',
              hintText: type == 'Lien'
                  ? 'https://...'
                  : 'Sélectionner un fichier',
              prefixIcon: const Icon(Icons.attach_file_rounded),
            ),
            readOnly: true,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          AppButton(
            text: l10n.translate('share'),
            onPressed: () {
              Navigator.pop(context);
              context.showSuccessToast(l10n.translate('resource_shared'));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreateSessionForm(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.translate('create_study_session'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            decoration: InputDecoration(
              labelText: l10n.translate('session_topic'),
              hintText: 'ex: Révision examen final',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      prefixIcon: const Icon(Icons.calendar_today_rounded),
                    ),
                    child: Text('Demain'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: 18, minute: 0),
                    );
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Heure',
                      prefixIcon: const Icon(Icons.access_time_rounded),
                    ),
                    child: Text('18:00'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Durée',
              hintText: 'ex: 2h',
              prefixIcon: const Icon(Icons.timer_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Participants max',
              hintText: 'ex: 8',
              prefixIcon: const Icon(Icons.people_rounded),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          AppButton(
            text: l10n.translate('create'),
            onPressed: () {
              Navigator.pop(context);
              context.showSuccessToast(l10n.translate('session_created'));
            },
          ),
        ],
      ),
    );
  }

  String get type => 'PDF';
}

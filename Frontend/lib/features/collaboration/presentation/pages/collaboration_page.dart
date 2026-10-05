import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

class CollaborationPage extends ConsumerWidget {
  const CollaborationPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('collaboration')),
          bottom: TabBar(
            tabs: [
              Tab(text: context.tr('shared_resources')),
              Tab(text: context.tr('study_sessions')),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showCreateDialog(context),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildResourcesTab(context),
            _buildStudySessionsTab(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResourcesTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final resources = [
      {'title': 'Exercices corrigés - POO', 'type': 'PDF', 'author': 'Marie D.', 'date': DateTime.now().subtract(const Duration(days: 2)), 'group': 'L3 Info - Groupe A'},
      {'title': 'Résumé cours Base de données', 'type': 'Lien', 'author': 'Thomas L.', 'date': DateTime.now().subtract(const Duration(days: 5)), 'group': 'L3 Info - Groupe A'},
      {'title': 'Algorithmes de tri - Implémentation', 'type': 'Code', 'author': 'Sarah K.', 'date': DateTime.now().subtract(const Duration(days: 8)), 'group': 'L3 Info - Groupe B'},
    ];
    
    if (resources.isEmpty) {
      return _buildEmptyState(context, 'resources');
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final resource = resources[index];
        final type = resource['type'] as String;
        
        IconData typeIcon;
        Color typeColor;
        
        switch (type) {
          case 'PDF':
            typeIcon = Icons.picture_as_pdf_rounded;
            typeColor = Colors.red;
            break;
          case 'Lien':
            typeIcon = Icons.link_rounded;
            typeColor = colorScheme.primary;
            break;
          case 'Code':
            typeIcon = Icons.code_rounded;
            typeColor = colorScheme.tertiary;
            break;
          default:
            typeIcon = Icons.insert_drive_file_rounded;
            typeColor = colorScheme.onSurfaceVariant;
        }
        
        return AppCard(
          onTap: () {},
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            resource['title'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            type,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Partagé par ${resource['author']}',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          (resource['date'] as DateTime).formatDate(),
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.flag_rounded, size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          resource['group'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStudySessionsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final sessions = [
      {'topic': 'Révision examen POO', 'date': DateTime.now().add(const Duration(days: 2)), 'time': '18:00 - 20:00', 'participants': 5, 'maxParticipants': 8, 'creator': 'Marie D.'},
      {'topic': 'Exercices Base de données', 'date': DateTime.now().add(const Duration(days: 5)), 'time': '14:00 - 16:00', 'participants': 3, 'maxParticipants': 6, 'creator': 'Thomas L.'},
    ];
    
    if (sessions.isEmpty) {
      return _buildEmptyState(context, 'sessions');
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final date = session['date'] as DateTime;
        final participants = session['participants'] as int;
        final maxParticipants = session['maxParticipants'] as int;
        
        return AppCard(
          onTap: () {},
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_rounded,
                      color: colorScheme.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session['topic'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Organisée par ${session['creator']}',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: participants >= maxParticipants
                          ? colorScheme.error.withValues(alpha: 0.1)
                          : colorScheme.tertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      '$participants/$maxParticipants',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: participants >= maxParticipants ? colorScheme.error : colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    date.formatDate(),
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    session['time'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: participants / maxParticipants,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  participants >= maxParticipants ? colorScheme.error : colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: Text(context.tr('comments')),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    text: participants >= maxParticipants ? 'Complet' : 'Rejoindre',
                    onPressed: participants >= maxParticipants ? null : () {},
                    isFullWidth: false,
                    variant: participants >= maxParticipants ? AppButtonVariant.text : AppButtonVariant.outlined,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context, String type) {
    String message;
    IconData icon;
    
    if (type == 'resources') {
      message = context.tr('no_resources');
      icon = Icons.folder_open_outlined;
    } else {
      message = context.tr('no_study_sessions');
      icon = Icons.event_outlined;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'resources'
                  ? 'Partagez vos premiers documents avec le groupe'
                  : 'Organisez une session de révision avec vos camarades',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: type == 'resources' ? context.tr('share_resource') : context.tr('create_study_session'),
              onPressed: () => _showCreateDialog(context),
              isFullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateCollaborationSheet(),
    );
  }
}

class _CreateCollaborationSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateCollaborationSheet> createState() => _CreateCollaborationSheetState();
}

class _CreateCollaborationSheetState extends ConsumerState<_CreateCollaborationSheet>
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
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
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
              hintText: type == 'Lien' ? 'https://...' : 'Sélectionner un fichier',
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.translate('resource_shared'))),
              );
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
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
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
                    final date = await showDatePicker(
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
                    final time = await showTimePicker(
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.translate('session_created'))),
              );
            },
          ),
        ],
      ),
    );
  }
  
  String get type => 'PDF';
}
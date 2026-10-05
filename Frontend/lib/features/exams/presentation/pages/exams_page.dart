import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

class ExamsPage extends ConsumerWidget {
  const ExamsPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('my_exams')),
          bottom: TabBar(
            tabs: [
              Tab(text: context.tr('upcoming')),
              Tab(text: context.tr('in_progress')),
              Tab(text: context.tr('completed')),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showCreateExamDialog(context),
              tooltip: context.tr('create_exam'),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildExamList(context, 'upcoming'),
            _buildExamList(context, 'in_progress'),
            _buildExamList(context, 'completed'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExamList(BuildContext context, String filter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final exams = filter == 'upcoming'
        ? [
            {'title': 'Examen final - Programmation OO', 'date': DateTime.now().add(const Duration(days: 3)), 'duration': const Duration(minutes: 120), 'questions': 20, 'status': 'À venir', 'isSimulation': false},
            {'title': 'Simulation - Base de données', 'date': DateTime.now().add(const Duration(days: 7)), 'duration': const Duration(minutes: 90), 'questions': 15, 'status': 'Simulation', 'isSimulation': true},
          ]
        : filter == 'in_progress'
        ? [
            {'title': 'Quiz hebdomadaire - Algo', 'date': DateTime.now(), 'duration': const Duration(minutes: 30), 'questions': 10, 'status': 'En cours', 'isSimulation': false},
          ]
        : [
            {'title': 'Examen mi-session - POO', 'date': DateTime.now().subtract(const Duration(days: 5)), 'duration': const Duration(minutes: 120), 'questions': 25, 'score': 84, 'status': 'Terminé', 'isSimulation': false},
            {'title': 'Simulation - Structures de données', 'date': DateTime.now().subtract(const Duration(days: 12)), 'duration': const Duration(minutes: 90), 'questions': 20, 'score': 92, 'status': 'Terminé', 'isSimulation': true},
          ];
    
    if (exams.isEmpty) {
      return _buildEmptyState(context, filter);
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final exam = exams[index];
        return AppExamCard(
          title: exam['title'] as String,
          date: exam['date'] as DateTime?,
          duration: exam['duration'] as Duration?,
          questionCount: exam['questions'] as int?,
          status: exam['status'] as String,
          statusColor: exam['isSimulation'] == true ? colorScheme.tertiary : colorScheme.primary,
          score: exam['score'] as int?,
          isSimulation: exam['isSimulation'] == true,
          onTap: () {},
          onStart: filter == 'upcoming' || filter == 'in_progress'
              ? () => _startExam(context, exam['title'] as String)
              : null,
        );
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context, String filter) {
    String message;
    IconData icon;
    
    switch (filter) {
      case 'upcoming':
        message = 'Aucun examen à venir';
        icon = Icons.event_available_outlined;
        break;
      case 'in_progress':
        message = 'Aucun examen en cours';
        icon = Icons.hourglass_empty_outlined;
        break;
      default:
        message = 'Aucun examen terminé';
        icon = Icons.check_circle_outline;
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
            if (filter == 'upcoming') ...[
              const SizedBox(height: 24),
              AppButton(
                text: context.tr('create_exam'),
                onPressed: () => _showCreateExamDialog(context),
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showCreateExamDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateExamSheet(),
    );
  }
  
  void _startExam(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Démarrer l\'examen'),
        content: Text('Voulez-vous commencer "$title" ?\n\nLe mode anti-fraude sera activé (plein écran, verrouillage du focus, blocage copier-coller).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Examen démarré: $title')),
              );
            },
            child: Text('Commencer'),
          ),
        ],
      ),
    );
  }
}

class _CreateExamSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateExamSheet> createState() => _CreateExamSheetState();
}

class _CreateExamSheetState extends ConsumerState<_CreateExamSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isSimulation = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
          Text(
            context.tr('create_exam'),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: context.tr('exam_title'),
                    hintText: 'ex: Examen final - Programmation',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('required_field');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  decoration: InputDecoration(
                    labelText: context.tr('exam_duration'),
                    hintText: 'Durée en minutes (ex: 120)',
                    prefixIcon: const Icon(Icons.access_time_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('required_field');
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Durée invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(context.tr('simulation_exam')),
                  subtitle: Text(context.tr('practice_mode')),
                  value: _isSimulation,
                  onChanged: (value) => setState(() => _isSimulation = value),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: context.tr('cancel'),
                        onPressed: () => Navigator.pop(context),
                        variant: AppButtonVariant.outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: _isSimulation ? context.tr('generate_exam') : context.tr('create'),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.tr(_isSimulation ? 'exam_generated' : 'exam_created'))),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
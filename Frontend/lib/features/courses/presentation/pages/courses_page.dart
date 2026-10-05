import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('my_courses')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateCourseDialog(context),
            tooltip: context.tr('create_course'),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
            tooltip: context.tr('search'),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }
  
  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterChips(context),
                const SizedBox(height: 16),
                _buildCourseList(context),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterChips(BuildContext context) {
    final filters = [
      context.tr('all'),
      context.tr('in_progress'),
      context.tr('completed'),
      context.tr('drafts'),
      context.tr('archived'),
    ];
    
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return FilterChip(
            label: Text(filters[index]),
            selected: isSelected,
            onSelected: (_) {},
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCourseList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final courses = [
      {'title': 'Programmation orientée objet', 'teacher': 'Prof. Martin', 'progress': 0.65, 'lessons': 12, 'status': 'En cours'},
      {'title': 'Base de données relationnelles', 'teacher': 'Prof. Dubois', 'progress': 0.30, 'lessons': 8, 'status': 'En cours'},
      {'title': 'Algorithmique et structures de données', 'teacher': 'Prof. Bernard', 'progress': 1.0, 'lessons': 15, 'status': 'Terminé'},
      {'title': 'Développement Web avec Flutter', 'teacher': 'Prof. Petit', 'progress': 0.0, 'lessons': 10, 'status': 'Non commencé'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr('my_courses')} (${courses.length})',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final course = courses[index];
            final progress = course['progress'] as double;
            final isCompleted = progress >= 1.0;
            
            return AppCourseCard(
              title: course['title'] as String,
              subtitle: '${course['teacher']} • ${course['lessons']} leçons',
              progress: '${(progress * 100).round()}% terminé',
              progressValue: progress,
              status: course['status'] as String,
              statusColor: isCompleted ? colorScheme.tertiary : colorScheme.primary,
              onTap: () {},
              tags: [
                Chip(
                  label: Text(isCompleted ? 'Terminé' : 'En cours'),
                  backgroundColor: isCompleted
                      ? colorScheme.tertiary.withValues(alpha: 0.1)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isCompleted ? colorScheme.tertiary : colorScheme.primary,
                    fontSize: 11,
                  ),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            );
          },
        ),
        if (courses.isEmpty) _buildEmptyState(context),
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('no_courses'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par créer ou rejoindre un cours',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: context.tr('create_course'),
              onPressed: () => _showCreateCourseDialog(context),
              isFullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCreateCourseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateCourseSheet(),
    );
  }
}

class _CreateCourseSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateCourseSheet> createState() => _CreateCourseSheetState();
}

class _CreateCourseSheetState extends ConsumerState<_CreateCourseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
            context.tr('create_course'),
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
                    labelText: context.tr('course_title'),
                    hintText: 'ex: Introduction à la programmation',
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
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: context.tr('course_description'),
                    hintText: 'Description du cours...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 500,
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
                        text: context.tr('create'),
                        onPressed: _createCourse,
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
  
  void _createCourse() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('course_created'))),
      );
    }
  }
}
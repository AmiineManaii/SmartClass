import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/courses_provider.dart';
import '../../application/providers/course_generation_job_provider.dart';
import '../../domain/entities/generated_course.dart';
import '../widgets/course_card.dart';
import '../widgets/error_state.dart';
import '../widgets/generated_course_card.dart';
import '../widgets/generated_list.dart';
import '../widgets/running_job_banner.dart';
import '../widgets/staggered_list_item.dart';
import '../widgets/subject_detail_card.dart';

/// "Cours & Ressources" pour le professeur.
///
/// - Section "Mes matières" : cartes matières extraites des classes du prof.
///   Cliquer sur une matière filtre les cours de cette matière uniquement.
/// - FAB "+" : choisir classe -> choisir matière (matières du prof pr cette
///   classe) -> creation avec IA.
/// - "Cours generes" : liste depuis myGeneratedCoursesProvider, tap -> lecteur.
/// Les etudiants voient leurs cours publies comme avant.
class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});

  static const _filters = ['all', 'in_progress', 'drafts'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authStateProvider).valueOrNull?.role?.toLowerCase();
    final isTeacher = role == 'teacher' || role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTeacher
              ? context.tr('nav_courses_resources')
              : context.tr('my_courses'),
        ),
        actions: [
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => context.push('/courses/ai-create'),
              tooltip: context.tr('create_course'),
            ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              context.showInfoToast(context.tr('feature_coming_soon'));
            },
            tooltip: context.tr('search'),
          ),
        ],
      ),
      body: _buildBody(context, ref, isTeacher),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, bool isTeacher) {
    final selectedFilter = ref.watch(courseFilterProvider);
    final selectedSubject = ref.watch(selectedSubjectProvider);
    final theme = Theme.of(context);
    final activeFilters = isTeacher ? _filters : const ['all', 'in_progress'];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isTeacher) ...[
                  _buildSubjectsSection(context, ref, selectedSubject),
                  const SizedBox(height: 24),
                  _buildTeacherGeneratedCourses(context, ref, selectedSubject),
                ] else ...[
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: activeFilters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = activeFilters[index];
                        final isSelected = filter == selectedFilter;
                        return FilterChip(
                          label: Text(context.tr(filter)),
                          selected: isSelected,
                          onSelected: (_) =>
                              ref.read(courseFilterProvider.notifier).state =
                                  filter,
                          selectedColor: theme.colorScheme.primaryContainer,
                          labelStyle: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCourseList(context, ref, selectedSubject),
                  const SizedBox(height: 24),
                  _buildGeneratedSection(context, ref),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Mes matières — cartes matières du professeur. Cliquer filtre les cours.
  Widget _buildSubjectsSection(
      BuildContext context, WidgetRef ref, String? selectedSubject) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('ai_my_subjects'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(selectedSubjectProvider.notifier).state = null,
              child: Text(
                context.tr('reset_filter'),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, _) {
            final coursesAsync = ref.watch(myCoursesProvider);
            final generatedAsync = ref.watch(myGeneratedCoursesProvider);
            return coursesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (courses) {
                final generated =
                    generatedAsync.valueOrNull ?? const <GeneratedCourse>[];
                final subjects = <String>{};
                final classNamesBySubject = <String, List<String>>{};
                for (final c in courses) {
                  for (final s in c.subjects) {
                    if (s.isEmpty) continue;
                    subjects.add(s);
                    final names = classNamesBySubject.putIfAbsent(
                      s,
                      () => <String>[],
                    );
                    if (!names.contains(c.name)) names.add(c.name);
                  }
                }
                if (subjects.isEmpty) return const SizedBox.shrink();
                final list = subjects.toList()..sort();
                return SizedBox(
                  height: 124,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final subject = list[index];
                      final courseCount = generated
                          .where((g) => g.subject == subject)
                          .length;
                      final classNames =
                          classNamesBySubject[subject] ?? const <String>[];
                      final isSelected = selectedSubject == subject;
                      return SubjectDetailCard(
                        index: index,
                        subject: subject,
                        courseCount: courseCount,
                        classNames: classNames,
                        isSelected: isSelected,
                        width: 240,
                        onTap: () => ref
                            .read(selectedSubjectProvider.notifier)
                            .state = isSelected ? null : subject,
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// Section dédiée pour l'enseignant : affiche ses cours créés/générés avec l'IA.
  /// Si une matière est sélectionnée, seuls les cours de cette matière sont affichés.
  Widget _buildTeacherGeneratedCourses(
      BuildContext context, WidgetRef ref, String? selectedSubject) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mineAsync = ref.watch(myGeneratedCoursesProvider);
    final job = ref.watch(courseGenerationJobProvider);
    final jobBanner = job.status == GenerationJobStatus.running
        ? Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RunningJobBanner(job: job),
          )
        : const SizedBox.shrink();

    return mineAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: SmartLoader.medium(message: 'Chargement des cours...'),
        ),
      ),
      error: (_, _) => jobBanner,
      data: (courses) {
        var filtered = courses;
        if (selectedSubject != null && selectedSubject.isNotEmpty) {
          filtered = courses
              .where((c) =>
                  c.subject != null &&
                  c.subject!.toLowerCase() == selectedSubject.toLowerCase())
              .toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            jobBanner,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${context.tr('my_courses')} (${filtered.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/courses/ai-create'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    context.tr('create_action'),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedSubject != null
                          ? 'Aucun cours généré pour $selectedSubject'
                          : 'Aucun cours généré pour le moment',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Créez un cours complet en quelques secondes avec l\'IA.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.push('/courses/ai-create'),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Créer avec l\'IA'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => StaggeredListItem(
                  index: index,
                  child: GeneratedCourseCard(
                    course: filtered[index],
                    showValidate: true,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCourseList(BuildContext context, WidgetRef ref,
      String? selectedSubject) {
    final theme = Theme.of(context);
    final coursesAsync = ref.watch(filteredCoursesProvider);

    return coursesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: SmartLoader.medium(message: 'Chargement de vos cours...'),
        ),
      ),
      error: (error, _) =>
          ErrorState(onRetry: () => ref.invalidate(myCoursesProvider)),
      data: (courses) {
        var filtered = courses;
        if (selectedSubject != null && selectedSubject.isNotEmpty) {
          filtered = courses
              .where((c) => c.subjects.contains(selectedSubject))
              .toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${context.tr('my_courses')} (${filtered.length})',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              _buildEmptyState(context)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    CourseCard(course: filtered[index], index: index),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('no_class_title'),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('no_class_message'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section "Cours générés" (enseignants : brouillons à valider ; étudiants :
/// cours publiés à lire). Tapping ouvre le lecteur.
Widget _buildGeneratedSection(BuildContext context, WidgetRef ref) {
  final role = ref.watch(authStateProvider).valueOrNull?.role;
  final isTeacher = role == 'teacher' || role == 'admin';
  final theme = Theme.of(context);

  if (isTeacher) {
    final mineAsync = ref.watch(myGeneratedCoursesProvider);
    final job = ref.watch(courseGenerationJobProvider);
    final jobBanner = job.status == GenerationJobStatus.running
        ? Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RunningJobBanner(job: job),
          )
        : const SizedBox.shrink();
    return mineAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: SmartLoader.medium(message: 'Chargement des cours...'),
        ),
      ),
      error: (_, _) => jobBanner,
      data: (courses) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          jobBanner,
          GeneratedList(
            titleKey: 'generated_courses',
            emptyKey: 'no_generated_courses',
            courses: courses,
            showValidate: true,
          ),
        ],
      ),
    );
  }

  final publishedAsync = ref.watch(publishedCoursesProvider);
  return publishedAsync.when(
    loading: () => const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: SmartLoader.medium(message: 'Chargement des cours publiés...'),
      ),
    ),
    error: (_, _) => const SizedBox.shrink(),
    data: (courses) {
      if (courses.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('published_courses'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('no_published_courses'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }
      return GeneratedList(
        titleKey: 'published_courses',
        emptyKey: 'no_published_courses',
        courses: courses,
        showValidate: false,
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
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

/// "Cours & Ressources" pour le professeur et l'étudiant.
class CoursesPage extends ConsumerStatefulWidget {
  const CoursesPage({super.key});

  @override
  ConsumerState<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends ConsumerState<CoursesPage> {
  static const _filters = ['all', 'in_progress', 'drafts'];
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authStateProvider).valueOrNull?.role?.toLowerCase();
    final isTeacher = role == 'teacher' || role == 'admin';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myCoursesProvider);
            ref.invalidate(myGeneratedCoursesProvider);
            ref.invalidate(publishedCoursesProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Hero Header Banner
              SliverToBoxAdapter(
                child: _buildHeroBanner(context, isTeacher),
              ),

              // 2. Real Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _buildSearchBar(context, isDark),
                ),
              ),

              // 3. Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildBody(context, ref, isTeacher),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 96),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isTeacher) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF122675), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF122675).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTeacher ? 'Cours & Ressources' : 'Mes Cours & Supports',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        isTeacher
                            ? 'Pédagogie & IA Générative'
                            : 'Apprentissage interactif',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isTeacher)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFA78BFA),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 11, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'IA +',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isTeacher
                ? 'Gérez vos supports de cours, organisez vos matières et créez des modules interactifs assistés par l\'IA.'
                : 'Consultez les cours de vos professeurs, téléchargez les supports et testez vos connaissances.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (isTeacher) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF122675),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(40),
              ),
              icon: const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: Color(0xFF6D28D9)),
              label: const Text(
                'Créer un cours avec l\'IA',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              onPressed: () => context.push('/courses/ai-create'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? const Color(0xFF122675)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 18,
            color: _searchQuery.isNotEmpty
                ? const Color(0xFF122675)
                : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: const InputDecoration(
                hintText: 'Rechercher un cours, matière ou module...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
              child: const Icon(Icons.cancel_rounded,
                  size: 16, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, bool isTeacher) {
    final selectedFilter = ref.watch(courseFilterProvider);
    final selectedSubject = ref.watch(selectedSubjectProvider);
    final theme = Theme.of(context);
    final activeFilters = isTeacher ? _filters : const ['all', 'in_progress'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isTeacher) ...[
          _buildSubjectsSection(context, ref, selectedSubject),
          const SizedBox(height: 20),
          _buildTeacherGeneratedCourses(
              context, ref, selectedSubject, _searchQuery),
        ] else ...[
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: activeFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = activeFilters[index];
                final isSelected = filter == selectedFilter;
                return ChoiceChip(
                  label: Text(context.tr(filter)),
                  selected: isSelected,
                  onSelected: (_) =>
                      ref.read(courseFilterProvider.notifier).state = filter,
                  selectedColor: const Color(0xFFEEF2FF),
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  labelStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF4338CA)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  side: isSelected
                      ? const BorderSide(color: Color(0xFFC7D2FE), width: 1)
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildCourseList(context, ref, selectedSubject, _searchQuery),
          const SizedBox(height: 24),
          _buildGeneratedSection(context, ref),
        ],
      ],
    );
  }

  /// Mes matières — cartes matières du professeur. Cliquer filtre les cours.
  Widget _buildSubjectsSection(
      BuildContext context, WidgetRef ref, String? selectedSubject) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  context.tr('ai_my_subjects'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                if (selectedSubject != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      selectedSubject,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (selectedSubject != null)
              TextButton(
                onPressed: () =>
                    ref.read(selectedSubjectProvider.notifier).state = null,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  context.tr('reset_filter'),
                  style: const TextStyle(
                    color: Color(0xFF4338CA),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
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
  Widget _buildTeacherGeneratedCourses(
    BuildContext context,
    WidgetRef ref,
    String? selectedSubject,
    String query,
  ) {
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
          filtered = filtered
              .where((c) =>
                  c.subject != null &&
                  c.subject!.toLowerCase() == selectedSubject.toLowerCase())
              .toList();
        }
        if (query.isNotEmpty) {
          final q = query.toLowerCase();
          filtered = filtered
              .where((c) =>
                  c.title.toLowerCase().contains(q) ||
                  (c.subject?.toLowerCase().contains(q) ?? false) ||
                  (c.content?.toLowerCase().contains(q) ?? false) ||
                  c.authorName.toLowerCase().contains(q))
              .toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            jobBanner,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${context.tr('my_courses')} (${filtered.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => context.push('/courses/ai-create'),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    context.tr('create_action'),
                    style: const TextStyle(
                      color: Color(0xFF4338CA),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                      size: 40,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      query.isNotEmpty
                          ? 'Aucun cours trouvé pour "$query"'
                          : (selectedSubject != null
                              ? 'Aucun cours généré pour $selectedSubject'
                              : 'Aucun cours généré pour le moment'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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
                        backgroundColor: const Color(0xFF122675),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

  Widget _buildCourseList(
    BuildContext context,
    WidgetRef ref,
    String? selectedSubject,
    String query,
  ) {
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
        if (query.isNotEmpty) {
          final q = query.toLowerCase();
          filtered = filtered
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.subjects.any((s) => s.toLowerCase().contains(q)))
              .toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${context.tr('my_courses')} (${filtered.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
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
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('no_class_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
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

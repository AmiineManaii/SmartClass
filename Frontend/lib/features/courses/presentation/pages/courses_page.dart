import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/courses_provider.dart';
import '../../application/providers/course_generation_job_provider.dart';
import '../../domain/entities/course_entry.dart';
import '../../domain/entities/generated_course.dart';

/// "Mes cours" — real classes of the caller (`GET /api/v1/groups/mine`).
/// No mock data: empty/error states are honest, progress/leçons are not
/// shown until the backend course module (📋 planned) exists.
class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});

  static const _filters = ['all', 'in_progress', 'drafts'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authStateProvider).valueOrNull?.role?.toLowerCase();
    final isTeacher = role == 'teacher' || role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTeacher ? context.tr('nav_courses_resources') : context.tr('my_courses')),
        actions: [
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showCreateCourseDialog(context),
              tooltip: context.tr('create_course'),
            ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // Server-side course search needs the courses module
              // (📋 planned): honest "coming soon" until then.
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
                        selectedColor:
                            theme.colorScheme.primaryContainer,
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
                _buildCourseList(context, ref),
                const SizedBox(height: 24),
                _buildGeneratedSection(context, ref),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Generated-course library below the class list.
  ///
  /// Teachers read their own drafts here and validate them (PUBLISHED) so
  /// students can read them; students (and other roles) read the
  /// validated courses and open them in the reader.
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
              child: _RunningJobBanner(job: job),
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
            _GeneratedList(
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
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
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
        return _GeneratedList(
          titleKey: 'published_courses',
          emptyKey: 'no_published_courses',
          courses: courses,
          showValidate: false,
        );
      },
    );
  }

  Widget _buildCourseList(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coursesAsync = ref.watch(filteredCoursesProvider);

    return coursesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: SmartLoader.medium(message: 'Chargement de vos cours...'),
        ),
      ),
      error: (error, _) => _ErrorState(
        onRetry: () => ref.invalidate(myCoursesProvider),
      ),
      data: (courses) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.tr('my_courses')} (${courses.length})',
            style:
                theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (courses.isEmpty)
            _buildEmptyState(context)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _CourseCard(course: courses[index]),
            ),
        ],
      ),
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

  void _showCreateCourseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateCourseSheet(),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseEntry course;

  const _CourseCard({required this.course});

  String _levelLabel(BuildContext context) {
    final key = switch (course.level) {
      'LICENCE' => 'level_licence',
      'MASTER' => 'level_master',
      'DOCTORAT' => 'level_doctorat',
      _ => '',
    };
    return key.isEmpty ? course.level : context.tr(key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final scope = (course.department == null || course.department!.isEmpty)
        ? _levelLabel(context)
        : course.department!;
    final subtitle = [
      scope,
      context.tr('courses_students_count',
          args: {'count': '${course.memberCount}'}),
      context.tr('courses_teachers_count',
          args: {'count': '${course.teacherCount}'}),
    ].join(' • ');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.primaryContainer.withValues(alpha: 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.menu_book_rounded,
                size: 48,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Chip(
                      label: Text(context.tr(course.isPublished
                          ? 'in_progress'
                          : 'drafts')),
                      backgroundColor: (course.isPublished
                              ? colorScheme.primary
                              : colorScheme.tertiary)
                          .withValues(alpha: 0.1),
                      labelStyle: theme.textTheme.labelSmall?.copyWith(
                        color: course.isPublished
                            ? colorScheme.primary
                            : colorScheme.tertiary,
                      ),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    if (course.myRole != 'STUDENT')
                      Chip(
                        label: Text(context.tr(course.myRole == 'REFERENT'
                            ? 'role_referent'
                            : 'role_teacher')),
                        backgroundColor:
                            colorScheme.secondary.withValues(alpha: 0.1),
                        labelStyle: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.secondary,
                        ),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  course.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Generated-course list (drafts to validate for teachers, published
/// courses to read for students). Tapping a card opens the reader.
class _GeneratedList extends StatelessWidget {
  final String titleKey;
  final String emptyKey;
  final List<GeneratedCourse> courses;
  final bool showValidate;

  const _GeneratedList({
    required this.titleKey,
    required this.emptyKey,
    required this.courses,
    required this.showValidate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr(titleKey)} (${courses.length})',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (courses.isEmpty)
          Text(
            context.tr(emptyKey),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _GeneratedCourseCard(
              course: courses[index],
              showValidate: showValidate,
            ),
          ),
      ],
    );
  }
}

class _GeneratedCourseCard extends ConsumerWidget {
  final GeneratedCourse course;
  final bool showValidate;

  const _GeneratedCourseCard({
    required this.course,
    required this.showValidate,
  });

  void _showFailure(BuildContext context, Object error) {
    final Failure failure = error is ApiException
        ? apiExceptionToFailure(error)
        : error as Failure;
    final l10n = failureL10n(failure);
    context.showErrorToast(context.tr(l10n.key, args: l10n.args));
  }

  Future<void> _validate(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(generatedCoursesDataSourceProvider).publish(course.id);
      ref
        ..invalidate(myGeneratedCoursesProvider)
        ..invalidate(publishedCoursesProvider);
      if (!context.mounted) return;
      context.showSuccessToast(context.tr('published'));
    } catch (e) {
      if (!context.mounted) return;
      _showFailure(context, e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete')),
        content: Text(context.tr('delete_course_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(generatedCoursesDataSourceProvider).deleteCourse(course.id);
      ref
        ..invalidate(myGeneratedCoursesProvider)
        ..invalidate(publishedCoursesProvider);
      if (!context.mounted) return;
      context.showInfoToast(context.tr('course_deleted'));
    } catch (e) {
      if (!context.mounted) return;
      _showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = [
      if (course.subject != null && course.subject!.isNotEmpty)
        course.subject!,
      course.authorName,
    ].join(' • ');

    return InkWell(
      onTap: () => context.push('/courses/${course.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              offset: const Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(context.tr(
                      course.isPublished ? 'published' : 'draft')),
                  backgroundColor: (course.isPublished
                          ? colorScheme.primary
                          : colorScheme.tertiary)
                      .withValues(alpha: 0.1),
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: course.isPublished
                        ? colorScheme.primary
                        : colorScheme.tertiary,
                  ),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const Spacer(),
                if (showValidate && course.isDraft)
                  TextButton.icon(
                    onPressed: () => _validate(context, ref),
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: Text(context.tr('validate_course')),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (showValidate)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 20, color: colorScheme.error),
                    tooltip: context.tr('delete'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _delete(context, ref),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              course.title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Slim banner shown in "Mes cours" while a background generation runs
/// (started from the creator page, which the teacher may have left).
/// The finished course lands in the drafts below automatically.
class _RunningJobBanner extends ConsumerWidget {
  final GenerationJobState job;

  const _RunningJobBanner({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final minutes = job.elapsedSec ~/ 60;
    final seconds = (job.elapsedSec % 60).toString().padLeft(2, '0');
    final tokens = job.chars ~/ 4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SmartLoader.small(
            customSize: 18,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${context.tr('generation_running')} $tokens tokens • $minutes:$seconds',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(courseGenerationJobProvider.notifier).cancel(),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            child: Text(context.tr('cancel')),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('server_error'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: context.tr('retry'),
              onPressed: onRetry,
              isFullWidth: false,
              variant: AppButtonVariant.outlined,
            ),
          ],
        ),
      ),
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
          Align(
            alignment: Alignment.center,
            child: Text(
              context.tr('create_course'),
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
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
                    hintText: context.tr('course_title'),
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
      context.showSuccessToast(context.tr('course_created'));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/course_section_build_provider.dart';
import '../../application/providers/courses_provider.dart';
import '../../domain/entities/course_outline.dart';
import '../../domain/entities/generated_course.dart';
import '../widgets/ai_section_refine_dialog.dart';
import '../widgets/course_image_search_dialog.dart';
import '../widgets/course_reader_actions.dart';
import '../widgets/course_section_card.dart';
import '../widgets/course_study_flashcards_tab.dart';
import '../widgets/course_study_summary_tab.dart';
import '../widgets/course_study_tutor_tab.dart';
import '../widgets/markdown_course_view.dart';

part '../widgets/course_reader_meta_strip_part.dart';
part '../widgets/course_reader_outline_part.dart';
part '../widgets/course_reader_section_build_part.dart';
part '../widgets/course_reader_sommaire_part.dart';

/// Corps du lecteur de cours : contenu, sections (enseignant) et espace
/// d'étude de l'étudiant (Résumé / Flashcards / Tuteur IA).
///
/// Séparé de `CourseReaderPage` et découpé en `part` pour respecter la
/// limite de taille de fichier (PROJECT_CONTEXT §7).
class CourseReaderBody extends ConsumerStatefulWidget {
  final GeneratedCourse course;
  final String courseId;
  final VoidCallback onCopy;

  const CourseReaderBody({
    super.key,
    required this.course,
    required this.courseId,
    required this.onCopy,
  });

  @override
  ConsumerState<CourseReaderBody> createState() => _CourseReaderBodyState();
}

class _CourseReaderBodyState extends ConsumerState<CourseReaderBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(courseSectionBuildProvider(widget.courseId).notifier).load();
      }
    });
  }

  bool _canModerate(String? role, String? userId) {
    if (role == 'admin') return true;
    return role == 'teacher' &&
        userId != null &&
        userId == widget.course.authorId;
  }

  void _showCourseFailure(BuildContext context, Object error) {
    final Failure failure = error is ApiException
        ? apiExceptionToFailure(error)
        : error as Failure;
    final l10n = failureL10n(failure);
    context.showErrorToast(context.tr(l10n.key, args: l10n.args));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    final role = auth?.role?.toLowerCase();
    final isStudent = role == 'student';
    final canModerate = _canModerate(role, auth?.userId);

    final content = widget.course.content ?? '';
    final words = content
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final readingMin = (words / 200).ceil().clamp(1, 180);

    return DefaultTabController(
      length: isStudent ? 4 : 1,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Meta strip : auteur, statut (Brouillon/Publié), durée de lecture
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _CourseMetaStrip(
                course: widget.course,
                readingMin: readingMin,
              ),
            ),
            const Divider(height: 1),
            if (isStudent) const _StudyTabBar(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildContentTab(context, content, canModerate),
                  if (isStudent) ...[
                    CourseStudySummaryTab(courseId: widget.courseId),
                    CourseStudyFlashcardsTab(courseId: widget.courseId),
                    CourseStudyTutorTab(courseId: widget.courseId),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reading tab: Markdown body, outline preview and teacher section build.
  Widget _buildContentTab(
    BuildContext context,
    String content,
    bool canModerate,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sommaire (extraits des titres Markdown)
          if (content.contains('#')) _SommaireChip(content: content),

          if (widget.course.content?.isNotEmpty == true)
            MarkdownCourseView(data: widget.course.content!),

          // Afficher le plan détaillé pour les brouillons avec outline
          if (widget.course.isDraft && widget.course.outline != null)
            _OutlinePreview(
              outline: widget.course.outline!,
              courseId: widget.courseId,
            ),

          const SizedBox(height: 24),

          // Construction par sections (brouillons uniquement)
          if (widget.course.isDraft)
            _SectionBuildPanel(courseId: widget.courseId),

          const SizedBox(height: 24),

          // Actions modérateur (enseignant auteur ou admin)
          if (canModerate)
            CourseReaderActions(
              course: widget.course,
              onRefine: () => _refineWithAi(context),
              onPublish: () => _publish(context),
              onUnpublish: () => _unpublish(context),
              onDelete: () => _delete(context),
            ),
        ],
      ),
    );
  }

  Future<void> _refineWithAi(BuildContext context) async {
    final fullContent = widget.course.content ?? '';
    await AiSectionRefineDialog.show(
      context: context,
      fullCourseContent: fullContent,
      level: widget.course.level,
      difficulty: widget.course.difficulty,
      onApply: (oldText, newText) async {
        String updated;
        if (fullContent.contains(oldText)) {
          updated = fullContent.replaceFirst(oldText, newText);
        } else {
          updated = fullContent.replaceAll(oldText.trim(), newText);
        }

        await ref
            .read(generatedCoursesDataSourceProvider)
            .updateCourse(id: widget.course.id, content: updated);
        ref
          ..invalidate(generatedCourseProvider(widget.course.id))
          ..invalidate(myGeneratedCoursesProvider)
          ..invalidate(publishedCoursesProvider);
      },
    );
  }

  Future<void> _publish(BuildContext context) async {
    final sectionState = ref.read(courseSectionBuildProvider(widget.course.id));
    if (sectionState.remainingToValidate > 0) {
      context.showWarningToast(
        context.tr(
          'ai_build_remaining',
          args: {'count': sectionState.remainingToValidate.toString()},
        ),
      );
      return;
    }

    try {
      await ref
          .read(generatedCoursesDataSourceProvider)
          .publish(widget.course.id);
      ref
        ..invalidate(generatedCourseProvider(widget.course.id))
        ..invalidate(myGeneratedCoursesProvider)
        ..invalidate(publishedCoursesProvider);
      if (!context.mounted) return;
      context.showSuccessToast(context.tr('published'));
    } catch (e) {
      if (!context.mounted) return;
      _showCourseFailure(context, e);
    }
  }

  Future<void> _unpublish(BuildContext context) async {
    try {
      await ref
          .read(generatedCoursesDataSourceProvider)
          .unpublish(widget.course.id);
      ref
        ..invalidate(generatedCourseProvider(widget.course.id))
        ..invalidate(myGeneratedCoursesProvider)
        ..invalidate(publishedCoursesProvider);
      if (!context.mounted) return;
      context.showInfoToast(context.tr('draft'));
    } catch (e) {
      if (!context.mounted) return;
      _showCourseFailure(context, e);
    }
  }

  Future<void> _delete(BuildContext context) async {
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
      await ref
          .read(generatedCoursesDataSourceProvider)
          .deleteCourse(widget.course.id);
      ref
        ..invalidate(myGeneratedCoursesProvider)
        ..invalidate(publishedCoursesProvider);
      if (!context.mounted) return;
      context.showInfoToast(context.tr('course_deleted'));
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      _showCourseFailure(context, e);
    }
  }
}

/// Student-only tabs: reading, AI summary, flashcards and course tutor.
class _StudyTabBar extends StatelessWidget {
  const _StudyTabBar();

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: [
        Tab(text: context.tr('course_study_tab_content')),
        Tab(text: context.tr('course_study_tab_summary')),
        Tab(text: context.tr('course_study_tab_flashcards')),
        Tab(text: context.tr('course_study_tab_tutor')),
      ],
    );
  }
}

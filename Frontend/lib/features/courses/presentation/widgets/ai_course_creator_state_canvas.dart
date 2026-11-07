part of '../pages/ai_course_creator_page.dart';

extension on _AiCourseCreatorPageState {
  Widget _buildStudioCanvas(
    BuildContext context, {
    required bool isDesktop,
    required GenerationJobState job,
    required String? displayed,
  }) {
    final running = job.status == GenerationJobStatus.running;
    final hasError = job.status == GenerationJobStatus.error;

    // 1. Finished result state (takes precedence once full course is generated)
    if (displayed != null) {
      if (_editing) {
        return _EditorCard(
          controller: _editController,
          onValidate: _validateEdit,
          onCancel: () => updateState(() => _editing = false),
        );
      }
      return _ResultCard(
        result: {...job.meta, 'content': displayed},
        validated: _validated,
        saving: job.saving,
        saved: job.courseId != null && displayed == job.savedContent,
        showDraftsLink: job.courseId != null,
        onReset: _resetResult,
        onEdit: () => _startEdit(displayed),
        onRefineWithAi: () {
          AiSectionRefineDialog.show(
            context: context,
            fullCourseContent: displayed,
            level: _level,
            difficulty: _difficulty,
            onApply: _onApplyRefinedSection,
          );
        },
        onSave: () => ref
            .read(courseGenerationJobProvider.notifier)
            .saveCurrentEdits(displayed),
        onViewDrafts: () => context.go('/courses'),
      );
    }

    // 2. Running progress state (generation in progress)
    if (running) {
      return _LiveProgressCard(
        elapsedSec: job.elapsedSec,
        liveChars: job.chars,
        preview: job.preview,
        phase: job.phase,
        onCancel: () => ref.read(courseGenerationJobProvider.notifier).cancel(),
      );
    }

    // 3. Error state - display error card with retry
    if (hasError) {
      return _GenerationErrorCard(
        error: job.error,
        onRetry: () => _generate(useOutline: _outline != null),
        onCancel: () => ref.read(courseGenerationJobProvider.notifier).reset(),
      );
    }

    // 4. Proposed Outline state (shown when outline is ready for review before full generation)
    if (_outline != null) {
      return CourseOutlineEditorCard(
        outline: _outline!,
        generating: running,
        onOutlineChanged: (o) {
          updateState(() => _outline = o);
          ref.read(coursePlanJobProvider.notifier).updateOutline(o);
        },
        onGenerateFullCourse: () => _generate(useOutline: true),
        onBuildSections: _buildSectionBySection,
        building: _savingPlan,
        onRegenerateOutline: _generateOutline,
        onCancel: () {
          updateState(() => _outline = null);
          ref.read(coursePlanJobProvider.notifier).reset();
        },
        outlineSaved: _outlineSaved,
      );
    }

    return const SizedBox.shrink();
  }


}


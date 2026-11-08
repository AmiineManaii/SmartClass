part of '../pages/ai_course_creator_page.dart';

extension on _AiCourseCreatorPageState {
  Widget _buildPage(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final job = ref.watch(courseGenerationJobProvider);
    final displayed = _displayedContent(job);
    final isDesktop = context.screenWidth >= 1024;
    final planJob = ref.watch(coursePlanJobProvider);

    // Synchronize outline from background job if page was re-entered
    if (_outline == null &&
        planJob.outline != null &&
        planJob.status == CoursePlanJobStatus.completed) {
      _outline = planJob.outline;
      _outlineSaved = planJob.outlineSaved;
      if (_topicController.text.trim().isEmpty && planJob.subject.isNotEmpty) {
        _topicController.text = planJob.subject;
      }
    }

    ref.listen<CoursePlanJobStatus>(
      coursePlanJobProvider.select((s) => s.status),
      (prev, next) {
        if (next == CoursePlanJobStatus.error) {
          final error = ref.read(coursePlanJobProvider).error;
          if (error != null) _showFailure(error);
        } else if (next == CoursePlanJobStatus.completed &&
            prev != CoursePlanJobStatus.completed) {
          final outline = ref.read(coursePlanJobProvider).outline;
          if (outline != null) {
            updateState(() {
              _outline = outline;
              _outlineSaved = ref.read(coursePlanJobProvider).outlineSaved;
            });
            context.showSuccessToast(
              context.tr('ai_toast_plan_ready'),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                );
              }
            });
          }
        }
      },
    );

    // Stream failure or manual-save failure surfaces here (the job has no
    // BuildContext of its own). Cancellation goes silently back to idle.
    ref.listen<GenerationJobStatus>(
      courseGenerationJobProvider.select((s) => s.status),
      (prev, next) {
        if (next == GenerationJobStatus.error) {
          final error = ref.read(courseGenerationJobProvider).error;
          if (error != null) _showFailure(error);
        } else if (next == GenerationJobStatus.done &&
            prev != GenerationJobStatus.done) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
              );
            }
          });
        }
      },
    );
    ref.listen<Object?>(
      courseGenerationJobProvider.select((s) => s.saveError),
      (_, error) {
        if (error != null) _showFailure(error);
      },
    );
    // A draft id appearing means the course just landed in "Mes cours"
    // (auto-save on completion, or manual save) — offer a shortcut there.
    ref.listen<String?>(courseGenerationJobProvider.select((s) => s.courseId), (
      previous,
      next,
    ) {
      if (next != null && next != previous) {
        context.showSuccessToast(
          context.tr('course_ready'),
          actionLabel: context.tr('view_drafts'),
          onAction: () => context.go('/courses'),
        );
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: isDesktop
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/courses');
                  }
                },
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SMARTCLASS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.secondary,
                      letterSpacing: 0.08,
                    ),
                  ),
                  Text(
                    context.tr('course_editor'),
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.menu_book_rounded),
                  tooltip: context.tr('my_courses'),
                  onPressed: () => context.go('/courses'),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/teacher_avatar.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, _) => Container(
                          color: colorScheme.primary,
                          child: Icon(
                            Icons.person,
                            color: colorScheme.onPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : (context.screenWidth >= 600 ? 24 : 16),
            vertical: isDesktop ? 24 : 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1380 : 720),
              child: isDesktop
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildWebStudioHeader(context),
                        if (displayed != null ||
                            _outline != null ||
                            job.status == GenerationJobStatus.running ||
                            planJob.status == CoursePlanJobStatus.running ||
                            job.status == GenerationJobStatus.error)
                          _buildStudioCanvas(
                            context,
                            isDesktop: true,
                            job: job,
                            displayed: displayed,
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Panel (flex: 52): Source & Content Prompt
                              Expanded(
                                flex: 52,
                                child: _buildSourceAndContentCard(
                                  context,
                                  isDesktop: true,
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Right Panel (flex: 48): Pedagogical Parameters & Launch
                              Expanded(
                                flex: 48,
                                child: _buildPedagogicalSettingsAndActionCard(
                                  context,
                                  isDesktop: true,
                                  job: job,
                                  planJob: planJob,
                                ),
                              ),
                            ],
                          ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSourceAndContentCard(context, isDesktop: false),
                        const SizedBox(height: 16),
                        _buildPedagogicalSettingsAndActionCard(
                          context,
                          isDesktop: false,
                          job: job,
                          planJob: planJob,
                        ),
                        if (displayed != null ||
                            _outline != null ||
                            job.status == GenerationJobStatus.running ||
                            planJob.status == CoursePlanJobStatus.running ||
                            job.status == GenerationJobStatus.error) ...[
                          const SizedBox(height: 20),
                          _buildStudioCanvas(
                            context,
                            isDesktop: false,
                            job: job,
                            displayed: displayed,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

}

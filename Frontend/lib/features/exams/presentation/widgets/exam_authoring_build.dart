part of '../pages/exam_authoring_page.dart';

extension _ExamAuthoringBuild on _ExamAuthoringPageState {
  Widget buildAuthoring(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('exam_authoring_title'))),
        body: const Center(child: SmartLoader()),
      );
    }
    if (_loadErrorKey != null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('exam_authoring_title'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.tr(_loadErrorKey!)),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _loadExisting,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDesktop = context.isDesktop;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr(
            _isEditing ? 'exam_edit_title' : 'exam_authoring_title',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SmartLoader.small()
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(context.tr('save')),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _detailsCard(context, theme),
                  if (_coverageReport != null ||
                      _knowledgeSources.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ExamCoverageAttributionCard(
                      sources: _knowledgeSources,
                      coverage: _coverageReport,
                      searchMode: _knowledgeSearchMode,
                      degradedReason: _knowledgeDegradedReason,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _scheduleCard(context, theme),
                  const SizedBox(height: 16),
                  _settingsCard(context, theme),
                  const SizedBox(height: 24),
                  _questionsHeader(context, theme),
                  const SizedBox(height: 12),
                  for (var index = 0; index < _questions.length; index += 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ExamQuestionEditorCard(
                        key: ValueKey<String>('$_editorRevision-$index'),
                        index: index,
                        draft: _questions[index],
                        onChanged: (draft) => _updateQuestion(index, draft),
                        onRemove: _questions.length > 1
                            ? () => _removeQuestion(index)
                            : null,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _applyState(_addQuestion),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(context.tr('exam_add_question')),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(
                            'exam_total_points',
                            args: <String, String>{'count': '$_totalPoints'},
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SmartLoader.small()
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          context.tr(
                            _isEditing ? 'exam_save_changes' : 'exam_create_save',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsCard(BuildContext context, ThemeData theme) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ExamTag(
                labelKey: examStatusKey(_status),
                tone: _status == ExamStatus.draft
                    ? ExamTagTone.warning
                    : ExamTagTone.primary,
              ),
              ExamTag(
                labelKey: examSourceKey(_source),
                icon: examSourceIcon(_source),
              ),
              if (_loadedModel != null)
                ExamTag(
                  labelKey: 'exam_ai_model_used',
                  tone: ExamTagTone.primary,
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: context.tr('exam_title'),
              hintText: context.tr('exam_title_hint'),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.tr('required_field')
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: context.tr('exam_description'),
              hintText: context.tr('exam_description_hint'),
              alignLabelWithHint: true,
            ),
          ),
          if (!_isEditing) ...[
            const SizedBox(height: 16),
            Text(
              context.tr('exam_source_title'),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _importing ? null : _pickImport,
                  icon: _importing
                      ? const SmartLoader.small()
                      : const Icon(Icons.upload_file_rounded, size: 18),
                  label: Text(context.tr('exam_import_action')),
                ),
                OutlinedButton.icon(
                  onPressed: _generating ? null : _generateAi,
                  icon: _generating
                      ? const SmartLoader.small()
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(context.tr('exam_ai_action')),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('exam_preview_only_hint'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_loadedModel != null) ...[
              const SizedBox(height: 6),
              Text(
                context.tr(
                  'exam_ai_model_name',
                  args: <String, String>{'model': _loadedModel!},
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _scheduleCard(BuildContext context, ThemeData theme) {
    final classes = ref.watch(examClassesProvider);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('exam_schedule_title'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          if (_isEditing)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.groups_rounded),
              title: Text(_className ?? context.tr('exam_class_unknown')),
              subtitle: Text(context.tr('exam_class_locked_hint')),
            )
          else
            classes.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: SmartLoader.small()),
              ),
              error: (error, _) => Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => ref.invalidate(examClassesProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('exam_classes_retry')),
                ),
              ),
              data: (options) {
                if (options.isEmpty) {
                  return Text(
                    context.tr('exam_classes_empty'),
                    style: theme.textTheme.bodySmall,
                  );
                }
                return DropdownButtonFormField<String>(
                  initialValue: _classGroupId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('exam_class_label'),
                  ),
                  items: [
                    for (final option in options)
                      DropdownMenuItem<String>(
                        value: option.id,
                        child: Text(
                          option.department == null
                              ? option.name
                              : '${option.name} · ${option.department}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => _applyState(() => _classGroupId = value),
                  validator: (value) => value == null
                      ? context.tr('exam_class_required')
                      : null,
                );
              },
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.tr('exam_duration_minutes'),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed < 1 || parsed > 600) {
                      return context.tr('exam_duration_invalid');
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  labelKey: 'exam_starts_at',
                  value: _startsAt,
                  onTap: () => _pickDate(start: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTile(
                  labelKey: 'exam_ends_at',
                  value: _endsAt,
                  onTap: () => _pickDate(start: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(BuildContext context, ThemeData theme) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('exam_settings_title'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'exam_settings_summary',
                    args: <String, String>{
                      'max': '${_settings.maxViolationCount}',
                    },
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (_settings.shuffleQuestions)
                      ExamTag(labelKey: 'exam_setting_shuffle_short'),
                    if (_settings.requireCamera)
                      ExamTag(labelKey: 'exam_setting_camera_short'),
                    if (!_settings.allowQuestionSkip)
                      ExamTag(labelKey: 'exam_setting_noskip_short'),
                    if (_settings.showResultsAfterClose)
                      ExamTag(labelKey: 'exam_setting_results_short'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _showSettings,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Text(context.tr('edit')),
          ),
        ],
      ),
    );
  }

  Widget _questionsHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.tr(
              'exam_questions_title',
              args: <String, String>{'count': '${_questions.length}'},
            ),
            style: theme.textTheme.titleMedium,
          ),
        ),
        IconButton.filledTonal(
          tooltip: context.tr('exam_add_question'),
          onPressed: () => _applyState(_addQuestion),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}


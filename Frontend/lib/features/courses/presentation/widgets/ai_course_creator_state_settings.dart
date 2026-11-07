part of '../pages/ai_course_creator_page.dart';

extension on _AiCourseCreatorPageState {
  Widget _buildPedagogicalSettingsAndActionCard(
    BuildContext context, {
    required bool isDesktop,
    required GenerationJobState job,
    required CoursePlanJobState planJob,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final running = job.status == GenerationJobStatus.running;
    final isGeneratingOutline = planJob.status == CoursePlanJobStatus.running;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('ai_sec_params_title'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('ai_sec_params_desc'),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(
          height: 1,
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        const SizedBox(height: 18),

        // Academic Level / Volume
        Text(
          context.tr('academic_level_label'),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (isDesktop) ...[
          Row(
            children: [
              Expanded(
                child: _SegmentPill(
                  label: _levelLabel(context, 'concis'),
                  subtitle: context.tr('ai_level_short_sub'),
                  selected: _level == 'concis',
                  onTap: () => updateState(() => _level = 'concis'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SegmentPill(
                  label: _levelLabel(context, 'equilibre'),
                  subtitle: context.tr('ai_level_standard_sub'),
                  selected: _level == 'equilibre',
                  onTap: () => updateState(() => _level = 'equilibre'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SegmentPill(
                  label: _levelLabel(context, 'detaille'),
                  subtitle: context.tr('ai_level_detailed_sub'),
                  selected: _level == 'detaille',
                  onTap: () => updateState(() => _level = 'detaille'),
                ),
              ),
            ],
          ),
        ] else ...[
          AppPickerRow(
            icon: Icons.school_outlined,
            value: _levelLabel(context, _level),
            onTap: () => _pickOption(
              titleKey: 'academic_level_label',
              options: _genLevels,
              labels: _genLevels.map((lvl) => _levelLabel(context, lvl)).toList(),
              current: _level,
              onSelected: (v) => updateState(() => _level = v),
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          context.tr('ai_level_hint'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 18),

        // Didactic Difficulty
        Text(
          context.tr('ai_difficulty_label'),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (isDesktop) ...[
          Row(
            children: [
              Expanded(
                child: _SegmentPill(
                  label: _difficultyLabel(context, 'facile'),
                  subtitle: context.tr('ai_diff_easy_sub'),
                  selected: _difficulty == 'facile',
                  onTap: () => updateState(() => _difficulty = 'facile'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SegmentPill(
                  label: _difficultyLabel(context, 'moyen'),
                  subtitle: context.tr('ai_diff_medium_sub'),
                  selected: _difficulty == 'moyen',
                  onTap: () => updateState(() => _difficulty = 'moyen'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SegmentPill(
                  label: _difficultyLabel(context, 'difficile'),
                  subtitle: context.tr('ai_diff_hard_sub'),
                  selected: _difficulty == 'difficile',
                  onTap: () => updateState(() => _difficulty = 'difficile'),
                ),
              ),
            ],
          ),
        ] else ...[
          AppPickerRow(
            icon: Icons.speed_outlined,
            value: _difficultyLabel(context, _difficulty),
            onTap: () => _pickOption(
              titleKey: 'ai_difficulty_label',
              options: const ['facile', 'moyen', 'difficile'],
              labels: [
                _difficultyLabel(context, 'facile'),
                _difficultyLabel(context, 'moyen'),
                _difficultyLabel(context, 'difficile'),
              ],
              current: _difficulty,
              onSelected: (v) => updateState(() => _difficulty = v),
            ),
          ),
        ],
        const SizedBox(height: 18),

        // Pedagogical Extras (Mermaid & Real Cases)
        Text(context.tr('ai_extras_label'), style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        _ExtrasBox(
          examples: _exExamples,
          mermaid: _exMermaid,
          onChanged: (examples, mermaid) => updateState(() {
            _exExamples = examples;
            _exMermaid = mermaid;
          }),
        ),
        const SizedBox(height: 22),

        // Action Launch Box
        if (_outline != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _outlineSaved
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _outlineSaved
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : const Color(0xFF6366F1).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _outlineSaved ? Icons.check_circle_rounded : Icons.schema_rounded,
                  color: _outlineSaved ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _outlineSaved
                            ? context.tr('ai_plan_saved_badge')
                            : context.tr('ai_plan_unsaved_badge'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _outlineSaved
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('ai_plan_review_desc'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: running ? null : () => _generate(useOutline: true),
            icon: const Icon(Icons.auto_awesome_rounded, size: 20),
            label: Text(
              context.tr('ai_btn_generate_from_outline'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              updateState(() => _outline = null);
              ref.read(coursePlanJobProvider.notifier).reset();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.tr('ai_btn_reset_outline')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ] else ...[
          // Primary Outline Validation Button (3s outline preview)
          FilledButton.icon(
            onPressed: running || isGeneratingOutline ? null : _generateOutline,
            icon: isGeneratingOutline
                ? const SmartLoader.small(customSize: 18, color: Colors.white)
                : const Icon(Icons.schema_rounded, size: 20),
            label: Text(
              isGeneratingOutline
                  ? context.tr(
                      'ai_proposing_outline_time',
                      args: {'sec': planJob.elapsedSec.toString()},
                    )
                  : context.tr('ai_btn_propose_outline'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.4),
            ),
          ),
          if (isGeneratingOutline) ...[
            const SizedBox(height: 8),
            Text(
              context.tr('ai_outline_bg_note'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Direct generation button
          OutlinedButton.icon(
            onPressed: running || isGeneratingOutline
                ? null
                : () => _generate(useOutline: false),
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: Text(context.tr('ai_outline_generate_direct')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.tr('estimate_rgpd'),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );

    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F172A).withValues(alpha: 0.95)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : const Color(0x0A0F172A),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: content,
      );
    }
    return content;
  }

}

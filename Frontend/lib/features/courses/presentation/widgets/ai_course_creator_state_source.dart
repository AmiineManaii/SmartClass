part of '../pages/ai_course_creator_page.dart';

extension on _AiCourseCreatorPageState {
  Widget _buildSourceAndContentCard(
    BuildContext context, {
    required bool isDesktop,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.source_rounded,
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
                    context.tr('ai_sec_source_title'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('ai_sec_source_desc'),
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

        // Mode Selector Label
        Text(context.tr('ai_mode_label'), style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),

        if (isDesktop) ...[
          Row(
            children: [
              Expanded(
                child: _DesktopModeCard(
                  icon: Icons.edit_note_rounded,
                  title: context.tr('ai_mode_topic'),
                  subtitle: context.tr('ai_mode_topic_sub'),
                  selected: _mode == 'topic',
                  onTap: () => updateState(() => _mode = 'topic'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DesktopModeCard(
                  icon: Icons.picture_as_pdf_rounded,
                  title: context.tr('ai_mode_pdf'),
                  subtitle: context.tr('ai_mode_pdf_sub'),
                  selected: _mode == 'pdf',
                  onTap: () => updateState(() => _mode = 'pdf'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DesktopModeCard(
                  icon: Icons.link_rounded,
                  title: context.tr('ai_mode_url'),
                  subtitle: context.tr('ai_mode_url_sub'),
                  selected: _mode == 'url',
                  onTap: () => updateState(() => _mode = 'url'),
                ),
              ),
            ],
          ),
        ] else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ModeChip(
                label: context.tr('ai_mode_topic'),
                selected: _mode == 'topic',
                onTap: () => updateState(() => _mode = 'topic'),
              ),
              _ModeChip(
                label: context.tr('ai_mode_pdf'),
                selected: _mode == 'pdf',
                onTap: () => updateState(() => _mode = 'pdf'),
              ),
              _ModeChip(
                label: context.tr('ai_mode_url'),
                selected: _mode == 'url',
                onTap: () => updateState(() => _mode = 'url'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),

        // Dynamic Source Inputs
        if (_mode == 'topic') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('topic_label'),
                style: theme.textTheme.labelLarge,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF312E81).withValues(alpha: 0.5)
                      : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                        : const Color(0xFFC7D2FE),
                  ),
                ),
                child: Text(
                  context.tr('recommended'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              controller: _topicController,
              maxLines: isDesktop ? 6 : 4,
              minLines: isDesktop ? 5 : 4,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: context.tr('topic_hint'),
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  height: 1.4,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Suggestion Chips
          Text(
            context.tr('module_suggestions').toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.05,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SuggestionChip(
                icon: Icons.format_list_numbered_rounded,
                label: context.tr('chip_detailed_plan'),
                onTap: () => _applySuggestionChip('plan'),
              ),
              _SuggestionChip(
                icon: Icons.quiz_outlined,
                label: context.tr('chip_quiz'),
                onTap: () => _applySuggestionChip('quiz'),
              ),
              _SuggestionChip(
                icon: Icons.code_rounded,
                label: context.tr('chip_exercises'),
                onTap: () => _applySuggestionChip('exercises'),
              ),
              _SuggestionChip(
                icon: Icons.cases_outlined,
                label: context.tr('chip_cases'),
                onTap: () => _applySuggestionChip('cases'),
              ),
              _SuggestionChip(
                icon: Icons.account_tree_outlined,
                label: context.tr('ai_chip_mermaid'),
                onTap: () => _applySuggestionChip('mermaid'),
              ),
            ],
          ),
        ],

        if (_mode == 'pdf') ...[
          InkWell(
            onTap: _pickPdf,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                      : const Color(0xFFCBD5E1),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF312E81).withValues(alpha: 0.4)
                          : const Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 26,
                      color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('drop_pdf_title'),
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('drop_pdf_formats'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _pickPdf,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: Text(context.tr('browse_files')),
                  ),
                ],
              ),
            ),
          ),
          if (_pdfName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 20,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _pdfName!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: context.tr('cancel'),
                    onPressed: () => updateState(() {
                      _pdfName = null;
                      _pdfBytes = null;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('topic_label'),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _topicController,
                maxLines: 2,
                minLines: 1,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: context.tr('ai_pdf_optional_topic'),
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(4),
                ),
              ),
            ),
          ],
        ],

        if (_mode == 'url') ...[
          Text(context.tr('ai_url_label'), style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: context.tr('ai_url_hint'),
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                ? const Color(0xFF6366F1).withValues(alpha: 0.2)
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

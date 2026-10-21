import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/courses_provider.dart';
import '../../domain/entities/generated_course.dart';
import '../widgets/ai_section_refine_dialog.dart';
import '../widgets/markdown_course_view.dart';

void _showCourseFailure(BuildContext context, Object error) {
  final Failure failure =
      error is ApiException ? apiExceptionToFailure(error) : error as Failure;
  final l10n = failureL10n(failure);
  context.showErrorToast(context.tr(l10n.key, args: l10n.args));
}

class _HeadingItem {
  final String title;
  final int level;
  final int lineIndex;

  const _HeadingItem({
    required this.title,
    required this.level,
    required this.lineIndex,
  });
}

List<_HeadingItem> _extractHeadings(String content) {
  final lines = content.split('\n');
  final result = <_HeadingItem>[];
  for (var i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed.startsWith('# ')) {
      result.add(_HeadingItem(
        title: trimmed.substring(2).trim(),
        level: 1,
        lineIndex: i,
      ));
    } else if (trimmed.startsWith('## ')) {
      result.add(_HeadingItem(
        title: trimmed.substring(3).trim(),
        level: 2,
        lineIndex: i,
      ));
    } else if (trimmed.startsWith('### ')) {
      result.add(_HeadingItem(
        title: trimmed.substring(4).trim(),
        level: 3,
        lineIndex: i,
      ));
    }
  }
  return result;
}

/// Lecteur de cours SmartClass widescreen et mobile, aligné sur la maquette Stitch
/// screen `5ce9abc104ce46afa036366ee3263d9b` ("SmartClass - Lecteur de Cours & Résumé IA").
class CourseReaderPage extends ConsumerWidget {
  final String courseId;

  const CourseReaderPage({super.key, required this.courseId});

  Future<void> _copyContent(BuildContext context, String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    context.showSuccessToast(context.tr('ai_copied'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(generatedCourseProvider(courseId));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          tooltip: 'Retour au cours',
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                courseAsync.valueOrNull?.title ?? context.tr('course_details'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF8197FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 14, color: Color(0xFFF5A623)),
                  SizedBox(width: 4),
                  Text(
                    'IA Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF122675),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (courseAsync.valueOrNull != null) ...[
            IconButton(
              icon: const Icon(Icons.bookmark_border_rounded),
              tooltip: 'Favori',
              onPressed: () {
                context.showSuccessToast('Cours ajouté à vos favoris');
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: context.tr('course_export'),
              onSelected: (val) {
                if (val == 'copy') {
                  _copyContent(context, courseAsync.valueOrNull?.content ?? '');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      const Icon(Icons.copy_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(context.tr('course_export_copy')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: courseAsync.when(
        loading: () => const Center(
          child: SmartLoader.large(message: 'Chargement du contenu du cours...'),
        ),
        error: (error, _) => _ReaderError(
          error: error,
          onRetry: () => ref.invalidate(generatedCourseProvider(courseId)),
        ),
        data: (course) => _ReaderBody(course: course),
      ),
    );
  }
}

class _ReaderBody extends ConsumerStatefulWidget {
  final GeneratedCourse course;

  const _ReaderBody({required this.course});

  @override
  ConsumerState<_ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends ConsumerState<_ReaderBody> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _notesController = TextEditingController(
    text: 'Mes notes de cours :\n- Théorème du Rang : dim(E) = dim(Ker(f)) + rg(f)\n- Vérifier toujours la stabilité par combinaison linéaire.',
  );

  int _selectedRailTab = 0; // 0: Résumé IA, 1: Fiches, 2: Notes
  int _mobileTab = 0; // 0: Cours complet, 1: Résumé IA, 2: Fiches & Notes
  bool _isVideoExpanded = true;
  bool _isPlaying = false;
  double _playbackSpeed = 1.25;
  String _currentTimeDisplay = '14:28';
  final String _totalDurationDisplay = '45:10';

  @override
  void dispose() {
    _scrollController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _canModerate(String? role, String? userId) {
    if (role == 'admin') return true;
    return role == 'teacher' && userId != null && userId == widget.course.authorId;
  }

  void _scrollToHeading(_HeadingItem item, int totalLines) {
    if (!_scrollController.hasClients || totalLines == 0) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final fraction = (item.lineIndex / totalLines).clamp(0.0, 1.0);
    final target = (maxScroll * fraction).clamp(0.0, maxScroll);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToFraction(double fraction) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final target = (maxScroll * fraction).clamp(0.0, maxScroll);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _showSommaire(BuildContext context, List<_HeadingItem> headings, int totalLines) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt_rounded, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${context.tr('course_sommaire')} (${headings.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (headings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Aucun sous-titre détecté',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: headings.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final h = headings[index];
                        final indent = (h.level - 1) * 16.0;
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            _scrollToHeading(h, totalLines);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(indent + 8, 10, 8, 10),
                            child: Row(
                              children: [
                                Icon(
                                  h.level == 1
                                      ? Icons.folder_rounded
                                      : h.level == 2
                                          ? Icons.subdirectory_arrow_right_rounded
                                          : Icons.circle,
                                  size: h.level == 3 ? 6 : 16,
                                  color: h.level == 1
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    h.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: h.level == 1
                                          ? FontWeight.bold
                                          : h.level == 2
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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

        await ref.read(generatedCoursesDataSourceProvider).updateCourse(
              id: widget.course.id,
              content: updated,
            );
        ref
          ..invalidate(generatedCourseProvider(widget.course.id))
          ..invalidate(myGeneratedCoursesProvider)
          ..invalidate(publishedCoursesProvider);
      },
    );
  }

  Future<void> _publish(BuildContext context) async {
    try {
      await ref.read(generatedCoursesDataSourceProvider).publish(widget.course.id);
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
      await ref.read(generatedCoursesDataSourceProvider).unpublish(widget.course.id);
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
      await ref.read(generatedCoursesDataSourceProvider).deleteCourse(widget.course.id);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.screenWidth >= 1024;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final canModerate = _canModerate(auth?.role, auth?.userId);

    final content = widget.course.content ?? '';
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final readingMin = (words / 200).ceil().clamp(1, 180);
    final headings = _extractHeadings(content);
    final totalLines = content.split('\n').length;

    if (isDesktop) {
      return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Left Widescreen Workspace (Video Player + Markdown Reader + Moderator Strip)
                Expanded(
                  flex: 65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Video / Slide Presentation Hero (Collapsible)
                      if (_isVideoExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
                          child: _buildVideoLectureBanner(context, headings, totalLines),
                        ),

                      // Instructor & Meta Header Strip
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                        child: _buildCourseTitleMetaStrip(
                          context,
                          readingMin: readingMin,
                          headingsCount: headings.length,
                          totalLines: totalLines,
                          headings: headings,
                          isDesktop: true,
                        ),
                      ),

                      const Divider(height: 1, indent: 24, endIndent: 16),

                      // Scrollable Markdown Reader
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(28, 16, 20, 24),
                          child: MarkdownCourseView(data: content),
                        ),
                      ),

                      // Moderator Toolbar
                      if (canModerate)
                        _buildModeratorBar(context, colorScheme),
                    ],
                  ),
                ),

                // Vertical Divider
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),

                // 2. Right Widescreen Rail: AI Summary, Flashcards, and Personal Notes
                Expanded(
                  flex: 35,
                  child: Container(
                    color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                    child: _buildAiCompanionRail(
                      context,
                      headings: headings,
                      totalLines: totalLines,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile / Tablet Responsive View
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact Video Banner
          if (_isVideoExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: _buildVideoLectureBanner(context, headings, totalLines),
            ),

          // Course Meta & Mobile Segmented Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildCourseTitleMetaStrip(
              context,
              readingMin: readingMin,
              headingsCount: headings.length,
              totalLines: totalLines,
              headings: headings,
              isDesktop: false,
            ),
          ),

          // Mobile View Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabPill(
                    title: 'Cours complet',
                    isSelected: _mobileTab == 0,
                    icon: Icons.menu_book_rounded,
                    onTap: () => setState(() => _mobileTab = 0),
                  ),
                  _buildTabPill(
                    title: 'Résumé IA',
                    isSelected: _mobileTab == 1,
                    icon: Icons.auto_awesome,
                    badge: 'En direct',
                    onTap: () => setState(() => _mobileTab = 1),
                  ),
                  _buildTabPill(
                    title: 'Fiches (4)',
                    isSelected: _mobileTab == 2,
                    icon: Icons.style_rounded,
                    onTap: () => setState(() => _mobileTab = 2),
                  ),
                ],
              ),
            ),
          ),

          // Body Content depending on mobile tab
          Expanded(
            child: _mobileTab == 0
                ? SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: MarkdownCourseView(data: content),
                  )
                : _mobileTab == 1
                    ? _buildAiSummaryTab(context, headings, totalLines)
                    : _buildFlashcardsTab(context),
          ),

          if (canModerate)
            _buildModeratorBar(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required String title,
    required bool isSelected,
    required IconData icon,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? const Color(0xFF122675) : const Color(0xFF757682),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? const Color(0xFF122675) : const Color(0xFF757682),
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE1FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001257),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Interactive Video / Slides presentation banner matching Stitch screen `5ce9abc104ce46afa036366ee3263d9b`.
  Widget _buildVideoLectureBanner(
    BuildContext context,
    List<_HeadingItem> headings,
    int totalLines,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151B2F),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visual Canvas with Scrim & Overlay
          AspectRatio(
            aspectRatio: 16 / 8.5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Classroom / Chalkboard aesthetic background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF1E293B),
                        Color(0xFF111827),
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    painter: _ChalkboardFormulaPainter(),
                  ),
                ),

                // Dark Graduated Scrim
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),

                // Top Overlay: HD badge, Subject & Chapter info
                Positioned(
                  top: 12,
                  left: 14,
                  right: 80,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.smart_display_rounded, size: 13, color: Color(0xFF65DBB2)),
                            SizedBox(width: 4),
                            Text(
                              'HD • Validé',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.course.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PIP Lecturer Bubble (Prof. Amine / Author)
                Positioned(
                  top: 10,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF2D3E8C),
                      child: Text(
                        widget.course.authorName.isNotEmpty
                            ? widget.course.authorName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                // Center Play / Pause Touch Button
                Center(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isPlaying = !_isPlaying;
                      });
                    },
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: const Color(0xFF122675),
                        size: 30,
                      ),
                    ),
                  ),
                ),

                // Scrubber Bar with AI Timestamp Markers
                Positioned(
                  bottom: 34,
                  left: 14,
                  right: 14,
                  child: Column(
                    children: [
                      // Interactive Track
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          return SizedBox(
                            height: 18,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Background bar
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // Buffered bar
                                Container(
                                  height: 4,
                                  width: width * 0.65,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // Elapsed bar
                                Container(
                                  height: 4,
                                  width: width * 0.32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8197FF),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // Current pin
                                Positioned(
                                  left: (width * 0.32) - 6,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF122675),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // AI Key Point Markers (Stitch yellow dots)
                                _buildMarkerDot(
                                  left: width * 0.09,
                                  tooltip: '04:12 Axiomes',
                                  onTap: () {
                                    setState(() => _currentTimeDisplay = '04:12');
                                    _scrollToFraction(0.1);
                                  },
                                ),
                                _buildMarkerDot(
                                  left: width * 0.28,
                                  tooltip: '12:45 Bases',
                                  onTap: () {
                                    setState(() => _currentTimeDisplay = '12:45');
                                    _scrollToFraction(0.3);
                                  },
                                ),
                                _buildMarkerDot(
                                  left: width * 0.63,
                                  tooltip: '28:30 Théorème du Rang',
                                  onTap: () {
                                    setState(() => _currentTimeDisplay = '28:30');
                                    _scrollToFraction(0.65);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Bottom Meta Strip: Timecode, Speed, CC, Volume
                Positioned(
                  bottom: 8,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$_currentTimeDisplay / $_totalDurationDisplay',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CHAP. 3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_playbackSpeed == 1.0) {
                                  _playbackSpeed = 1.25;
                                } else if (_playbackSpeed == 1.25) {
                                  _playbackSpeed = 1.5;
                                } else {
                                  _playbackSpeed = 1.0;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${_playbackSpeed}x',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.closed_caption, size: 12, color: Colors.white),
                                SizedBox(width: 2),
                                Text(
                                  'FR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.volume_up_rounded, size: 16, color: Colors.white70),
                          const SizedBox(width: 8),
                          const Icon(Icons.fullscreen_rounded, size: 17, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerDot({
    required double left,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: left - 4,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Title & Meta strip displaying professor, reading duration, and quick sommaire launch.
  Widget _buildCourseTitleMetaStrip(
    BuildContext context, {
    required int readingMin,
    required int headingsCount,
    required int totalLines,
    required List<_HeadingItem> headings,
    required bool isDesktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            widget.course.authorName.isNotEmpty
                ? widget.course.authorName[0].toUpperCase()
                : 'P',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Prof. ${widget.course.authorName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 14, color: Color(0xFF003627)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: (widget.course.isPublished
                              ? colorScheme.primary
                              : colorScheme.tertiary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      context.tr(widget.course.isPublished ? 'published' : 'draft'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.course.isPublished
                            ? colorScheme.primary
                            : colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Durée ~$readingMin min • ${_levelName(widget.course.level)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (headingsCount > 0)
          ActionChip(
            avatar: const Icon(Icons.list_alt_rounded, size: 14),
            label: Text('Sommaire ($headingsCount)'),
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
            side: BorderSide.none,
            onPressed: () => _showSommaire(context, headings, totalLines),
          ),
        const SizedBox(width: 6),
        IconButton(
          icon: Icon(
            _isVideoExpanded ? Icons.expand_less_rounded : Icons.smart_display_outlined,
            size: 20,
          ),
          tooltip: _isVideoExpanded ? 'Masquer la vidéo' : 'Afficher la vidéo',
          onPressed: () {
            setState(() {
              _isVideoExpanded = !_isVideoExpanded;
            });
          },
        ),
      ],
    );
  }

  /// AI Companion Rail (Right column on widescreen desktop)
  Widget _buildAiCompanionRail(
    BuildContext context, {
    required List<_HeadingItem> headings,
    required int totalLines,
  }) {
    return Column(
      children: [
        // Top Segmented Bar: Résumé IA, Fiches, Notes
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabPill(
                  title: 'Résumé IA',
                  isSelected: _selectedRailTab == 0,
                  icon: Icons.auto_awesome,
                  badge: 'En direct',
                  onTap: () => setState(() => _selectedRailTab = 0),
                ),
                _buildTabPill(
                  title: 'Fiches (4)',
                  isSelected: _selectedRailTab == 1,
                  icon: Icons.style_rounded,
                  onTap: () => setState(() => _selectedRailTab = 1),
                ),
                _buildTabPill(
                  title: 'Notes',
                  isSelected: _selectedRailTab == 2,
                  icon: Icons.edit_note_rounded,
                  onTap: () => setState(() => _selectedRailTab = 2),
                ),
              ],
            ),
          ),
        ),

        // Rail Content Stream
        Expanded(
          child: _selectedRailTab == 0
              ? _buildAiSummaryTab(context, headings, totalLines)
              : _selectedRailTab == 1
                  ? _buildFlashcardsTab(context)
                  : _buildNotesTab(context),
        ),
      ],
    );
  }

  /// Tab 0: AI Summary with key points, formula highlights, and question rebound.
  Widget _buildAiSummaryTab(
    BuildContext context,
    List<_HeadingItem> headings,
    int totalLines,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AI Guarantee & Meta Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF8197FF).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, size: 20, color: Color(0xFFF5A623)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Synthèse SmartClass IA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF151B2F),
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF83F8CD),
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              '98% fidélité',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF002116),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Synchronisé avec l\'audio du cours et les diapositives.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF757682)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Expanded(
              child: Text(
                'Points clés & Notions fondamentales',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151B2F),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '4 indexés',
              style: TextStyle(fontSize: 11, color: Color(0xFF757682)),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Point 1: Axiomes de base
        _buildKeyPointCard(
          timestamp: '04:12',
          tag: 'Axiomes de base',
          title: 'Définition axiomatique d\'un espace vectoriel (E, +, ·)',
          description:
              'Un ensemble non vide E muni de deux lois de composition interne (+) et externe (·) vérifiant la structure de groupe abélien et la distributivité scalaire.',
          ruleHighlight:
              'Règle d\'or : Vérifier systématiquement la stabilité par combinaison linéaire αx + βy ∈ E et l\'élément neutre 0_E.',
          onTimestampTap: () => _scrollToFraction(0.1),
        ),

        const SizedBox(height: 12),

        // Point 2: Bases & Indépendance
        _buildKeyPointCard(
          timestamp: '12:45',
          tag: 'Bases & Indépendance',
          title: 'Familles libres, génératrices et dimension finie',
          description:
              '• Famille libre : Toute combinaison linéaire ∑ λ_i v_i = 0 impose λ_1 = ... = λ_n = 0.\n• Dimension : Le cardinal invariant de toute base finie caractérise dim(E).',
          onTimestampTap: () => _scrollToFraction(0.3),
        ),

        const SizedBox(height: 12),

        // Point 3: Théorème du Rang (Rank-Nullity) with formula block
        _buildKeyPointCard(
          timestamp: '28:30',
          tag: 'Incontournable Examen',
          tagColor: const Color(0xFFFEF3C7),
          tagTextColor: const Color(0xFFB45309),
          title: 'Théorème du Rang (Rank-Nullity Theorem)',
          description:
              'Ce résultat fondamental relie l\'espace de départ, le noyau (injectivité) et l\'image (surjectivité).',
          formula: 'dim(E) = dim(Ker(f)) + rg(f)',
          formulaSubtext: 'où rg(f) = dim(Im(f)) pour toute application linéaire f: E → F',
          onTimestampTap: () => _scrollToFraction(0.65),
        ),

        const SizedBox(height: 12),

        // Point 4: Piège fréquent
        _buildKeyPointCard(
          timestamp: '39:15',
          tag: 'Piège fréquent',
          tagColor: const Color(0xFFFFDAD6),
          tagTextColor: const Color(0xFF93000A),
          title: 'Applications directes & Vigilance matricielle',
          description:
              'Ne confondez pas la dimension de l\'ensemble d\'arrivée avec le rang de la matrice. Le rang ne peut jamais excéder min(dim E, dim F).',
          onTimestampTap: () => _scrollToFraction(0.9),
        ),

        const SizedBox(height: 18),

        // Rebound Prompts to Interactive AI Tutor
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEBEDFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFFF5A623)),
                  SizedBox(width: 6),
                  Text(
                    'Rebonds et Questions au Tuteur',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF151B2F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildReboundButton(
                prompt: 'Pourquoi Ker(f) = {0} garantit l\'injectivité ?',
                onTap: () => context.push('/ai-assistant'),
              ),
              const SizedBox(height: 6),
              _buildReboundButton(
                prompt: 'Générer un QCM d\'entraînement sur ce cours ⚡',
                onTap: () => context.push('/ai-assistant'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyPointCard({
    required String timestamp,
    required String tag,
    Color? tagColor,
    Color? tagTextColor,
    required String title,
    required String description,
    String? ruleHighlight,
    String? formula,
    String? formulaSubtext,
    required VoidCallback onTimestampTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E7FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with timestamp chip and badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onTimestampTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE1FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 13, color: Color(0xFF122675)),
                      const SizedBox(width: 2),
                      Text(
                        timestamp,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF122675),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor ?? const Color(0xFFF3F2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: tagTextColor ?? const Color(0xFF454651),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151B2F),
            ),
          ),

          const SizedBox(height: 6),

          // Formula Highlight
          if (formula != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEBEDFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    formula,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF122675),
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (formulaSubtext != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      formulaSubtext,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF454651)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF454651),
              height: 1.4,
            ),
          ),

          // Golden Rule
          if (ruleHighlight != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, size: 15, color: Color(0xFFF5A623)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ruleHighlight,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF151B2F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReboundButton({
    required String prompt,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCE1FE)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                prompt,
                style: const TextStyle(fontSize: 12, color: Color(0xFF151B2F)),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF2D3E8C)),
          ],
        ),
      ),
    );
  }

  /// Tab 1: Interactive Flashcards
  Widget _buildFlashcardsTab(BuildContext context) {
    final flashcards = [
      {
        'q': 'Qu\'est-ce qu\'un espace vectoriel ?',
        'a': 'Un ensemble E muni d\'une LCI (+) formant un groupe abélien et d\'une LCE (·) distributive sur le corps K.',
        'tag': 'Définition',
      },
      {
        'q': 'Quelle est la condition pour qu\'une famille soit libre ?',
        'a': 'Toute combinaison linéaire nulle impose des coefficients tous nuls (∑ λ_i v_i = 0 ⇒ λ_i = 0).',
        'tag': 'Théorème',
      },
      {
        'q': 'Formule du Théorème du Rang ?',
        'a': 'dim(E) = dim(Ker(f)) + rg(f) avec rg(f) = dim(Im(f)).',
        'tag': 'Formule Clé',
      },
      {
        'q': 'Comment prouver qu\'une application linéaire est injective ?',
        'a': 'Il suffit de vérifier que son noyau est réduit au vecteur nul : Ker(f) = {0_E}.',
        'tag': 'Méthode',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Fiches de Révision Automatiques',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151B2F),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDDE1FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '4 fiches prêtes',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001257),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...flashcards.map((f) => _FlashcardItemCard(
              question: f['q']!,
              answer: f['a']!,
              tag: f['tag']!,
            )),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push('/ai-assistant'),
          icon: const Icon(Icons.play_circle_outline, size: 18),
          label: const Text('Lancer un quiz d\'entraînement ⚡'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2D3E8C),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  /// Tab 2: Personal Notes Scratchpad
  Widget _buildNotesTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Bloc-notes personnel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF151B2F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                tooltip: 'Copier mes notes',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _notesController.text));
                  context.showSuccessToast('Notes copiées dans le presse-papier');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE3E7FF)),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontSize: 13, height: 1.5),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Écrivez vos remarques, questions ou formules à retenir...',
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _notesController.text += '\n• ';
                    });
                  },
                  icon: const Icon(Icons.format_list_bulleted, size: 16),
                  label: const Text('Ajouter puce'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    context.showSuccessToast('Notes sauvegardées automatiquement');
                  },
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Enregistrer'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF122675),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Moderator / Teacher action bar
  Widget _buildModeratorBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _refineWithAi(context),
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: Text(context.tr('ai_refine_btn')),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (widget.course.isDraft)
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _publish(context),
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: Text(context.tr('validate_course')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _unpublish(context),
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                label: Text(context.tr('unpublish_course')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
            tooltip: context.tr('delete'),
            onPressed: () => _delete(context),
          ),
        ],
      ),
    );
  }

  String _levelName(String level) {
    return switch (level) {
      'concis' => 'Cours court',
      'detaille' => 'Cours complet',
      _ => 'Cours normal',
    };
  }
}

/// Interactive Flashcard Component with question and answer reveal
class _FlashcardItemCard extends StatefulWidget {
  final String question;
  final String answer;
  final String tag;

  const _FlashcardItemCard({
    required this.question,
    required this.answer,
    required this.tag,
  });

  @override
  State<_FlashcardItemCard> createState() => _FlashcardItemCardState();
}

class _FlashcardItemCardState extends State<_FlashcardItemCard> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _showAnswer ? const Color(0xFF8197FF) : const Color(0xFFE3E7FF),
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _showAnswer = !_showAnswer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F2FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.tag,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3E8C),
                      ),
                    ),
                  ),
                  Text(
                    _showAnswer ? 'Masquer' : 'Voir réponse',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _showAnswer ? const Color(0xFF757682) : const Color(0xFF2D3E8C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.question,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151B2F),
                ),
              ),
              if (_showAnswer) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBEDFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.answer,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF122675),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for chalkboard formula lines aesthetic in video player background
class _ChalkboardFormulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Subtle grid lines & circle geometry
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.9),
      Offset(size.width * 0.7, size.height * 0.1),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.height * 0.3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReaderError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ReaderError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Failure failure = error is ApiException
        ? apiExceptionToFailure(error as ApiException)
        : error is Failure
            ? error as Failure
            : ServerFailure(error.toString());
    final l10n = failureL10n(failure);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(l10n.key, args: l10n.args),
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

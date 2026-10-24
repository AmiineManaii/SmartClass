import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../courses/application/providers/courses_provider.dart';
import '../../../courses/domain/entities/course_entry.dart';

/// Tuteur IA & Studio IA.
///
/// The conversational tutor backend does not exist yet (no chat route in
/// `contracts/ai-assistant.openapi.yaml`), so this page never fabricates an
/// AI answer. It is wired to the caller's real classes
/// (`GET /api/v1/groups/mine`) and routes to the real AI features
/// (revision summary, practice quiz, course creator for teachers).
class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isGenerating = false;
  String? _selectedClassId;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  CourseEntry? _activeClass(List<CourseEntry> classes) {
    if (classes.isEmpty) return null;
    for (final c in classes) {
      if (c.id == _selectedClassId) return c;
    }
    return classes.first;
  }

  String _levelLabel(BuildContext context, String level) {
    final key = switch (level) {
      'LICENCE' => 'level_licence',
      'MASTER' => 'level_master',
      'DOCTORAT' => 'level_doctorat',
      _ => '',
    };
    return key.isEmpty ? level : context.tr(key);
  }

  Future<void> _sendMessage(String text) async {
    final value = text.trim();
    if (value.isEmpty || _isGenerating) return;

    setState(() {
      _messages.add(
        _ChatMessage(text: value, isUser: true, timestamp: DateTime.now()),
      );
      _isGenerating = true;
      _controller.clear();
    });
    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final classes = ref.read(myCoursesProvider).valueOrNull ?? const [];
    final active = _activeClass(classes);
    final className = active?.name ?? context.tr('no_class_title');

    setState(() {
      _messages.add(
        _ChatMessage(
          text:
              'Le tuteur conversationnel temps réel sera disponible avec le module IA (📋 planifié). '
              'Aucune réponse n\'est générée hors de ce module pour éviter toute information inventée.\n\n'
              'En attendant, le Studio IA peut réellement travailler sur **$className** :',
          isUser: false,
          timestamp: DateTime.now(),
          stepTitle: 'Module IA en préparation',
          actions: const ['summary', 'quiz'],
        ),
      );
      _isGenerating = false;
    });
    _scrollToBottom();
  }

  void _clearHistory() {
    setState(() => _messages.clear());
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Effacer la conversation'),
        content: const Text(
          'Voulez-vous réinitialiser cette séance d\'étude avec le tuteur ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (confirmed == true) _clearHistory();
  }

  void _showChangeClassDialog(
    BuildContext context,
    List<CourseEntry> classes,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Changer de classe'),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: classes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = classes[i];
              final selected = c.id == _activeClass(classes)?.id;
              return _ClassSelectTile(
                title: c.name,
                subtitle: [
                  _levelLabel(context, c.level),
                  if (c.department != null && c.department!.isNotEmpty)
                    c.department!,
                ].join(' • '),
                isSelected: selected,
                onTap: () {
                  setState(() {
                    _selectedClassId = c.id;
                    _messages.clear();
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.screenWidth >= 1024;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final isTeacher = auth?.role?.toLowerCase() == 'teacher';
    final classesAsync = ref.watch(myCoursesProvider);
    final classes = classesAsync.valueOrNull ?? const <CourseEntry>[];
    final active = _activeClass(classes);

    if (isTeacher) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(
            context.tr('ai_tutor'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _TeacherStudioGrid(active: active),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: colorScheme.onPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tuteur IA Interactif',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'SmartClass AI • ${active?.name ?? context.tr('no_class_title')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 3, backgroundColor: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  classesAsync.isLoading
                      ? context.tr('loading')
                      : '${classes.length} classe(s)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Effacer la conversation',
            onPressed: _messages.isEmpty ? null : _confirmClearHistory,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: classesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildEmptyState(
          context,
          title: context.tr('server_error'),
          message: context.tr('check_connection'),
          onRetry: () => ref.invalidate(myCoursesProvider),
        ),
        data: (realClasses) {
          if (realClasses.isEmpty) {
            return _buildEmptyState(
              context,
              title: context.tr('no_class_title'),
              message: context.tr('no_class_message'),
              onRetry: () => ref.invalidate(myCoursesProvider),
            );
          }
          final current = _activeClass(realClasses)!;
          return Column(
            children: [
              _buildClassContextBar(context, current, realClasses, isTeacher),
              Expanded(
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _buildChatColumn(context, current),
                          ),
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.4),
                          ),
                          Expanded(
                            flex: 5,
                            child: _buildDesktopRail(context, current),
                          ),
                        ],
                      )
                    : _buildChatColumn(context, current),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 72,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassContextBar(
    BuildContext context,
    CourseEntry active,
    List<CourseEntry> classes,
    bool isTeacher,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = [
      _levelLabel(context, active.level),
      if (active.department != null && active.department!.isNotEmpty)
        active.department!,
      context.tr('courses_students_count',
          args: {'count': '${active.memberCount}'}),
    ].join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.menu_book_rounded,
              color: colorScheme.primary,
              size: 16,
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
                        active.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isTeacher ? 'Espace Enseignant' : 'Aligné classe',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isTeacher) ...[
            IconButton.filledTonal(
              icon: const Icon(Icons.draw_rounded, size: 16),
              tooltip: 'Studio Créateur IA',
              visualDensity: VisualDensity.compact,
              onPressed: () => context.go('/courses/ai-create'),
            ),
            const SizedBox(width: 8),
          ],
          OutlinedButton.icon(
            onPressed: classes.length > 1
                ? () => _showChangeClassDialog(context, classes)
                : null,
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('Changer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatColumn(BuildContext context, CourseEntry active) {
    final colorScheme = Theme.of(context).colorScheme;
    final prompts = [
      'Résume ${active.name}',
      'Génère un quiz sur ${active.name}',
      'Où en est le module IA ?',
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: 1 + _messages.length + (_isGenerating ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildIntroBubble(context, active);
              }
              final msgIndex = index - 1;
              if (msgIndex == _messages.length) {
                return _buildTypingIndicator(context);
              }
              return _buildMessage(context, _messages[msgIndex]);
            },
          ),
        ),
        Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: prompts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              return ActionChip(
                backgroundColor: colorScheme.surfaceContainerLowest,
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                label: Text(
                  prompts[i],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => _sendMessage(prompts[i]),
              );
            },
          ),
        ),
        _buildInputBar(context),
      ],
    );
  }

  Widget _buildIntroBubble(BuildContext context, CourseEntry active) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final name = (auth?.displayName?.trim().isNotEmpty == true)
        ? auth!.displayName!.trim()
        : context.tr('student_greeting_default');

    return _TutorBubble(
      title: 'Tuteur Connecté',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour $name ! Je suis connecté à votre classe **${active.name}**. '
            'Le moteur de révision et les quiz sont disponibles via le Studio IA.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionPill(
                icon: Icons.summarize_rounded,
                label: context.tr('course_summary'),
                onTap: () => context.push('/ai-revision'),
              ),
              _ActionPill(
                icon: Icons.quiz_rounded,
                label: context.tr('practice_quiz'),
                onTap: () => context.push('/ai-quiz'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, _ChatMessage message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.timestamp.formatTime(),
                style: TextStyle(
                  color: colorScheme.onPrimary.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _TutorBubble(
      title: message.stepTitle ?? 'Tuteur IA SmartClass',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: colorScheme.onSurface,
            ),
          ),
          if (message.actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (message.actions.contains('summary'))
                  _ActionPill(
                    icon: Icons.summarize_rounded,
                    label: context.tr('course_summary'),
                    onTap: () => context.push('/ai-revision'),
                  ),
                if (message.actions.contains('quiz'))
                  _ActionPill(
                    icon: Icons.quiz_rounded,
                    label: context.tr('practice_quiz'),
                    onTap: () => context.push('/ai-quiz'),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.content_copy_rounded, size: 16),
                tooltip: 'Copier',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  context.showSuccessToast('Message copié');
                },
              ),
              const Spacer(),
              Text(
                'Module IA non connecté',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRail(BuildContext context, CourseEntry active) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.style_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ma classe',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _InfoTag(
                      icon: Icons.school_rounded,
                      label: _levelLabel(context, active.level),
                      color: colorScheme.primary,
                    ),
                    if (active.department != null &&
                        active.department!.isNotEmpty)
                      _InfoTag(
                        icon: Icons.account_balance_rounded,
                        label: active.department!,
                        color: colorScheme.secondary,
                      ),
                    _InfoTag(
                      icon: Icons.people_alt_rounded,
                      label: context.tr('courses_students_count',
                          args: {'count': '${active.memberCount}'}),
                      color: colorScheme.onSurfaceVariant,
                    ),
                    _InfoTag(
                      icon: Icons.co_present_rounded,
                      label: context.tr('courses_teachers_count',
                          args: {'count': '${active.teacherCount}'}),
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (active.subjects.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    active.subjects.join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Outils IA disponibles',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _RailTool(
            icon: Icons.summarize_rounded,
            title: context.tr('course_summary'),
            subtitle: context.tr('course_summary_desc'),
            onTap: () => context.push('/ai-revision'),
          ),
          const SizedBox(height: 10),
          _RailTool(
            icon: Icons.quiz_rounded,
            title: context.tr('practice_quiz'),
            subtitle: context.tr('practice_quiz_desc'),
            onTap: () => context.push('/ai-quiz'),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le tuteur conversationnel temps réel arrive avec le module IA (📋 planifié).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Posez une question sur le cours au tuteur...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: colorScheme.outline,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.send_rounded,
                  color: colorScheme.onPrimary,
                  size: 18,
                ),
                onPressed: _isGenerating ? null : () => _sendMessage(_controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_rounded, color: colorScheme.primary, size: 16),
            const SizedBox(width: 8),
            Text(
              'Vérification du module IA...',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? stepTitle;
  final List<String> actions;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.stepTitle,
    this.actions = const [],
  });
}

/// Vue Tuteur IA pour le professeur : 4 cartes animées (Cours IA, Résumé IA,
/// Test IA, Examen IA) disposées 2 par ligne.
class _TeacherStudioGrid extends StatelessWidget {
  final CourseEntry? active;

  const _TeacherStudioGrid({this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('ai_studio_section_title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('ai_studio_section_desc'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.95,
            children: const [
              _AnimatedStudioCard(
                index: 0,
                icon: Icons.auto_stories_rounded,
                titleKey: 'ai_card_course',
                subtitleKey: 'ai_card_course_desc',
                route: '/courses/ai-create',
                accent: Color(0xFF122675),
              ),
              _AnimatedStudioCard(
                index: 1,
                icon: Icons.summarize_rounded,
                titleKey: 'course_summary',
                subtitleKey: 'course_summary_desc',
                route: '/ai-revision',
                accent: Color(0xFF4056B9),
              ),
              _AnimatedStudioCard(
                index: 2,
                icon: Icons.quiz_rounded,
                titleKey: 'ai_card_test',
                subtitleKey: 'ai_card_test_desc',
                route: '/ai-quiz',
                accent: Color(0xFF003627),
              ),
              _AnimatedStudioCard(
                index: 3,
                icon: Icons.fact_check_rounded,
                titleKey: 'ai_card_exam',
                subtitleKey: 'ai_card_exam_desc',
                route: '/exams',
                accent: Color(0xFF0F9D78),
              ),
            ],
          ),
          if (active != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Classe active : ${active!.name}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}

/// Carte studio animée : entrée staggered (fade + slide-up) puis
/// hover scale + glow (shadow colorisé).
class _AnimatedStudioCard extends StatefulWidget {
  final int index;
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final String route;
  final Color accent;

  const _AnimatedStudioCard({
    required this.index,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.route,
    required this.accent,
  });

  @override
  State<_AnimatedStudioCard> createState() => _AnimatedStudioCardState();
}

class _AnimatedStudioCardState extends State<_AnimatedStudioCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(
      parent: _entry,
      curve: Interval(0, 0.7, curve: Curves.easeOutCubic),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
    // Staggered : chaque carte démarre avec un décalage de 140ms.
    Future<void>.delayed(Duration(milliseconds: 140 * widget.index), () {
      if (mounted) _entry.forward();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => context.push(widget.route),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              transformAlignment: Alignment.center,
              transform: Matrix4.identity()
                ..scaleByDouble(
                  _hovered ? 1.04 : 1.0,
                  _hovered ? 1.04 : 1.0,
                  1.0,
                  1.0,
                ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hovered
                      ? widget.accent.withValues(alpha: 0.5)
                      : theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                  width: _hovered ? 1.4 : 1,
                ),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: widget.accent.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(
                            alpha: 0.04,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(
                            alpha: _hovered ? 0.2 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.accent,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      AnimatedSlide(
                        duration: const Duration(milliseconds: 220),
                        offset: Offset(_hovered ? 0.1 : 0, 0),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: _hovered
                              ? widget.accent
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    context.tr(widget.titleKey),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr(widget.subtitleKey),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10.5,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorBubble extends StatelessWidget {
  final String title;
  final Widget child;

  const _TutorBubble({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 32),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RailTool extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RailTool({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassSelectTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClassSelectTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
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
      ),
    );
  }
}

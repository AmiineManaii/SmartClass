part of '../widgets/teacher_dashboard_view.dart';
class _DashboardBody extends ConsumerStatefulWidget {
  final TeacherDashboardData data;
  final bool isDesktop;

  const _DashboardBody({
    required this.data,
    required this.isDesktop,
  });

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nextLiveFeed = ref.watch(nextSessionFeedProvider).valueOrNull;

    final q = _searchQuery.toLowerCase().trim();
    final filteredClasses = q.isEmpty
        ? widget.data.classes
        : widget.data.classes.where((c) {
            final matchName = c.name.toLowerCase().contains(q);
            final matchPromo = c.promoTag.toLowerCase().contains(q);
            final matchSubject =
                c.subjects.any((s) => s.toLowerCase().contains(q));
            return matchName || matchPromo || matchSubject;
          }).toList();

    // Check if query triggers a quick tool shortcut suggestion
    Widget? quickShortcut;
    if (q.isNotEmpty) {
      if (q.contains('direct') ||
          q.contains('reunion') ||
          q.contains('visi') ||
          q.contains('live') ||
          q.contains('meet')) {
        quickShortcut = _SearchShortcutChip(
          icon: Icons.videocam_rounded,
          label: 'Directs & Réunions (LiveKit)',
          color: const Color(0xFFE11D48),
          onTap: () => context.push('/videoconference'),
        );
      } else if (q.contains('ia') ||
          q.contains('quiz') ||
          q.contains('plan') ||
          q.contains('crea') ||
          q.contains('gener')) {
        quickShortcut = _SearchShortcutChip(
          icon: Icons.auto_awesome_rounded,
          label: 'Créateur de cours IA',
          color: const Color(0xFF7C3AED),
          onTap: () => context.push('/courses/ai-create'),
        );
      } else if (q.contains('exam') ||
          q.contains('note') ||
          q.contains('devoir') ||
          q.contains('eval')) {
        quickShortcut = _SearchShortcutChip(
          icon: Icons.assignment_turned_in_rounded,
          label: 'Examens, Devoirs & Notes',
          color: const Color(0xFF059669),
          onTap: () => context.push('/exams'),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Search Bar (on mobile, mirrors web top search bar)
        if (!widget.isDesktop) ...[
          _TeacherSearchBar(
            controller: _searchCtrl,
            focusNode: _searchFocusNode,
            query: _searchQuery,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            onClear: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
            },
          ),
          if (quickShortcut != null) ...[
            const SizedBox(height: 8),
            quickShortcut,
          ],
          const SizedBox(height: 16),
        ],

        if (nextLiveFeed?.session != null) ...[
          () {
            final liveSession = nextLiveFeed!.session!;
            final phase = phaseOf(
              liveSession,
              DateTime.now(),
              serverOffset: nextLiveFeed.serverOffset,
            );
            final isEndedOrCanceled =
                liveSession.status == VideoSessionStatus.completed ||
                    liveSession.status == VideoSessionStatus.canceled ||
                    phase == SessionPhase.ended ||
                    phase == SessionPhase.canceled;

            if (isEndedOrCanceled) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TeacherImminentLiveCard(
                session: liveSession,
                serverOffset: nextLiveFeed.serverOffset,
              ),
            );
          }(),
        ],
        if (widget.data.nextSlot != null) ...[
          _NextSlotPill(slot: widget.data.nextSlot!),
          const SizedBox(height: 16),
        ],

        // KPI Stat Cards (Clickable to jump to classes/courses)
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.school_outlined,
                value: '${widget.data.classes.length}',
                labelKey: 'teacher_stat_classes',
                onTap: () => context.push('/groups'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.groups_outlined,
                value: '${widget.data.totalStudents}',
                labelKey: 'teacher_stat_students',
                onTap: () => context.push('/groups'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.book_outlined,
                value: '${widget.data.subjects.length}',
                labelKey: 'teacher_stat_subjects',
                onTap: () => context.push('/courses'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // AI Create Banner
        AiCreateBanner(
          onGenerate: () => context.push('/courses/ai-create'),
        ),
        const SizedBox(height: 20),

        // Quick Tools & Services Grid (Brings web sidebar 1-click tools to mobile)
        if (!widget.isDesktop) ...[
          _QuickToolsGrid(
            classesCount: widget.data.classes.length,
            onNewVirtualClass: () => _showCreateVirtualDialog(context, ref),
            onOpenCalendar: () => _showCalendarBottomSheet(
              context,
              widget.data.nextSlot,
              widget.data.classes,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Mes Classes Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('my_classes'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '${filteredClasses.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text('Classe'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  onPressed: () => _showCreateVirtualDialog(context, ref),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () => context.push('/groups'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Voir tout',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Classes List or Empty Search
        if (filteredClasses.isEmpty)
          _EmptySearchCard(
            query: _searchQuery,
            onReset: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
            },
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              if (!isWide || filteredClasses.length == 1) {
                return Column(
                  children: [
                    for (int i = 0; i < filteredClasses.length; i++) ...[
                      _TeacherClassCard(teacherClass: filteredClasses[i]),
                      if (i < filteredClasses.length - 1)
                        const SizedBox(height: 16),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final cls in filteredClasses)
                    SizedBox(
                      width: (constraints.maxWidth - 16) / 2,
                      child: _TeacherClassCard(teacherClass: cls),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}


part of '../pages/admin_planning_page.dart';

class _AdminPlanningPageState extends ConsumerState<AdminPlanningPage> {
  int _weekOffset = 0;
  int _selectedDay = 0;
  bool _classDefaulted = false;

  void _comingSoon() {
    context.showInfoToast(context.tr('feature_coming_soon'));
  }

  String _localeTag(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  /// Monday (YYYY-MM-DD) of the displayed week, driving the API call.
  String _weekStartFor(int offset) {
    final now = DateTime.now();
    final monday = now
        .subtract(Duration(days: now.weekday - 1))
        .add(Duration(days: offset * 7));
    return DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(monday.year, monday.month, monday.day));
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return const WebAdminPlanningView();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final classesAsync = ref.watch(adminClassesProvider);
    final classes = classesAsync.valueOrNull ?? const [];
    final selectedClassId = ref.watch(adminPlanningClassProvider);
    final computedWeekStart = _weekStartFor(_weekOffset);
    if (ref.watch(adminPlanningWeekStartProvider) != computedWeekStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminPlanningWeekStartProvider.notifier).state =
            computedWeekStart;
      });
    }
    if (!_classDefaulted && classes.isNotEmpty) {
      _classDefaulted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(adminPlanningClassProvider) == null) {
          ref.read(adminPlanningClassProvider.notifier).state =
              selectedClassId ?? classes.first.id;
        }
      });
    }
    final weekAsync = ref.watch(adminWeekScheduleProvider);
    final effectiveClassId =
        selectedClassId ?? (classes.isNotEmpty ? classes.first.id : null);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SMARTCLASS ADMIN',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.secondary,
                letterSpacing: 0.06,
              ),
            ),
            Text(
              context.tr('admin_timetable'),
              style: theme.textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_view_week_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              child: Icon(Icons.person_rounded, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminClassesProvider);
            ref.invalidate(adminWeekScheduleProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: context.screenWidth >= 600 ? 32 : 20,
              vertical: 8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: classesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Text(
                          context.tr('something_went_wrong'),
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(adminClassesProvider),
                          child: Text(context.tr('retry')),
                        ),
                      ],
                    ),
                  ),
                  data: (_) {
                    if (classes.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Text(
                          context.tr('admin_no_classes'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ClassSelector(
                          classes: classes,
                          selectedId: effectiveClassId,
                          onSelected: (id) => setState(() {
                            ref
                                    .read(adminPlanningClassProvider.notifier)
                                    .state =
                                id;
                            _selectedDay = 0;
                          }),
                        ),
                        const SizedBox(height: 12),
                        weekAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, _) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Text(
                                  context.tr('something_went_wrong'),
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () =>
                                      ref.invalidate(adminWeekScheduleProvider),
                                  child: Text(context.tr('retry')),
                                ),
                              ],
                            ),
                          ),
                          data: (week) {
                            if (week == null) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48,
                                ),
                                child: Text(
                                  context.tr('admin_no_timetable'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            AdminClassSummary? selectedClass;
                            for (final c in classes) {
                              if (c.id == effectiveClassId) {
                                selectedClass = c;
                                break;
                              }
                            }
                            return _PlanningBody(
                              week: week,
                              selectedClass: selectedClass,
                              weekOffset: _weekOffset,
                              selectedDay: _selectedDay,
                              localeTag: _localeTag(context),
                              onPrevWeek: () => setState(() => _weekOffset--),
                              onNextWeek: () => setState(() => _weekOffset++),
                              onToday: () => setState(() {
                                _weekOffset = 0;
                                _selectedDay = _todayIndex(week);
                              }),
                              onSelectDay: (i) =>
                                  setState(() => _selectedDay = i),
                              onTakeAttendance: _comingSoon,
                              onReserve: _comingSoon,
                              onNewSlot: _comingSoon,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _comingSoon,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('admin_new_slot')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  int _todayIndex(PlannerWeek week) {
    final idx = week.days.indexWhere((d) => d.isToday);
    return idx < 0 ? 0 : idx;
  }
}


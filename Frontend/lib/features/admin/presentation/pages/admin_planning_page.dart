import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/managed_class.dart';
import '../../domain/entities/timetable.dart';

class AdminPlanningPage extends ConsumerStatefulWidget {
  const AdminPlanningPage({super.key});

  @override
  ConsumerState<AdminPlanningPage> createState() => _AdminPlanningPageState();
}

class _AdminPlanningPageState extends ConsumerState<AdminPlanningPage> {
  int _weekOffset = 0;
  int _selectedDay = 0;
  bool _classDefaulted = false;

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('feature_coming_soon')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _localeTag(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  /// Monday (YYYY-MM-DD) of the displayed week, driving the API call.
  String _weekStartFor(int offset) {
    final now = DateTime.now();
    final monday = now
        .subtract(Duration(days: now.weekday - 1))
        .add(Duration(days: offset * 7));
    return DateFormat('yyyy-MM-dd')
        .format(DateTime(monday.year, monday.month, monday.day));
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(icon: const Icon(Icons.calendar_view_week_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.ios_share_outlined), onPressed: () {}),
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
                          onPressed: () =>
                              ref.invalidate(adminClassesProvider),
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
                                .state = id;
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
                                  onPressed: () => ref.invalidate(
                                      adminWeekScheduleProvider),
                                  child: Text(context.tr('retry')),
                                ),
                              ],
                            ),
                          ),
                          data: (week) {
                            if (week == null) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 48),
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

class _ClassSelector extends StatelessWidget {
  final List<AdminClassSummary> classes;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const _ClassSelector({
    required this.classes,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = classes.where((c) => c.id == selectedId);
    final label = selected.isEmpty ? classes.first.title : selected.first.title;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          final picked = await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (sheetContext) {
              final sheetTheme = Theme.of(sheetContext);
              return SafeArea(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: classes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    title: Text(classes[i].title,
                        style: sheetTheme.textTheme.bodyMedium),
                    subtitle: Text(classes[i].promoTag,
                        style: sheetTheme.textTheme.bodySmall),
                    trailing: classes[i].id == selectedId
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () =>
                        Navigator.of(sheetContext).pop(classes[i].id),
                  ),
                ),
              );
            },
          );
          if (picked != null) onSelected(picked);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.school_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.expand_more_rounded,
                  color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanningBody extends StatelessWidget {
  final PlannerWeek week;
  final AdminClassSummary? selectedClass;
  final int weekOffset;
  final int selectedDay;
  final String localeTag;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onToday;
  final ValueChanged<int> onSelectDay;
  final VoidCallback onTakeAttendance;
  final VoidCallback onReserve;
  final VoidCallback onNewSlot;

  const _PlanningBody({
    required this.week,
    required this.selectedClass,
    required this.weekOffset,
    required this.selectedDay,
    required this.localeTag,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onToday,
    required this.onSelectDay,
    required this.onTakeAttendance,
    required this.onReserve,
    required this.onNewSlot,
  });

  @override
  Widget build(BuildContext context) {
    final monday = week.monday.add(Duration(days: weekOffset * 7));
    final friday = monday.add(const Duration(days: 4));
    final range =
        '${DateFormat('d', localeTag).format(monday)} - ${DateFormat('d MMM y', localeTag).format(friday)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PromoCard(selectedClass: selectedClass),
        const SizedBox(height: 12),
        _WeekNavigator(
          range: range,
          onPrev: onPrevWeek,
          onNext: onNextWeek,
          onToday: onToday,
        ),
        const SizedBox(height: 12),
        _DayStrip(
          monday: monday,
          days: week.days,
          selectedDay: selectedDay,
          localeTag: localeTag,
          onSelect: onSelectDay,
        ),
        const SizedBox(height: 12),
        _WeekStats(
          hours: week.hoursScheduled,
          conflicts: week.conflicts,
        ),
        const SizedBox(height: 20),
        _DayTimeline(
          monday: monday,
          selectedDay: selectedDay,
          events: week.events,
          localeTag: localeTag,
          onTakeAttendance: onTakeAttendance,
          onReserve: onReserve,
        ),
        const SizedBox(height: 96),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final AdminClassSummary? selectedClass;

  const _PromoCard({required this.selectedClass});

  static String _levelLabel(BuildContext context, ClassLevel? level) {
    switch (level) {
      case ClassLevel.master:
        return context.tr('admin_filter_master');
      case ClassLevel.doctorat:
        return context.tr('admin_filter_doctorat');
      case ClassLevel.licence:
      case null:
        return context.tr('admin_filter_licence');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, size: 16, color: colorScheme.secondary),
              const SizedBox(width: 6),
              Text(
                context.tr('admin_active_promo').toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.secondary,
                  letterSpacing: 0.06,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list_rounded, size: 14, color: colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      _levelLabel(context, selectedClass?.level),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedClass?.title ?? '—',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _MetaChip(
                icon: Icons.groups_outlined,
                text:
                    '${selectedClass?.students ?? 0} ${context.tr('admin_stat_students')}',
              ),
              if ((selectedClass?.promoTag ?? '').isNotEmpty)
                _MetaChip(icon: null, text: selectedClass!.promoTag),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData? icon;
  final String text;

  const _MetaChip({this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  final String range;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const _WeekNavigator({
    required this.range,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrev,
          ),
          Text(range, style: theme.textTheme.labelLarge),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: onNext,
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: onToday,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  textStyle: theme.textTheme.labelSmall,
                ),
                child: Text(context.tr('admin_today').toUpperCase()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  final DateTime monday;
  final List<PlannerDay> days;
  final int selectedDay;
  final String localeTag;
  final ValueChanged<int> onSelect;

  const _DayStrip({
    required this.monday,
    required this.days,
    required this.selectedDay,
    required this.localeTag,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        for (int i = 0; i < days.length; i++) ...[
          Expanded(
            child: _DayCell(
              date: monday.add(Duration(days: i)),
              day: days[i],
              selected: i == selectedDay,
              localeTag: localeTag,
              colorScheme: colorScheme,
              theme: theme,
              onTap: () => onSelect(i),
            ),
          ),
          if (i < days.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final PlannerDay day;
  final bool selected;
  final String localeTag;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.day,
    required this.selected,
    required this.localeTag,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEE', localeTag).format(date).toUpperCase();
    final sub = context.tr('admin_day_courses', args: {'count': '${day.courseCount}'});

    return Material(
      color: selected ? colorScheme.primary : colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                dayName.length > 3 ? dayName.substring(0, 3) : dayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${date.day}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.onPrimary.withValues(alpha: 0.2)
                      : colorScheme.secondaryFixed,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  sub,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSecondaryFixed,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekStats extends StatelessWidget {
  final String hours;
  final int conflicts;

  const _WeekStats({required this.hours, required this.conflicts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget item(IconData icon, Color color, String text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          item(
            Icons.schedule_rounded,
            colorScheme.secondary,
            context.tr('admin_hours_scheduled', args: {'hours': hours}),
          ),
          item(
            conflicts == 0 ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
            conflicts == 0 ? colorScheme.tertiary : colorScheme.error,
            context.tr('admin_no_conflict', args: {'count': '$conflicts'}),
          ),
        ],
      ),
    );
  }
}

class _DayTimeline extends StatelessWidget {
  final DateTime monday;
  final int selectedDay;
  final List<PlannerEvent> events;
  final String localeTag;
  final VoidCallback onTakeAttendance;
  final VoidCallback onReserve;

  const _DayTimeline({
    required this.monday,
    required this.selectedDay,
    required this.events,
    required this.localeTag,
    required this.onTakeAttendance,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = monday.add(Duration(days: selectedDay));
    final dayKey = DateFormat('yyyy-MM-dd').format(date);
    final dayEvents =
        events.where((e) => e.date.isEmpty || e.date == dayKey).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.tr('admin_day_planning'),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            Text(
              DateFormat('EEEE d MMM', localeTag).format(date).toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (dayEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              context.tr('admin_no_timetable'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final event in dayEvents) ...[
            _TimelineRow(
              event: event,
              onTakeAttendance: onTakeAttendance,
              onReserve: onReserve,
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final PlannerEvent event;
  final VoidCallback onTakeAttendance;
  final VoidCallback onReserve;

  const _TimelineRow({
    required this.event,
    required this.onTakeAttendance,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (event.kind == PlannerEventKind.pause ||
        event.kind == PlannerEventKind.lunch) {
      return _BreakRow(event: event);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.start,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (event.end.isNotEmpty)
                Text(
                  event.end,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
        Container(
          width: 3,
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: event.kind == PlannerEventKind.free
              ? _FreeSlotCard(event: event, onReserve: onReserve)
              : _SessionCard(event: event, onTakeAttendance: onTakeAttendance),
        ),
      ],
    );
  }
}

class _BreakRow extends StatelessWidget {
  final PlannerEvent event;

  const _BreakRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.start,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (event.end.isNotEmpty)
                Text(
                  event.end,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Row(
            children: [
              Icon(
                event.kind == PlannerEventKind.lunch
                    ? Icons.restaurant_outlined
                    : Icons.local_cafe_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (event.noteDuration != null)
                Text(
                  event.noteDuration!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final PlannerEventKind kind;

  const _TypeChip({required this.kind});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (IconData icon, String labelKey) = switch (kind) {
      PlannerEventKind.cm => (Icons.auto_stories_outlined, 'admin_event_cm'),
      PlannerEventKind.tp => (Icons.terminal_rounded, 'admin_event_tp'),
      PlannerEventKind.td => (Icons.assignment_outlined, 'admin_event_td'),
      _ => (Icons.event_outlined, 'admin_event_cm'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.secondary),
          const SizedBox(width: 4),
          Text(
            context.tr(labelKey),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final PlannerEvent event;
  final VoidCallback onTakeAttendance;

  const _SessionCard({required this.event, required this.onTakeAttendance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TypeChip(kind: event.kind),
          const SizedBox(height: 8),
          Text(event.title, style: theme.textTheme.headlineSmall),
          if (event.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              event.subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (event.teacherName != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryFixed,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: event.teacherInitials == null
                      ? Icon(Icons.person_rounded,
                          size: 16, color: colorScheme.onSecondaryFixed)
                      : Text(
                          event.teacherInitials!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryFixed,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.teacherName!,
                        style: theme.textTheme.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.teacherRole != null)
                        Text(
                          event.teacherRole!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (event.roomValue != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.meeting_room_outlined,
                            size: 14, color: colorScheme.secondary),
                        Text(
                          event.roomValue!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (event.statusLines.isNotEmpty || event.statusNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final line in event.statusLines)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _StatusLine(textKey: line),
              ),
            for (final note in event.statusNotes)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _RawStatusLine(text: note),
              ),
          ],
          if (event.actionKey != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTakeAttendance,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr(event.actionKey!),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded,
                        size: 16, color: colorScheme.secondary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String textKey;

  const _StatusLine({required this.textKey});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (IconData icon, Color color) = switch (textKey) {
      'admin_confirmed_open' => (Icons.circle_outlined, theme.warningColor),
      'admin_session_validated' => (Icons.check_circle_outline_rounded, colorScheme.tertiary),
      'admin_group_full' => (Icons.group_outlined, colorScheme.onSurfaceVariant),
      'admin_hybrid_on' => (Icons.videocam_outlined, colorScheme.secondary),
      _ => (Icons.info_outline, colorScheme.onSurfaceVariant),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            context.tr(textKey),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _RawStatusLine extends StatelessWidget {
  final String text;

  const _RawStatusLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _FreeSlotCard extends StatelessWidget {
  final PlannerEvent event;
  final VoidCallback onReserve;

  const _FreeSlotCard({required this.event, required this.onReserve});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_available_outlined,
                      size: 16, color: colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('admin_free_slot'),
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
              if (event.noteDuration != null)
                Text(
                  event.noteDuration!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('admin_free_desc'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (event.roomValue != null)
                Text(
                  context.tr('admin_room_available',
                      args: {'room': event.roomValue!}),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.secondary,
                  ),
                )
              else
                const Spacer(),
              OutlinedButton.icon(
                onPressed: onReserve,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(context.tr('admin_book')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  textStyle: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

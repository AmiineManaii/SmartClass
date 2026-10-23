import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/admin_providers.dart';
import '../../domain/entities/timetable.dart';
import '../widgets/web_admin_scaffold.dart';

class WebAdminPlanningView extends ConsumerStatefulWidget {
  const WebAdminPlanningView({super.key});

  @override
  ConsumerState<WebAdminPlanningView> createState() =>
      _WebAdminPlanningViewState();
}

class _WebAdminPlanningViewState extends ConsumerState<WebAdminPlanningView> {
  int _weekOffset = 0;
  bool _classDefaulted = false;

  String _weekStartFor(int offset) {
    final now = DateTime.now();
    final monday = now
        .subtract(Duration(days: now.weekday - 1))
        .add(Duration(days: offset * 7));
    return DateFormat('yyyy-MM-dd')
        .format(DateTime(monday.year, monday.month, monday.day));
  }

  String _formatWeekRange(int offset) {
    final now = DateTime.now();
    final monday = now
        .subtract(Duration(days: now.weekday - 1))
        .add(Duration(days: offset * 7));
    final friday = monday.add(const Duration(days: 4));
    final f = DateFormat('dd MMM', 'fr');
    return '${f.format(monday)} – ${f.format(friday)} ${monday.year}';
  }

  Color _kindColor(PlannerEventKind kind) {
    switch (kind) {
      case PlannerEventKind.cm:
        return const Color(0xFF2563EB); // Blue
      case PlannerEventKind.td:
        return const Color(0xFF7C3AED); // Purple
      case PlannerEventKind.tp:
        return const Color(0xFF059669); // Emerald
      case PlannerEventKind.pause:
      case PlannerEventKind.lunch:
        return const Color(0xFFF59E0B); // Amber
      case PlannerEventKind.free:
        return const Color(0xFF64748B); // Slate
    }
  }

  String _kindLabel(PlannerEventKind kind) {
    switch (kind) {
      case PlannerEventKind.cm:
        return 'CM';
      case PlannerEventKind.td:
        return 'TD';
      case PlannerEventKind.tp:
        return 'TP';
      case PlannerEventKind.pause:
        return 'PAUSE';
      case PlannerEventKind.lunch:
        return context.tr('admin_planning_lunch');
      case PlannerEventKind.free:
        return 'LIBRE';
    }
  }

  void _showEventDialog(PlannerEvent event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kColor = _kindColor(event.kind);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _kindLabel(event.kind),
                style: TextStyle(
                  color: kColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.subtitle != null && event.subtitle!.isNotEmpty) ...[
              Text(
                event.subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFFCBD5E1) : AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  '${event.start} – ${event.end}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.meeting_room_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  event.roomValue ?? context.tr('admin_planning_room_undefined'),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            if (event.teacherName != null && event.teacherName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    event.teacherName!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

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
    final week = weekAsync.valueOrNull;

    return WebAdminScaffold(
      activePath: 'planning',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // 1. TOP HEADER & BREADCRUMBS
            // ==========================================
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              spacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('admin_planning_breadcrumb_cat'),
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      '  /  ',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF475569) : AppTheme.outlineVariant,
                      ),
                    ),
                    Text(
                      context.tr('admin_planning_breadcrumb_current'),
                      style: TextStyle(
                        color: isDark ? const Color(0xFFCBD5E1) : AppTheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(adminClassesProvider);
                    ref.invalidate(adminWeekScheduleProvider);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Actualiser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppTheme.primary,
                    backgroundColor: cardBg,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              runSpacing: 16,
              spacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('admin_planning_heading'),
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('admin_planning_sub'),
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AppTheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                // Week navigator
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () => setState(() => _weekOffset--),
                        tooltip: context.tr('admin_prev_week_tooltip'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          _formatWeekRange(_weekOffset),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : AppTheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () => setState(() => _weekOffset++),
                        tooltip: context.tr('admin_next_week_tooltip'),
                      ),
                      if (_weekOffset != 0)
                        TextButton(
                          onPressed: () => setState(() => _weekOffset = 0),
                          child: Text(context.tr('admin_today_btn')),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 2. CLASS SELECTOR TOOLBAR
            // ==========================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined,
                      size: 20, color: Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('admin_selected_class_label'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: effectiveClassId,
                        dropdownColor: cardBg,
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        isExpanded: true,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.primary,
                        ),
                        items: classes.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.id,
                            child: Text('${c.title} (${c.promoTag})'),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            ref
                                .read(adminPlanningClassProvider.notifier)
                                .state = id;
                          }
                        },
                      ),
                    ),
                  ),
                  if (week != null) ...[
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr('admin_hours_planned', args: {'hours': week.hoursScheduled.toString()}),
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 3. WEEKLY SCHEDULE GRID (5 DAYS COLUMN)
            // ==========================================
            weekAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: SmartLoader.medium()),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 36, color: AppTheme.error),
                      const SizedBox(height: 12),
                      Text(context.tr('admin_unable_load_planning')),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(adminWeekScheduleProvider),
                        child: Text(context.tr('retry')),
                      ),
                    ],
                  ),
                ),
              ),
              data: (plannerWeek) {
                if (plannerWeek == null || plannerWeek.days.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(
                        classes.isEmpty
                            ? context.tr('admin_first_create_class_planning')
                            : context.tr('admin_no_courses_this_week'),
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                final days = plannerWeek.days.take(5).toList();

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: days.map((day) {
                    final dayDateStr =
                        DateFormat('yyyy-MM-dd').format(day.date);
                    final dayEvents = plannerWeek.events
                        .where((e) => e.date == dayDateStr)
                        .toList();

                    final dayName = DateFormat('EEEE', 'fr').format(day.date);
                    final dayNum = DateFormat('d MMM', 'fr').format(day.date);

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: day.isToday
                                ? const Color(0xFF2563EB)
                                : borderColor,
                            width: day.isToday ? 1.8 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: isDark ? 0.3 : 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Column Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: day.isToday
                                    ? const Color(0xFF2563EB)
                                        .withValues(alpha: 0.12)
                                    : (isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC)),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    dayName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: day.isToday
                                          ? const Color(0xFF2563EB)
                                          : (isDark
                                              ? const Color(0xFFCBD5E1)
                                              : const Color(0xFF475569)),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dayNum,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : AppTheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: borderColor),

                            // Day slots
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: dayEvents.isEmpty
                                  ? Container(
                                      height: 140,
                                      alignment: Alignment.center,
                                      child: Text(
                                        context.tr('admin_no_courses_day'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : AppTheme.outline,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: dayEvents.map((evt) {
                                        final kColor = _kindColor(evt.kind);

                                        return InkWell(
                                          onTap: () => _showEventDialog(evt),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: kColor.withValues(
                                                  alpha: isDark ? 0.15 : 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: kColor.withValues(
                                                    alpha: 0.35),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      '${evt.start} – ${evt.end}',
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: kColor,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 5,
                                                          vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: kColor
                                                            .withValues(
                                                                alpha: 0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        _kindLabel(evt.kind),
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: kColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  evt.title,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? Colors.white
                                                        : AppTheme.onSurface,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (evt.roomValue != null &&
                                                    evt.roomValue!
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .meeting_room_outlined,
                                                        size: 12,
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF94A3B8)
                                                            : const Color(
                                                                0xFF64748B),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          evt.roomValue!,
                                                          style: TextStyle(
                                                            fontSize: 10.5,
                                                            color: isDark
                                                                ? const Color(
                                                                    0xFF94A3B8)
                                                                : const Color(
                                                                    0xFF64748B),
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

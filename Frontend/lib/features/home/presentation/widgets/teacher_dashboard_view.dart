import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/teacher_dashboard_provider.dart';
import '../../domain/entities/teacher_dashboard.dart';
import 'ai_create_banner.dart';
import 'teacher_greeting_header.dart';

/// Teacher home, fed only by the real API ([teacherDashboardProvider]:
/// own classes from `GET /groups/mine`, next session from their
/// timetables). A teacher with no class sees the contact-administration
/// notice — never invented stats, sessions or classes.
class TeacherDashboardView extends ConsumerWidget {
  const TeacherDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authStateProvider).valueOrNull;
    final dashboardAsync = ref.watch(teacherDashboardProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(teacherDashboardProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: context.screenWidth >= 600 ? 32 : 20,
              vertical: 8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopTitleRow(),
                    const SizedBox(height: 16),
                    TeacherGreetingHeader(user: user),
                    const SizedBox(height: 16),
                    dashboardAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => _DashboardError(
                        onRetry: () =>
                            ref.invalidate(teacherDashboardProvider),
                      ),
                      data: (data) => data.classes.isEmpty
                          ? const _NoClassNotice()
                          : _DashboardBody(data: data),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          context.tr('something_went_wrong'),
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(context.tr('retry')),
        ),
      ],
    );
  }
}

class _NoClassNotice extends StatelessWidget {
  const _NoClassNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.secondaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.co_present_outlined,
              color: colorScheme.onSecondaryFixed,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('teacher_no_class'),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('teacher_no_class_desc'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final TeacherDashboardData data;

  const _DashboardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.nextSlot != null) ...[
          _NextSlotPill(slot: data.nextSlot!),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.school_outlined,
                value: '${data.classes.length}',
                labelKey: 'teacher_stat_classes',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.groups_outlined,
                value: '${data.totalStudents}',
                labelKey: 'teacher_stat_students',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.book_outlined,
                value: '${data.subjects.length}',
                labelKey: 'teacher_stat_subjects',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AiCreateBanner(
          onGenerate: () => context.push('/courses/ai-create'),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  context.tr('my_classes'),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${data.classes.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/groups'),
              child: Text(
                context.tr('view_all_count',
                    args: {'count': '${data.classes.length}'}),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < data.classes.length; i++) ...[
          _TeacherClassCard(teacherClass: data.classes[i]),
          if (i < data.classes.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _NextSlotPill extends StatelessWidget {
  final TeacherNextSlot slot;

  const _NextSlotPill({required this.slot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => context.push('/videoconference'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.secondaryFixed.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.videocam_outlined,
                color: colorScheme.onSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('teacher_next_slot'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${slot.title} • ${slot.dayLabel} ${slot.start}'
                    '${slot.room != null ? ' • ${slot.room}' : ''}',
                    style: theme.textTheme.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    slot.className,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colorScheme.secondary),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String labelKey;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.labelKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.headlineSmall),
          Text(
            context.tr(labelKey),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TeacherClassCard extends StatelessWidget {
  final TeacherDashboardClass teacherClass;

  const _TeacherClassCard({required this.teacherClass});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              teacherClass.promoTag,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(teacherClass.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.groups_outlined,
                  size: 16, color: colorScheme.outline),
              const SizedBox(width: 6),
              Text(
                '${teacherClass.memberCount} ${context.tr('stat_students')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (teacherClass.subjects.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              context.tr('teacher_subjects_label'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final subject in teacherClass.subjects)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryFixed
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      subject,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryFixed,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (teacherClass.nextSessionLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule_outlined,
                    size: 16, color: colorScheme.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    teacherClass.nextSessionLabel!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TopTitleRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.school, color: colorScheme.onPrimary, size: 18),
            ),
            const SizedBox(width: 8),
            Column(
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
                  context.tr('home'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, color: colorScheme.onPrimary, size: 18),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../application/providers/teacher_dashboard_provider.dart';
import 'ai_create_banner.dart';
import 'live_session_pill.dart';
import 'teacher_class_card.dart';
import 'teacher_greeting_header.dart';
import 'teacher_stats_row.dart';

class TeacherDashboardView extends ConsumerWidget {
  const TeacherDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authStateProvider).value;
    final liveSession = ref.watch(teacherLiveSessionProvider);
    final stats = ref.watch(teacherStatsProvider);
    final classes = ref.watch(teacherClassesProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(teacherClassesProvider),
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
                    LiveSessionPill(
                      session: liveSession,
                      onTap: () => context.push('/videoconference'),
                    ),
                    const SizedBox(height: 16),
                    TeacherStatsRow(stats: stats),
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
                                color: colorScheme.surfaceContainerHigh,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${classes.length}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.push('/groups'),
                          child: Text(
                            context.tr('view_all_count', args: {'count': '4'}),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < classes.length; i++) ...[
                      TeacherClassCard(
                        teacherClass: classes[i],
                        onOpen: () => context.push('/groups'),
                        onHomework: () => context.push('/exams'),
                      ),
                      if (i < classes.length - 1) const SizedBox(height: 16),
                    ],
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

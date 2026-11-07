import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../admin/presentation/widgets/admin_dashboard_view.dart';
import '../widgets/missing_role_view.dart';
import '../widgets/student_dashboard_view.dart';
import '../widgets/teacher_dashboard_view.dart';
import '../widgets/welcome_section.dart';
import '../widgets/quick_actions.dart';
import '../widgets/upcoming_sessions.dart';
import '../widgets/recent_courses.dart';
import '../widgets/pending_tasks.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    // Backend is the source of truth for the role (TEACHER/STUDENT/ADMIN
    // lowercase in app). Null/empty means the onboarding role was never
    // persisted (legacy local-only flow) — send back to role-selection
    // instead of silently showing the student dashboard.
    final role = user?.role;

    if (role == null || role.isEmpty) {
      return MissingRoleView(authState: authState);
    }

    if (role == 'teacher') {
      return const TeacherDashboardView(key: ValueKey('teacher-dashboard'));
    }

    if (role == 'admin') {
      return const AdminDashboardView(key: ValueKey('admin-dashboard'));
    }

    if (role == 'student') {
      return const StudentDashboardView(key: ValueKey('student-dashboard'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${context.tr('home')} • ${_getRoleDisplayName(role)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WelcomeSection(user: user),
                    const SizedBox(height: 24),
                    QuickActions(role: role),
                    const SizedBox(height: 24),
                    const UpcomingSessions(),
                    const SizedBox(height: 24),
                    const RecentCourses(),
                    const SizedBox(height: 24),
                    PendingTasks(role: role),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'teacher':
        return 'Enseignant';
      case 'admin':
        return 'Administrateur';
      default:
        return 'Étudiant';
    }
  }
}

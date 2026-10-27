import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/typography/typography_provider.dart';
import '../core/typography/typography_config.dart';
import '../core/constants/app_constants.dart';
import '../core/error/failures.dart';
import '../core/network/network_providers.dart';
import '../features/authentication/application/providers/auth_repository_provider.dart';
import '../features/authentication/domain/entities/user_entity.dart';
import '../features/authentication/domain/repositories/auth_repository.dart';
import '../features/authentication/presentation/pages/forgot_password_page.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/authentication/presentation/pages/profile_setup_page.dart';
import '../features/authentication/presentation/pages/register_page.dart';
import '../features/authentication/presentation/pages/reset_password_page.dart';
import '../features/authentication/presentation/pages/role_selection_page.dart';
import '../features/authentication/presentation/pages/verify_email_page.dart';
import '../features/courses/presentation/pages/ai_course_creator_page.dart';
import '../features/courses/presentation/pages/course_reader_page.dart';
import '../features/courses/presentation/pages/course_section_builder_page.dart';
import '../features/courses/presentation/pages/courses_page.dart';
import '../features/groups/presentation/pages/groups_page.dart';
import '../features/groups/presentation/pages/class_detail_page.dart';
import '../features/exams/presentation/pages/exams_page.dart';
import '../features/exams/presentation/pages/secure_exam_page.dart';
import '../features/exams/presentation/pages/exam_ai_score_page.dart';
import '../features/videoconference/presentation/pages/videoconference_page.dart';
import '../features/videoconference/presentation/pages/lobby_page.dart';
import '../features/videoconference/presentation/pages/live_room_page.dart';
import '../features/collaboration/presentation/pages/collaboration_page.dart'
    as collaboration_page;
import '../features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../features/ai_assistant/presentation/pages/ai_revision_page.dart';
import '../features/ai_assistant/presentation/pages/ai_quiz_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/admin/presentation/pages/admin_classes_page.dart';
import '../features/admin/presentation/pages/admin_students_page.dart';
import '../features/admin/presentation/pages/admin_teachers_page.dart';
import '../features/admin/presentation/pages/admin_frauds_page.dart';
import '../features/admin/presentation/pages/admin_planning_page.dart';
import '../features/admin/presentation/pages/class_create_page.dart';
import '../features/admin/presentation/pages/class_students_page.dart';
import '../features/admin/presentation/pages/class_teachers_page.dart';
import '../core/widgets/web_main_scaffold.dart';
import '../features/courses/presentation/widgets/global_ai_plan_progress_bar.dart';

/// Notifier stable qui force GoRouter à réévaluer `redirect`
/// sans recréer l'instance (sinon la navigation est réinitialisée).
class AuthRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final authRefreshProvider = Provider<AuthRefreshNotifier>((ref) {
  return AuthRefreshNotifier();
});

final hasSeenSplashProvider = StateProvider<bool>((ref) => false);
final pendingEmailProvider = StateProvider<String?>((ref) => null);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(authRefreshProvider);
  final hasSeenSplash = ref.watch(hasSeenSplashProvider);

  return GoRouter(
    initialLocation: hasSeenSplash ? '/home' : '/splash',
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // 1. Splash screen obligatoire UNIQUEMENT au tout premier lancement mobile (cold start)
      if (!hasSeenSplash) {
        if (location == '/splash' || location == '/') return null;
        if (kIsWeb) return null;
        return '/splash';
      }

      final authAsync = ProviderScope.containerOf(
        context,
      ).read(authStateProvider);
      // Ne jamais rediriger vers /login si la session est en cours de restauration ou de chargement
      if (authAsync.isLoading) {
        return null;
      }
      final auth = authAsync.valueOrNull;
      final isLoggedIn = auth?.isAuthenticated ?? false;
      final completed = auth?.onboardingCompleted ?? false;

      // Si l'utilisateur tente d'aller manuellement sur /splash après l'avoir terminé
      if (location == '/splash') {
        return completed
            ? '/home'
            : (isLoggedIn ? '/role-selection' : '/login');
      }

      final isPublicRoute =
          location.startsWith('/login') ||
          location.startsWith('/register') ||
          location.startsWith('/forgot-password') ||
          location.startsWith('/reset-password');
      final isOnboardingRoute =
          location.startsWith('/role-selection') ||
          location.startsWith('/profile-setup') ||
          location.startsWith('/verify-email');

      if (!isLoggedIn) {
        if (isPublicRoute || isOnboardingRoute) return null;
        return '/login';
      }

      if (isPublicRoute) {
        return completed ? '/home' : '/role-selection';
      }

      if (location == '/') {
        return completed ? '/home' : '/role-selection';
      }

      if (!completed) {
        if (isOnboardingRoute) {
          if (location.startsWith('/profile-setup') && auth?.role == null) {
            return '/role-selection';
          }
          return null;
        }
        return auth?.role == null ? '/role-selection' : '/profile-setup';
      }

      if (isOnboardingRoute) return '/home';

      final normalizedRole = auth?.role?.toLowerCase();
      if (location.startsWith('/admin') && normalizedRole != 'admin') {
        return '/home';
      }

      if ((location.startsWith('/courses/ai-create') ||
              location.endsWith('/build')) &&
          normalizedRole != 'teacher' &&
          normalizedRole != 'admin') {
        return '/courses';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return VerifyEmailPage(email: email);
        },
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupPage(),
      ),
      // Fullscreen (outside the shell): generate → validate every section
      // of one draft before it can be published (RG4/RG27).
      GoRoute(
        path: '/courses/:courseId/build',
        name: 'course-section-build',
        builder: (context, state) => CourseSectionBuilderPage(
          courseId: state.pathParameters['courseId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/ai-revision',
        name: 'ai-revision',
        builder: (context, state) => const AiRevisionPage(),
      ),
      GoRoute(
        path: '/ai-quiz',
        name: 'ai-quiz',
        builder: (context, state) => const AiQuizPage(),
      ),
      GoRoute(
        path: '/exams/secure-session',
        name: 'secure-exam-session',
        builder: (context, state) => const SecureExamPage(),
      ),
      GoRoute(
        path: '/exams/ai-score',
        name: 'exam-ai-score',
        builder: (context, state) => const ExamAiScorePage(),
      ),
      GoRoute(
        path: '/videoconference/:sessionId/lobby',
        name: 'videoconference-lobby',
        builder: (context, state) => LobbyPage(
          sessionId: state.pathParameters['sessionId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/videoconference/:sessionId/room',
        name: 'videoconference-room',
        builder: (context, state) {
          final micParam = state.uri.queryParameters['mic'];
          final camParam = state.uri.queryParameters['cam'];
          final extra = state.extra as Map<String, dynamic>?;

          final initialMic = extra?['initialMic'] as bool? ??
              (micParam != null ? micParam == 'true' : null);
          final initialCamera = extra?['initialCamera'] as bool? ??
              (camParam != null ? camParam == 'true' : null);

          return LiveRoomPage(
            sessionId: state.pathParameters['sessionId'] ?? '',
            initialMic: initialMic,
            initialCamera: initialCamera,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/courses',
            name: 'courses',
            builder: (context, state) => const CoursesPage(),
          ),
          GoRoute(
            path: '/courses/ai-create',
            name: 'ai-create-course',
            builder: (context, state) => const AiCourseCreatorPage(),
          ),
          GoRoute(
            path: '/courses/:courseId',
            name: 'course-reader',
            builder: (context, state) => CourseReaderPage(
              courseId: state.pathParameters['courseId'] ?? '',
            ),
          ),
          GoRoute(
            path: '/groups',
            name: 'groups',
            builder: (context, state) => const GroupsPage(),
          ),
          GoRoute(
            path: '/groups/:groupId',
            name: 'group-detail',
            builder: (context, state) => ClassDetailPage(
              groupId: state.pathParameters['groupId'] ?? '',
              initialTitle: state.extra is String
                  ? state.extra as String
                  : null,
            ),
          ),
          GoRoute(
            path: '/exams',
            name: 'exams',
            builder: (context, state) => const ExamsPage(),
          ),
          GoRoute(
            path: '/videoconference',
            name: 'videoconference',
            builder: (context, state) => const VideoconferencePage(),
          ),
          GoRoute(
            path: '/collaboration',
            name: 'collaboration',
            builder: (context, state) =>
                const collaboration_page.CollaborationPage(),
          ),
          GoRoute(
            path: '/ai-assistant',
            name: 'ai-assistant',
            builder: (context, state) => const AiAssistantPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/admin/classes',
            name: 'admin-classes',
            builder: (context, state) => const AdminClassesPage(),
          ),
          GoRoute(
            path: '/admin/teachers',
            name: 'admin-teachers',
            builder: (context, state) => const AdminTeachersPage(),
          ),
          GoRoute(
            path: '/admin/students',
            name: 'admin-students',
            builder: (context, state) => const AdminStudentsPage(),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'admin-users',
            builder: (context, state) => const AdminStudentsPage(),
          ),
          GoRoute(
            path: '/admin/classes/new',
            name: 'admin-class-new',
            builder: (context, state) => ClassCreatePage(
              editClassId: state.extra is String ? state.extra as String : null,
            ),
          ),
          GoRoute(
            path: '/admin/classes/:classId/students',
            name: 'admin-class-students',
            builder: (context, state) => ClassStudentsPage(
              classId: state.pathParameters['classId'] ?? '',
            ),
          ),
          GoRoute(
            path: '/admin/classes/:classId/teachers',
            name: 'admin-class-teachers',
            builder: (context, state) => ClassTeachersPage(
              classId: state.pathParameters['classId'] ?? '',
            ),
          ),
          GoRoute(
            path: '/admin/planning',
            name: 'admin-planning',
            builder: (context, state) => const AdminPlanningPage(),
          ),
          GoRoute(
            path: '/admin/frauds',
            name: 'admin-frauds',
            builder: (context, state) => const AdminFraudsPage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('not_found'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: Text(context.tr('home')),
            ),
          ],
        ),
      ),
    ),
  );
});

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final role = ref.watch(authStateProvider).valueOrNull?.role;

    if (isDesktop) {
      return WebMainScaffold(body: child, role: role);
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: isDesktop ? null : const _BottomNavBar(),
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final role = ref.watch(authStateProvider).valueOrNull?.role?.toLowerCase();

    // Role-specific mobile navigation tabs (always providing Directs / Visioconférence).
    final List<_NavItem> items;
    if (role == 'admin') {
      items = const [
        _NavItem(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          labelKey: 'admin_tab_dashboard',
          route: '/home',
        ),
        _NavItem(
          icon: Icons.school_outlined,
          selectedIcon: Icons.school_rounded,
          labelKey: 'admin_tab_classes',
          route: '/admin/classes',
        ),
        _NavItem(
          icon: Icons.videocam_outlined,
          selectedIcon: Icons.videocam_rounded,
          labelKey: 'nav_live_meetings',
          route: '/videoconference',
          isLivePill: true,
        ),
        _NavItem(
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month_rounded,
          labelKey: 'admin_tab_planning',
          route: '/admin/planning',
        ),
        _NavItem(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_rounded,
          labelKey: 'settings',
          route: '/settings',
        ),
      ];
    } else if (role == 'teacher') {
      items = const [
        _NavItem(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          labelKey: 'home',
          route: '/home',
        ),
        _NavItem(
          icon: Icons.school_outlined,
          selectedIcon: Icons.school_rounded,
          labelKey: 'nav_my_classes',
          route: '/groups',
        ),
        _NavItem(
          icon: Icons.videocam_outlined,
          selectedIcon: Icons.videocam_rounded,
          labelKey: 'nav_live_meetings',
          route: '/videoconference',
          isLivePill: true,
        ),
        _NavItem(
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book_rounded,
          labelKey: 'nav_courses_resources',
          route: '/courses',
        ),
        _NavItem(
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          labelKey: 'profile',
          route: '/profile',
        ),
      ];
    } else {
      // Student navigation
      items = const [
        _NavItem(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          labelKey: 'home',
          route: '/home',
        ),
        _NavItem(
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book_rounded,
          labelKey: 'nav_my_courses',
          route: '/courses',
        ),
        _NavItem(
          icon: Icons.videocam_outlined,
          selectedIcon: Icons.videocam_rounded,
          labelKey: 'nav_live_meetings',
          route: '/videoconference',
          isLivePill: true,
        ),
        _NavItem(
          icon: Icons.auto_awesome_rounded,
          selectedIcon: Icons.auto_awesome_rounded,
          labelKey: 'ai_tutor',
          route: '/ai-assistant',
          isAiPill: true,
        ),
        _NavItem(
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          labelKey: 'profile',
          route: '/profile',
        ),
      ];
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFF0F172A))
                    .withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.map((item) {
              final isSelected = item.route == '/home'
                  ? (location == '/home' || location == '/')
                  : location.startsWith(item.route);

              final rawLabel = context.tr(item.labelKey);

              return Expanded(
                child: Center(
                  child: Tooltip(
                    message: rawLabel,
                    child: InkWell(
                      onTap: () => context.go(item.route),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        width: isSelected ? 48 : 42,
                        height: isSelected ? 48 : 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isSelected
                              ? (item.isAiPill
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF4F46E5),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : (item.isLivePill
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFEF4444),
                                            Color(0xFFDC2626),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: isDark
                                              ? const [
                                                  Color(0xFF3B82F6),
                                                  Color(0xFF1D4ED8),
                                                ]
                                              : const [
                                                  Color(0xFF1E3A8A),
                                                  Color(0xFF122675),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )))
                              : null,
                          color: !isSelected
                              ? (item.isAiPill
                                  ? (isDark
                                      ? const Color(0xFF312E81).withValues(alpha: 0.3)
                                      : const Color(0xFFEEF2FF))
                                  : (item.isLivePill
                                      ? (isDark
                                          ? const Color(0xFF881337).withValues(alpha: 0.3)
                                          : const Color(0xFFFFF1F2))
                                      : Colors.transparent))
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (item.isAiPill
                                            ? const Color(0xFF6366F1)
                                            : (item.isLivePill
                                                ? const Color(0xFFEF4444)
                                                : (isDark
                                                    ? const Color(0xFF3B82F6)
                                                    : const Color(0xFF122675))))
                                        .withValues(alpha: isDark ? 0.45 : 0.30),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? Colors.white
                                  : (item.isAiPill
                                      ? const Color(0xFF6366F1)
                                      : (item.isLivePill
                                          ? const Color(0xFFEF4444)
                                          : (isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B)))),
                            ),
                            if (!isSelected && item.isLivePill)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;
  final String route;
  final bool isAiPill;
  final bool isLivePill;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
    required this.route,
    this.isAiPill = false,
    this.isLivePill = false,
  });
}

class AppProviders extends ConsumerWidget {
  final Widget child;

  const AppProviders({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final typographyConfig = ref.watch(typographyConfigProvider);

    final config = typographyConfig.valueOrNull ?? const TypographyConfig();

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(ref.watch(localeProvider)),
      theme: AppTheme.getLightTheme(AppTextStyles(config)),
      darkTheme: AppTheme.getDarkTheme(AppTextStyles(config)),
      themeMode: ref.watch(themeModeProvider),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(config.textScaleFactor)),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const GlobalAiPlanProgressBar(),
            ],
          ),
        );
      },
    );
  }
}

final localeProvider = StateProvider<String>(
  (ref) => AppConstants.defaultLanguageCode,
);

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Values that older builds pre-filled in the academic profile form.
/// They are not real user data, so they must never be displayed as if they
/// were the user's institution.
const _legacyMockInstitutions = <String>{
  'Université Mohammed V de Rabat',
  'Université Mohammed V de Rabat - Faculté des Sciences',
  'Université Mohammed VI Polytechnique',
  'Institut Supérieur / Université',
};

String? sanitizeInstitution(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (_legacyMockInstitutions.contains(trimmed)) return null;
  return trimmed;
}

@immutable
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? role;
  final String? email;
  final String? displayName;
  final bool emailVerified;
  final bool onboardingCompleted;
  final String? institution;
  final String? faculty;
  final String? major;
  final String? studentId;
  final String? bio;
  final bool twoFactorEnabled;

  String get status => emailVerified ? 'ACTIVE' : 'PENDING_VERIFICATION';
  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.role,
    this.email,
    this.displayName,
    this.emailVerified = false,
    this.onboardingCompleted = false,
    this.institution,
    this.faculty,
    this.major,
    this.studentId,
    this.bio,
    this.twoFactorEnabled = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? role,
    String? email,
    String? displayName,
    bool? emailVerified,
    bool? onboardingCompleted,
    String? institution,
    String? faculty,
    String? major,
    String? studentId,
    String? bio,
    bool? twoFactorEnabled,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      emailVerified: emailVerified ?? this.emailVerified,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      institution: institution ?? this.institution,
      faculty: faculty ?? this.faculty,
      major: major ?? this.major,
      studentId: studentId ?? this.studentId,
      bio: bio ?? this.bio,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>((ref) {
      final refresher = ref.watch(authRefreshProvider);
      final notifier = AuthNotifier(ref, onChanged: refresher.refresh);
      // Session expiry surfaced by ApiClient (e.g. refresh-token reuse) logs out.
      ref.read(apiClientProvider).onUnauthorized = notifier.expireSession;
      return notifier;
    });

/// Orchestrates the real auth API ([AuthRepository]).
/// Throws [Failure] on error — pages catch it to show localized messages
/// and skip navigation (see `failureL10n`).
class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  AuthNotifier(this._ref, {required this.onChanged})
    : super(const AsyncValue.loading()) {
    _restoreSession();
  }

  final Ref _ref;
  final VoidCallback onChanged;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  void _emit(AsyncValue<AuthState> next, {bool forceNotifyRouter = false}) {
    final prev = state.valueOrNull;
    state = next;
    final curr = next.valueOrNull;
    if (forceNotifyRouter ||
        prev?.isAuthenticated != curr?.isAuthenticated ||
        prev?.role != curr?.role ||
        prev?.onboardingCompleted != curr?.onboardingCompleted) {
      onChanged();
    }
  }

  AuthState _fromUser(
    UserEntity user, {
    required bool authenticated,
    String? institution,
    String? faculty,
    String? major,
    String? studentId,
    String? bio,
    AuthState? previousState,
  }) {
    final prev = previousState ?? state.valueOrNull;
    final currentRole = (user.role != null && user.role!.isNotEmpty)
        ? user.role
        : prev?.role;
    final currentInst = institution ?? prev?.institution;
    final currentFaculty = faculty ?? prev?.faculty;
    final currentMajor = major ?? prev?.major;
    final currentStudentId = studentId ?? prev?.studentId;
    final currentBio = bio ?? prev?.bio;

    return AuthState(
      isAuthenticated: authenticated,
      userId: user.id.isEmpty ? null : user.id,
      email: user.email.isEmpty ? null : user.email,
      role: currentRole,
      displayName: user.displayName.isEmpty ? null : user.displayName,
      emailVerified: user.emailVerified,
      onboardingCompleted: user.onboardingCompleted,
      institution: sanitizeInstitution(currentInst),
      faculty: currentFaculty,
      major: currentMajor,
      studentId: currentStudentId,
      bio: currentBio,
      twoFactorEnabled: user.twoFactorEnabled,
    );
  }

  Future<void> _restoreSession() async {
    final tokens = _ref.read(tokenStorageProvider);
    final refreshToken = await tokens.readRefreshToken();

    // 1. First attempt: validate active session using current tokens / cookies
    try {
      final user = await _repo.getMe();
      final profile = await tokens.readAcademicProfile(
        user.id.isNotEmpty ? user.id : user.email,
      );
      _emit(
        AsyncValue.data(
          _fromUser(
            user,
            authenticated: true,
            institution: profile['institution'],
            faculty: profile['faculty'],
            major: profile['major'],
            studentId: profile['studentId'],
            bio: profile['bio'],
          ),
        ),
      );
      return;
    } catch (_) {
      // Access token may be expired or absent; proceed to refresh if available
    }

    // 2. Second attempt: rotate session using refresh token if present
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _repo.refreshSession(refreshToken: refreshToken);
        final user = await _repo.getMe();
        final profile = await tokens.readAcademicProfile(
          user.id.isNotEmpty ? user.id : user.email,
        );
        _emit(
          AsyncValue.data(
            _fromUser(
              user,
              authenticated: true,
              institution: profile['institution'],
              faculty: profile['faculty'],
              major: profile['major'],
              studentId: profile['studentId'],
              bio: profile['bio'],
            ),
          ),
        );
        return;
      } catch (_) {
        // Refresh token failed or expired: clear stale tokens
        await tokens.clear(keepSavedEmail: true);
      }
    }

    // 3. No valid session found
    _emit(const AsyncValue.data(AuthState()));
  }

  /// Called by [ApiClient] when the session can no longer be refreshed.
  void expireSession() {
    _emit(const AsyncValue.data(AuthState()));
  }

  Future<void> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    _ref.read(pendingEmailProvider.notifier).state = email;
    _emit(const AsyncValue.loading());
    try {
      final session = await _repo.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      final tokens = _ref.read(tokenStorageProvider);
      final profile = await tokens.readAcademicProfile(
        session.user.id.isNotEmpty ? session.user.id : email,
      );
      _emit(
        AsyncValue.data(
          _fromUser(
            session.user,
            authenticated: true,
            institution: profile['institution'],
            faculty: profile['faculty'],
            major: profile['major'],
            studentId: profile['studentId'],
            bio: profile['bio'],
          ),
        ),
      );
    } catch (e) {
      _emit(AsyncValue.error(e, StackTrace.current));
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? role,
  }) async {
    _ref.read(pendingEmailProvider.notifier).state = email;
    _emit(const AsyncValue.loading());
    try {
      final fallback = email.split('@').first;
      final result = await _repo.register(
        email: email,
        password: password,
        firstName: (firstName == null || firstName.isEmpty)
            ? fallback
            : firstName,
        lastName: (lastName == null || lastName.isEmpty)
            ? ((firstName == null || firstName.isEmpty) ? fallback : firstName)
            : lastName,
        role: role,
      );
      // No tokens are issued until email verification: local session only.
      _emit(
        AsyncValue.data(
          _fromUser(
            result.user.copyWith(role: () => role),
            authenticated: true,
          ),
        ),
      );
    } catch (e) {
      _emit(AsyncValue.error(e, StackTrace.current));
      rethrow;
    }
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    _emit(const AsyncValue.loading());
    try {
      final session = await _repo.verifyEmail(email: email, code: code);
      _emit(AsyncValue.data(_fromUser(session.user, authenticated: true)));
    } catch (e) {
      _emit(AsyncValue.error(e, StackTrace.current));
      rethrow;
    }
  }

  /// Live email-availability check for the registration form.
  /// Intentionally does NOT touch global auth state (no `_emit`):
  /// it is a background validation, failures propagate as [Failure].
  Future<bool> checkEmailAvailability(String email) {
    return _repo.checkEmailAvailability(email: email);
  }

  Future<void> resendVerification({required String email}) {
    return _repo.resendVerification(email: email);
  }

  Future<void> forgotPassword({required String email}) {
    return _repo.forgotPassword(email: email);
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _repo.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  Future<void> logout() async {
    final tokens = _ref.read(tokenStorageProvider);
    final refresh = await tokens.readRefreshToken();
    try {
      await _repo.logout(refreshToken: refresh);
    } finally {
      await tokens.clear(keepSavedEmail: true);
      _emit(const AsyncValue.data(AuthState()));
    }
  }

  /// PATCH firstName/lastName on the backend (email is immutable server-side).
  Future<void> updateProfile({String? firstName, String? lastName}) async {
    final current = state.value;
    if (current == null || !current.isAuthenticated) return;
    try {
      final user = await _repo.updateProfile(
        firstName: firstName,
        lastName: lastName,
      );
      _emit(
        AsyncValue.data(
          _fromUser(user, authenticated: true, previousState: current),
        ),
      );
    } catch (e) {
      _emit(AsyncValue.data(current));
      rethrow;
    }
  }

  /// Persists the onboarding role via `PATCH /users/me/role` (RG1, once-only).
  /// Backend is the source of truth: the returned session (fresh tokens
  /// embedding the role) replaces the local state.
  /// ADMIN is never self-assignable — throws [Failure] (403) in that case.
  /// If the role was already assigned (409 ROLE_ALREADY_ASSIGNED),
  /// resyncs from `GET /auth/me` instead of failing the onboarding.
  Future<void> updateRole(String role) async {
    final normalized = role.toLowerCase();
    if (normalized == 'admin') {
      throw const AuthFailure(
        'Administrator accounts must be provisioned by an existing administrator',
        code: 'FORBIDDEN',
      );
    }
    final current = state.value;
    _emit(const AsyncValue.loading());
    try {
      final session = await _repo.setMyRole(role: normalized);
      _emit(
        AsyncValue.data(
          _fromUser(session.user, authenticated: true, previousState: current),
        ),
      );
    } catch (e) {
      // Role already set server-side: resync from the backend (source of
      // truth). Only swallow the error when the synced role matches the
      // request (e.g. retry after the app was killed post-success) —
      // otherwise surface it so the user isn't sent to the wrong dashboard.
      try {
        final user = await _repo.getMe();
        final synced = _fromUser(
          user,
          authenticated: true,
          previousState: current,
        );
        _emit(AsyncValue.data(synced));
        if (synced.role == normalized) return;
      } catch (_) {
        // Fall through to restore previous state below.
      }
      if (current != null) {
        _emit(AsyncValue.data(current));
      } else {
        _emit(AsyncValue.error(e, StackTrace.current));
      }
      rethrow;
    }
  }

  Future<void> completeProfile({
    String? institution,
    String? faculty,
    String? major,
    String? studentId,
    String? bio,
  }) async {
    final current = state.value;
    if (current == null || !current.isAuthenticated) return;

    final tokens = _ref.read(tokenStorageProvider);
    final userKey = current.userId ?? current.email;
    await tokens.saveAcademicProfile(
      userIdOrEmail: userKey,
      institution: institution,
      faculty: faculty,
      major: major,
      studentId: studentId,
      bio: bio,
    );

    try {
      final user = await _repo.updateProfile(onboardingCompleted: true);
      _emit(
        AsyncValue.data(
          _fromUser(
            user,
            authenticated: true,
            institution: institution ?? current.institution,
            faculty: faculty ?? current.faculty,
            major: major ?? current.major,
            studentId: studentId ?? current.studentId,
            bio: bio ?? current.bio,
          ),
        ),
      );
    } catch (_) {
      // Offline-tolerant onboarding: validated locally, synced later.
      _emit(
        AsyncValue.data(
          current.copyWith(
            onboardingCompleted: true,
            institution: sanitizeInstitution(
              institution ?? current.institution,
            ),
            faculty: faculty ?? current.faculty,
            major: major ?? current.major,
            studentId: studentId ?? current.studentId,
            bio: bio ?? current.bio,
          ),
        ),
      );
    }
  }

  Future<void> updateAcademicProfile({
    String? institution,
    String? faculty,
    String? major,
    String? studentId,
    String? bio,
  }) async {
    final current = state.value;
    if (current == null) return;

    final tokens = _ref.read(tokenStorageProvider);
    final userKey = current.userId ?? current.email;
    await tokens.saveAcademicProfile(
      userIdOrEmail: userKey,
      institution: institution,
      faculty: faculty,
      major: major,
      studentId: studentId,
      bio: bio,
    );

    _emit(
      AsyncValue.data(
        current.copyWith(
          institution: sanitizeInstitution(institution ?? current.institution),
          faculty: faculty ?? current.faculty,
          major: major ?? current.major,
          studentId: studentId ?? current.studentId,
          bio: bio ?? current.bio,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> setup2fa() {
    return _repo.setup2fa();
  }

  Future<void> verify2fa(String code) async {
    final success = await _repo.verify2fa(code: code);
    if (success) {
      final current = state.valueOrNull;
      if (current != null) {
        _emit(AsyncValue.data(current.copyWith(twoFactorEnabled: true)));
      }
    }
  }

  Future<void> disable2fa({String? code, String? password}) async {
    final success = await _repo.disable2fa(code: code, password: password);
    if (success) {
      final current = state.valueOrNull;
      if (current != null) {
        _emit(AsyncValue.data(current.copyWith(twoFactorEnabled: false)));
      }
    }
  }

  Future<void> authenticate2fa({
    required String tempToken,
    required String code,
    bool rememberMe = false,
  }) async {
    _emit(const AsyncValue.loading());
    try {
      final session = await _repo.authenticate2fa(
        tempToken: tempToken,
        code: code,
        rememberMe: rememberMe,
      );
      final tokens = _ref.read(tokenStorageProvider);
      final profile = await tokens.readAcademicProfile(
        session.user.id.isNotEmpty ? session.user.id : session.user.email,
      );
      _emit(
        AsyncValue.data(
          _fromUser(
            session.user,
            authenticated: true,
            institution: profile['institution'],
            faculty: profile['faculty'],
            major: profile['major'],
            studentId: profile['studentId'],
            bio: profile['bio'],
          ),
        ),
      );
    } catch (e) {
      _emit(AsyncValue.error(e, StackTrace.current));
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 20}) {
    return _repo.getAuditLogs(limit: limit);
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<List<Map<String, dynamic>>> getSessions() {
    return _repo.getSessions();
  }

  Future<void> revokeSession(String sessionId) {
    return _repo.revokeSession(sessionId);
  }

  Future<void> revokeAllOtherSessions() {
    return _repo.revokeAllOtherSessions();
  }

  Future<String> freezeAccount() async {
    final tokens = _ref.read(tokenStorageProvider);
    try {
      final msg = await _repo.freezeAccount();
      return msg;
    } finally {
      await tokens.clear(keepSavedEmail: true);
      _emit(const AsyncValue.data(AuthState()));
    }
  }

  Future<String> deleteAccount({required String passwordConfirmation}) async {
    final tokens = _ref.read(tokenStorageProvider);
    try {
      final msg = await _repo.deleteAccount(
        passwordConfirmation: passwordConfirmation,
      );
      return msg;
    } finally {
      await tokens.clear(keepSavedEmail: false);
      _emit(const AsyncValue.data(AuthState()));
    }
  }
}

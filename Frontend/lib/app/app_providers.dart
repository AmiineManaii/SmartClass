import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/typography/typography_provider.dart';
import '../core/typography/typography_config.dart';
import '../core/constants/app_constants.dart';
import '../features/authentication/presentation/pages/forgot_password_page.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/authentication/presentation/pages/profile_setup_page.dart';
import '../features/authentication/presentation/pages/register_page.dart';
import '../features/authentication/presentation/pages/role_selection_page.dart';
import '../features/courses/presentation/pages/ai_course_creator_page.dart';
import '../features/courses/presentation/pages/courses_page.dart';
import '../features/groups/presentation/pages/groups_page.dart';
import '../features/exams/presentation/pages/exams_page.dart';
import '../features/videoconference/presentation/pages/videoconference_page.dart';
import '../features/collaboration/presentation/pages/collaboration_page.dart'
    as collaboration_page;
import '../features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../features/ai_assistant/presentation/pages/ai_revision_page.dart';
import '../features/ai_assistant/presentation/pages/ai_quiz_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';

/// Notifier stable qui force GoRouter à réévaluer `redirect`
/// sans recréer l'instance (sinon la navigation est réinitialisée).
class AuthRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final authRefreshProvider = Provider<AuthRefreshNotifier>((ref) {
  return AuthRefreshNotifier();
});

final hasSeenSplashProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(authRefreshProvider);
  final hasSeenSplash = ref.watch(hasSeenSplashProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // 1. Splash screen obligatoire au premier chargement (cold start ou reload)
      if (!hasSeenSplash) {
        if (location == '/splash' || location == '/') return null;
        return '/splash';
      }

      final auth = ProviderScope.containerOf(context).read(authStateProvider).value;
      final isLoggedIn = auth?.isAuthenticated ?? false;
      final completed = auth?.onboardingCompleted ?? false;

      // Si l'utilisateur tente d'aller manuellement sur /splash après l'avoir terminé
      if (location == '/splash') {
        return completed ? '/home' : (isLoggedIn ? '/role-selection' : '/login');
      }

      final isPublicRoute = location.startsWith('/login') ||
          location.startsWith('/register') ||
          location.startsWith('/forgot-password');
      final isOnboardingRoute = location.startsWith('/role-selection') ||
          location.startsWith('/profile-setup');

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
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: '/courses/ai-create',
        name: 'ai-create-course',
        builder: (context, state) => const AiCourseCreatorPage(),
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
            path: '/groups',
            name: 'groups',
            builder: (context, state) => const GroupsPage(),
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
            builder: (context, state) => const collaboration_page.CollaborationPage(),
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
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(context.tr('not_found'), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(state.error.toString(), style: Theme.of(context).textTheme.bodyMedium),
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
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(),
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final location = GoRouterState.of(context).matchedLocation;

    final items = [
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
        icon: Icons.auto_awesome_rounded,
        selectedIcon: Icons.auto_awesome_rounded,
        labelKey: 'ai_tutor',
        route: '/ai-assistant',
        isAiPill: true,
      ),
      _NavItem(
        icon: Icons.forum_outlined,
        selectedIcon: Icons.forum_rounded,
        labelKey: 'community',
        route: '/groups',
      ),
      _NavItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        labelKey: 'profile',
        route: '/profile',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final isSelected = location.startsWith(item.route);

              if (item.isAiPill) {
                return InkWell(
                  onTap: () => context.go(item.route),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.secondaryFixed.withValues(alpha: 0.5),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            item.selectedIcon,
                            size: 20,
                            color: colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr(item.labelKey),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final color = isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant;

              return InkWell(
                onTap: () => context.go(item.route),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        size: 24,
                        color: color,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.tr(item.labelKey),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: color,
                        ),
                      ),
                    ],
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

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
    required this.route,
    this.isAiPill = false,
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
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(config.textScaleFactor),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

final localeProvider = StateProvider<String>((ref) => AppConstants.defaultLanguageCode);

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

@immutable
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? role;
  final String? email;
  final String? displayName;
  final bool onboardingCompleted;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.role,
    this.email,
    this.displayName,
    this.onboardingCompleted = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? role,
    String? email,
    String? displayName,
    bool? onboardingCompleted,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>((ref) {
  final refresher = ref.watch(authRefreshProvider);
  return AuthNotifier(onChanged: refresher.refresh);
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final VoidCallback onChanged;

  AuthNotifier({required this.onChanged}) : super(const AsyncValue.data(AuthState()));

  void _emit(AsyncValue<AuthState> next) {
    state = next;
    onChanged();
  }

  Future<void> login(String email, String password, {String? role}) async {
    _emit(const AsyncValue.loading());
    await Future.delayed(const Duration(milliseconds: 500));
    final normalized = email.toLowerCase();
    final effectiveRole = role ??
        (normalized.contains('prof') || normalized.contains('teacher') || normalized.contains('amine')
            ? 'teacher'
            : 'student');
    final isTeacher = effectiveRole == 'teacher';
    _emit(AsyncValue.data(AuthState(
      isAuthenticated: true,
      userId: '1',
      email: email.isNotEmpty ? email : (isTeacher ? 'prof.amine@smartclass.edu' : 'salma@smartclass.edu'),
      role: effectiveRole,
      displayName: isTeacher ? 'Prof. Amine' : 'Salma',
      onboardingCompleted: true,
    )));
  }

  Future<void> register(String email, String password, String role) async {
    _emit(const AsyncValue.loading());
    await Future.delayed(const Duration(milliseconds: 500));
    _emit(AsyncValue.data(AuthState(
      isAuthenticated: true,
      userId: '1',
      email: email,
      role: role,
      displayName: 'Utilisateur',
      onboardingCompleted: false,
    )));
  }

  Future<void> logout() async {
    _emit(const AsyncValue.data(AuthState()));
  }

  void updateProfile({String? displayName, String? email}) {
    final current = state.value;
    if (current != null) {
      _emit(AsyncValue.data(current.copyWith(
        displayName: displayName,
        email: email,
      )));
    }
  }

  void updateRole(String role) {
    final current = state.value;
    if (current != null) {
      _emit(AsyncValue.data(current.copyWith(role: role)));
    }
  }

  void completeProfile() {
    final current = state.value;
    if (current != null) {
      _emit(AsyncValue.data(current.copyWith(onboardingCompleted: true)));
    }
  }
}
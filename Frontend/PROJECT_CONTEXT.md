# SmartClass - Contexte Technique du Projet

Ce document sert de référence pour les futures conversations. Il documente toutes les décisions techniques, patterns d'architecture, et conventions utilisées dans le projet.

---

## 1. Architecture Globale

### Clean Architecture (Respect strict des couches)

```
lib/
├── app/                    # Configuration app (router, providers, theme)
├── core/                   # Infrastructure partagée
│   ├── constants/          # Constantes globales
│   ├── error/              # Failure classes (ServerFailure, NetworkFailure, etc.)
│   ├── extensions/         # Extensions Dart/Flutter
│   ├── localization/       # Système i18n (FR/EN)
│   ├── theme/              # Material 3 Theme
│   ├── typography/         # Système typographique configurable
│   └── widgets/            # Widgets réutilisables
└── features/               # Modules fonctionnels (Clean Architecture)
    ├── authentication/     # Auth (login, register, role selection)
    ├── courses/            # Gestion cours
    ├── groups/             # Groupes/classes
    ├── exams/              # Examens & simulations
    ├── videoconference/    # Sessions live, replays
    ├── collaboration/      # Ressources partagées, sessions étude
    ├── ai_assistant/       # Tuteur IA conversationnel
    ├── profile/            # Profil utilisateur
    └── settings/           # Paramètres globaux
```

### Responsabilités par couche (STRICT)

| Couche | Responsabilité | Dépendances |
|--------|----------------|-------------|
| **Domain** | Entités, Repository interfaces, UseCases | Aucune (pure Dart) |
| **Application** | Controllers, Providers, State (Riverpod) | Domain |
| **Infrastructure** | DataSources (mock), Models, Repository implémentations | Domain, Application |
| **Presentation** | Pages, Widgets, Components | Application, Core |

**Règles** :
- Domain = zéro dépendance Flutter
- Application = orchestration uniquement (pas de logique métier)
- Infrastructure = implémentations concrètes (mock → API plus tard)
- Presentation = UI uniquement, pas de logique métier

---

## 2. Design System (Source: DESIGN.md)

### Couleurs (Material 3 ColorScheme)

```dart
// Primaires
primary: #122675 (bleu foncé)
primaryContainer: #2D3E8C
onPrimary: #FFFFFF
onPrimaryContainer: #9EAEFF

// Secondaires
secondary: #4056B9
tertiary: #003627 (vert succès)

// Surfaces
surface: #FAF8FF
surfaceContainerHighest: #DCE1FE (remplace surfaceVariant déprécié)
onSurface: #151B2F
onSurfaceVariant: #454651

// États
success: #0F9D78
warning: #F5A623
error: #BA1A1A
```

### Typographie (Police: Inter)

| Style | Taille | Weight | LineHeight | LetterSpacing |
|-------|--------|--------|------------|---------------|
| displayLarge | 34px | 700 | 41px | -0.022em |
| headlineLarge | 28px | 600 | 34px | -0.019em |
| headlineMedium | 22px | 600 | 28px | -0.015em |
| headlineSmall | 20px | 600 | 25px | -0.012em |
| bodyLarge | 17px | 400 | 22px | -0.011em |
| bodyMedium | 15px | 400 | 20px | -0.008em |
| bodySmall | 13px | 400 | 18px | -0.003em |
| labelLarge | 17px | 600 | 22px | -0.011em |
| labelMedium | 15px | 600 | 20px | -0.008em |
| labelSmall | 12px | 600 | 16px | 0.002em |
| caption | 11px | 500 | 13px | 0.006em |

### Border Radius

```dart
sm: 4px (0.25rem)
DEFAULT: 8px (0.5rem) — inputs, buttons
md: 12px (0.75rem)
lg: 16px (1rem) — cards
xl: 24px (1.5rem) — modals
full: 9999px — badges/chips
```

### Espacements (base 8px)

```dart
space-xs: 4px (0.25rem)
space-sm: 8px (0.5rem)
space-md: 16px (1rem)
space-lg: 24px (1.5rem)
space-xl: 32px (2rem)
screenMargin: 20px (mobile) / 32px (tablet)
```

### Élévation (iOS-style subtil)

- Level 0: Canvas (#F7F8FB) — pas d'ombre
- Level 1: Cards — `0 2px 8px rgba(29,35,56,0.04), 0 1px 2px rgba(29,35,56,0.02)`
- Level 2: Floating — `0 10px 25px -5px rgba(29,35,56,0.08), 0 4px 6px -2px rgba(29,35,56,0.03)`
- Level 3: Modals — backdrop blur + scrim

---

## 3. Internationalisation (i18n)

### Configuration

- **Langues supportées** : `fr` (défaut), `en`
- **Système** : `AppLocalizations` avec `LocalizationsDelegate`
- **Initialisation** : `AppLocalizations.initialize()` dans `main.dart` avant `runApp`

### Utilisation (OBLIGATOIRE)

```dart
// Dans les widgets (via extension)
context.tr('key')                    // Traduction simple
context.tr('key', args: {'count': 5}) // Avec paramètres

// Clés organisées par domaine:
// auth.*, navigation.*, courses.*, groups.*, exams.*
// videoconference.*, collaboration.*, ai_assistant.*
// profile.*, settings.*, errors.*, validation.*
```

### Règles strictes

- **Aucun texte hardcodé** dans l'UI (`Text("Connexion")` ❌)
- **Tous** les textes utilisateur passent par `context.tr()`
- Placeholders, messages d'erreur, dialogues, tooltips inclus
- Architecture extensible pour futures langues

---

## 4. Système Typographique Global (Configurable depuis Settings)

### Architecture

```
Settings (UI)
    ↓
TypographyConfigNotifier (StateNotifier)
    ↓
SharedPreferences (persistance)
    ↓
AppTextStyles (Provider)
    ↓
ThemeData (textTheme)
    ↓
Toute l'application (rebuild automatique)
```

### Options configurables

| Paramètre | Options | Défaut |
|-----------|---------|--------|
| **Font Family** | Inter, Roboto, Open Sans, System | Inter |
| **Font Size** | Small (0.85), Medium (1.0), Large (1.15), ExtraLarge (1.3) | Medium |
| **Text Scale** | Slider 85% - 150% | 100% |

### Implémentation technique

```dart
// Provider principal
final typographyConfigProvider = StateNotifierProvider<TypographyConfigNotifier, AsyncValue<TypographyConfig>>(...)

// Application dans MaterialApp
builder: (context, child) => MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.linear(config.textScaleFactor),
  ),
  child: child!,
)

// Styles centralisés via AppTextStyles(config)
theme: AppTheme.getLightTheme(AppTextStyles(config))
```

### Règle : **Jamais** de `fontSize: 14` ou `TextStyle(fontSize: ...)` dans les écrans. Toujours utiliser `theme.textTheme.bodyMedium` ou `AppTextStyles`.

---

## 5. Gestion d'État (Riverpod)

### Types de providers utilisés

| Type | Usage |
|------|-------|
| `Provider` | Services, repositories, configuration statique |
| `StateNotifierProvider` | État mutable complexe (Auth, Typography, etc.) |
| `StateProvider` | État simple local (locale, themeMode) |
| `FutureProvider` / `StreamProvider` | Données asynchrones |
| `AutoDispose` | Nettoyage automatique (non utilisé par défaut) |

### Structure d'état par feature

```
feature/
├── application/
│   ├── providers/      # Providers Riverpod exposés
│   ├── controllers/    # StateNotifiers (logique)
│   └── state/          # Classes d'état (freezed/equatable)
```

### Patterns

```dart
// StateNotifier pour état complexe
class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  // Méthodes exposées: login(), logout(), updateProfile()
}

// State simple
final localeProvider = StateProvider<String>((ref) => 'fr');

// Lecture dans UI
final authState = ref.watch(authStateProvider);
final config = ref.watch(typographyConfigProvider);
```

### Règles

- **Pas de `setState`** pour état partagé → Riverpod
- **Local UI State** (scroll, animation, focus) → `setState` OK
- **Global/App State** → Riverpod uniquement
- **Invalidation ciblée** → `ref.invalidate(provider)` pas de polling

---

## 6. Navigation (GoRouter)

### Configuration

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) => /* auth guard */,
    routes: [
      GoRoute(path: '/login', ...),
      GoRoute(path: '/register', ...),
      GoRoute(path: '/role-selection', ...),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home', ...),
          GoRoute(path: '/courses', ...),
          // ... autres routes
        ],
      ),
    ],
  );
});
```

### Navigation dans le code

```dart
context.go('/home')           // Remplace la stack
context.push('/courses')      // Ajoute à la stack
context.pop()                 // Retour
```

### Bottom Navigation

- 5 onglets principaux : Home, Courses, Groups, Exams, Videoconference
- `NavigationBar` Material 3
- `ShellRoute` pour conserver le bottom nav

### Règle critique : router stable (bug connu et corrigé)

- **Ne JAMAIS faire `ref.watch(authStateProvider)` dans `routerProvider`** : cela recrée le `GoRouter` à chaque changement d'état et réinitialise la navigation (ex. après inscription, retour forcé à `/home` au lieu de `/role-selection`).
- Pattern en place : `GoRouter` créé **une seule fois** + `refreshListenable: AuthRefreshNotifier` (notifié par `AuthNotifier` après chaque mutation) + `redirect` qui lit l'état via `ProviderScope.containerOf(context).read(authStateProvider)`.
- `AuthState.onboardingCompleted` pilote le flux : inscription → `/role-selection` → `/profile-setup` (`completeProfile()`) → `/home`. Connexion existante → `/home` direct.

---

## 7. Principes de Code (OBLIGATOIRES)

### SOLID + Clean Code

- **SRP** : Une classe = une responsabilité
- **OCP** : Ouvert extension, fermé modification (interfaces Repository)
- **LSP** : Implémentations interchangeables (Mock ↔ API)
- **ISP** : Interfaces spécifiques par feature
- **DIP** : Dépendances vers abstractions (Domain)

### Conventions

```dart
// Nommage
- Classes: PascalCase
- Variables/fonctions: camelCase
- Constantes: SCREAMING_SNAKE_CASE
- Fichiers: snake_case.dart
- Providers: lowerCamelCaseProvider

// Imports (ordre)
1. Dart SDK
2. Flutter SDK
3. Packages tiers
4. Core (../../../core/...)
5. Feature (../../../features/...)
6. Relative (./)

// Extensions : toujours importer core/extensions/extensions.dart
```

### Interdits

- ❌ `Timer.periodic` pour polling
- ❌ `while(true)` boucles de refresh
- ❌ Texte hardcodé dans l'UI
- ❌ `fontSize` direct dans les widgets
- ❌ Logique métier dans Presentation
- ❌ Dépendances Flutter dans Domain
- ❌ `ProviderScope` multiple
- ❌ `ref.watch` dans `build` sans `ConsumerWidget`

---

## 8. Données Mockées (Infrastructure)

### Structure

```
feature/
└── infrastructure/
    ├── datasources/
    │   └── mock_<entity>_datasource.dart
    ├── models/
    │   └── <entity>_model.dart (fromJson/toJson)
    └── repositories/
        └── <entity>_repository_impl.dart
```

### Règle

```dart
// Dans Presentation - JAMAIS
class HomePage extends StatelessWidget {
  final users = [...]; // ❌
}

// Dans Infrastructure - TOUJOURS
class MockUserDataSource implements UserDataSource {
  // Données statiques ici
}
```

### États d'interface gérés

```dart
// Via AsyncValue (Riverpod)
Initial → Loading → Success(data) / Error(failure) / Empty
```

---

## 9. Responsive / Mobile-First

### Breakpoints

```dart
isMobile: width < 600
isTablet: width >= 600 && width < 1024
isDesktop: width >= 1024
```

### Outils

- `LayoutBuilder` pour contraintes
- `MediaQuery` pour dimensions
- `ConstrainedBox` / `Flexible` / `Expanded`
- Grille : 1 col (mobile), 2-4 (tablet), 6-12 (desktop)
- Marges : 20px (mobile) → 32px (tablet+)

---

## 10. Composants Réutilisables (core/widgets)

| Widget | Description |
|--------|-------------|
| `AppButton` | Primary/Secondary/Outlined/Text + loading |
| `AppTextField` | Label, hint, prefix/suffix icons, validation |
| `AppSearchField` | Recherche avec clear button |
| `AppTextArea` | Multi-lignes |
| `AppCard` | Card de base + header/content/actions |
| `AppCourseCard` | Carte cours (image, progress, status) |
| `AppGroupCard` | Carte groupe (membres, rôle, code) |
| `AppExamCard` | Carte examen (date, durée, score, simulation) |

### États UI standardisés

```dart
// Loading
CircularProgressIndicator(color: theme.colorScheme.primary)

// Empty
AppEmptyState(icon, title, message, action?)

// Error
AppErrorState(message, onRetry?)

// Success feedback
SnackBar / Toast via ScaffoldMessenger
```

---

## 11. Fichiers Clés à Connaître

| Fichier | Rôle |
|---------|------|
| `lib/main.dart` | Entry point, init i18n, ProviderScope |
| `lib/app/app.dart` | SmartClassApp (MaterialApp.router) |
| `lib/app/app_providers.dart` | Router, Theme, Auth, Locale, Typography |
| `lib/core/localization/app_localizations.dart` | Système traduction complet |
| `lib/core/typography/typography_config.dart` | Config + Repository |
| `lib/core/typography/typography_provider.dart` | StateNotifier + Providers |
| `lib/core/theme/app_theme.dart` | ThemeData complet (light/dark) |
| `lib/core/extensions/extensions.dart` | Extensions BuildContext, String, DateTime |
| `lib/core/widgets/app_*.dart` | Widgets de base |
| `lib/features/*/presentation/pages/*_page.dart` | Écrans principaux |

---

## 12. Commandes Utiles

```bash
# Dépendances
flutter pub get
flutter pub upgrade

# Code generation
flutter pub run build_runner build --delete-conflicting-outputs
flutter pub run build_runner watch

# Analyse
flutter analyze

# Build
flutter build web --release
flutter build apk --release
flutter build ios --release

# Tests
flutter test
```

---

## 13. Prochaines Étapes (Backend Ready)

L'architecture est prête pour l'intégration backend :

1. **Remplacer MockDataSource** par `RemoteDataSource` (Dio + Retrofit)
2. **Ajouter Auth interceptor** (JWT, refresh token)
3. **Configurer API base URL** par environnement
4. **Implémenter WebSocket** pour temps réel (visioconférence, collab)
5. **Ajouter Offline-first** (SQLite local + sync)

**Aucune modification** de la couche Presentation/Domain nécessaire.

---

## 14. Rappels pour la Prochaine Conversation

> **Utilise ce fichier comme mémoire technique. Tout nouveau code doit respecter :**
> - Clean Architecture (4 couches strictes)
> - DESIGN.md pour le visuel (couleurs, typo, espacements, radius)
> - HTML pour le fonctionnel (features, règles métier, flux)
> - i18n FR/EN obligatoire (context.tr)
> - Typography globale configurable (Settings → Provider → Theme)
> - Riverpod pour état global (pas de setState partagé)
> - Pas de polling (Timer.periodic, while) → architecture réactive
> - Mock data isolé dans Infrastructure
> - Mobile-first, responsive, même code Mobile/Web
> - Composants réutilisables dans core/widgets
> - Extensions dans core/extensions
> - Tests et analyse avant validation

---

### Dashboard par rôle (maquettes `assets/design/prof/`)

- `HomePage` branche sur `authState.role` : `teacher` → `TeacherDashboardView`, sinon vue étudiant existante.
- Données mockées isolées : `home/infrastructure/datasources/mock_teacher_dashboard_datasource.dart` + providers `teacher_dashboard_provider.dart` (stats, direct, classes). Icônes stockées en `String` et mappées en présentation (`teacher_icons.dart`).
- Avatar prof : `assets/images/teacher_avatar.png` (copie de `assets/design/prof/photo de prof.png`), déclaré dans `pubspec.yaml`, avec fallback icône via `errorBuilder`.
- Créateur de cours IA (UC1) : `courses/presentation/pages/ai_course_creator_page.dart`, route top-level `/courses/ai-create` (bouton "Générer maintenant" de la bannière). Options mockées : `mock_ai_course_options_datasource.dart` + `ai_course_options_provider.dart`.
- Shell de navigation inchangé (5 onglets) : seule la vue `/home` varie selon le rôle.

---

*Dernière mise à jour : 2026-10-02*
*Version : 1.1.0*